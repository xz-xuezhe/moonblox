///|
/// moonblox serve — dev server with file watching and live reload
pub async fn serve(dir : String, port : Int) -> Unit {
  guard @fs.path_exists(dir) else {
    println("Error: directory not found: \{dir}")
    return
  }

  let dist_dir = "\{dir}/dist"
  let port : UInt = port.to_uint()

  // Initial build
  println("Building...")
  let _ = build(dir)

  // Setup file watcher (warren pattern: watch source dir, filter build artifacts)
  let watcher = @afs.Watcher(dir, ignored_paths=fn(path) {
    path.contains("_moonblox") ||
    path.contains("dist") ||
    path.contains(".mooncakes") ||
    path.contains("_build")
  })

  // Start HTTP server
  let server = @http.Server(@socket.Addr::parse("127.0.0.1:\{port}"), reuse_addr=true)
  println("  Server: http://localhost:\{port}")

  // Subscriber management (warren pattern)
  let subscribers : Ref[Map[Int, @async.Queue[BroadcastMsg]]] = Ref({})
  let next_id : Ref[Int] = Ref(0)

  @async.with_task_group(group => {
    // Spawn HTTP server in background (warren: no_wait=true)
    group.spawn_bg(no_wait=true, allow_failure=true, () => {
      let _ = server.run_forever(
        (request, _, conn) => handle_request(
          dist_dir, request, conn, subscribers, next_id,
        ),
        allow_failure=true,
        max_connections=64,
      )
    })

    println("Watching for changes...")
    // Warren pattern: build first, then wait
    while true {
      watcher.wait_any()
      println("Change detected, rebuilding...")
      let _ = build(dir)
      broadcast(subscribers, BroadcastMsg::Reload)
      println("Rebuilt.")
    }
  })
}

///|
pub(all) enum BroadcastMsg {
  Building
  Reload
  BuildFailed(String)
} derive(Debug)

///|
fn broadcast(
  subscribers : Ref[Map[Int, @async.Queue[BroadcastMsg]]],
  msg : BroadcastMsg,
) -> Unit {
  for entry in subscribers.val.iter() {
    let (_, queue) = entry
    ignore(queue.try_put(msg)) catch {
      _ => ()
    }
  }
}

///|
async fn handle_request(
  dist_dir : String,
  request : @http.Request,
  conn : @http.ServerConnection,
  subscribers : Ref[Map[Int, @async.Queue[BroadcastMsg]]],
  next_id : Ref[Int],
) -> Unit {
  guard request.meth is Get else {
    conn
    ..send_response(405, "Method Not Allowed", extra_headers={"Content-Type": "text/plain"})
    ..write("Method Not Allowed")
    .end_response()
    return
  }

  let path = if request.path == "/" { "/index.html" } else { request.path }

  // WebSocket upgrade — warren's exact handle_ws pattern
  if path == "/__moonblox/events" {
    let ws = @websocket.from_http_server(request, conn)
    defer ws.close()
    let id = next_id.val
    next_id.val = id + 1
    let queue = @async.Queue(kind=DiscardOldest(32))
    subscribers.val.set(id, queue)
    defer subscribers.val.remove(id)
    @async.with_task_group(group => {
      group.spawn_bg(allow_failure=true, () => {
        while queue.get() is msg {
          match msg {
            Building => ws.send_text("building") catch { _ => break }
            Reload => ws.send_text("reload") catch { _ => break }
            BuildFailed(_) => ()
          }
        }
      })
      try {
        for ;; {
          let _ = ws.recv()
        }
      } catch {
        _ => ()
      }
      group.return_immediately(()) catch {
        _ => ()
      }
    })
    return
  }

  // Serve file from dist/ (warren pattern: VFS read)
  let mut file_path = "\{dist_dir}\{path}"
  if @fs.path_exists(file_path) && @fs.is_dir(file_path) {
    file_path = "\{file_path}/index.html"
  }

  let content_type = if file_path.has_suffix(".html") {
    "text/html"
  } else if file_path.has_suffix(".css") {
    "text/css"
  } else if file_path.has_suffix(".js") {
    "text/javascript"
  } else {
    "application/octet-stream"
  }

  if @fs.path_exists(file_path) && !@fs.is_dir(file_path) {
    let content = @fs.read_file_to_string(file_path)
    let body = if file_path.has_suffix(".html") {
      inject_reload_script(content)
    } else {
      content
    }
    conn
    ..send_response(200, "OK", extra_headers={"Content-Type": content_type})
    ..write(body)
    .end_response()
  } else {
    conn
    ..send_response(404, "Not Found", extra_headers={"Content-Type": "text/plain"})
    ..write("\{path} Not Found")
    .end_response()
  }
}

///|
fn inject_reload_script(html : String) -> String {
  let script =
    #|<script>
    #|(function() {
    #|  var ws = new WebSocket('ws://' + location.host + '/__moonblox/events');
    #|  ws.onmessage = function(e) { if (e.data === 'reload') location.reload(); };
    #|  ws.onclose = function() { console.log('[moonblox] live reload disconnected'); };
    #|})();
    #|</script>
    #|
    #|</body>
  html.replace_all(old="</body>", new=script)
}