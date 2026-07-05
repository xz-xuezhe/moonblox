///|
/// moonblox serve — dev server with file watching and live reload
pub async fn serve(dir : String, port : Int) -> Unit {
  guard @fs.path_exists(dir) else {
    println("Error: directory not found: \{dir}")
    return
  }

  let build_root = "\{dir}/\{BUILD_DIR_NAME}"
  let dist_dir = "\{build_root}/_build/js/debug/build"
  let port : UInt = port.reinterpret_as_uint()

  // Initial build (debug mode — serve directly from build output)
  println("Building...")
  let ok = build(dir, dev_mode=true)
  guard ok else {
    println("Error: initial build failed — fix errors and restart")
    return
  }

  // Setup file watcher (warren pattern: watch source dir, filter build artifacts)
  let watcher = @afs.Watcher(dir, ignored_paths=fn(path) {
    path.contains(BUILD_DIR_NAME) ||
    path.contains(MOONCAKES_DIR) ||
    path.contains(BUILD_OUT_DIR)
  })

  // Start HTTP server
  let server = @http.Server(
    @socket.Addr::parse("127.0.0.1:\{port}"),
    reuse_addr=true,
  )
  println("  Server: http://localhost:\{port}")

  // Subscriber management (warren pattern)
  let subscribers : Ref[Map[Int, @async.Queue[BroadcastMsg]]] = Ref({})
  let next_id : Ref[Int] = Ref(0)

  @async.with_task_group(group => {
    // Spawn HTTP server in background (warren: no_wait=true)
    group.spawn_bg(no_wait=true, allow_failure=true, () => {
      let _ = server.run_forever(
        (request, _, conn) => {
          handle_request(dist_dir, request, conn, subscribers, next_id)
        },
        allow_failure=true,
        max_connections=64,
      )
    })

    println("Watching for changes...")
    let config = read_config(dir)
    let cache = Ref(BuildCache::new())
    // Prime the cache: snapshot current state so future detections
    // compare against this baseline rather than empty cache.
    ignore(detect_changes(dir, cache, config))
    // Warren pattern: build first, then wait
    while true {
      watcher.wait_any()
      @async.sleep(100)
      let changes = detect_changes(dir, cache, config)
      match changes {
        NoChanges => continue
        _ => {
          println("Change detected, rebuilding...")
          let ok = incremental_rebuild(
            dir,
            build_root,
            config,
            changes,
            dev_mode=true,
          )
          if ok {
            broadcast(subscribers, BroadcastMsg::Reload)
            println("Rebuilt.")
          } else {
            println("Build failed.")
            broadcast(subscribers, BroadcastMsg::BuildFailed(""))
          }
        }
      }
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
fn is_safe_request_path(path : String) -> Bool {
  path.has_prefix("/") && !path.contains("..") && !path.contains("\\")
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
    ..send_response(405, "Method Not Allowed", extra_headers={
      "Content-Type": "text/plain",
    })
    ..write("Method Not Allowed")
    .end_response()
    return
  }

  let path = if request.path == "/" { "/\{INDEX_HTML}" } else { request.path }

  guard is_safe_request_path(path) else {
    conn
    ..send_response(400, "Bad Request", extra_headers={
      "Content-Type": "text/plain",
    })
    ..write("Bad Request")
    .end_response()
    return
  }

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
            BuildFailed(_) => ws.send_text("buildfailed") catch { _ => break }
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

  // Serve file from build output (warren pattern: VFS read)
  let mut file_path = "\{dist_dir}\{path}"

  // Handle directory -> index.html
  if @fs.path_exists(file_path) && @fs.is_dir(file_path) {
    file_path = "\{file_path}/\{INDEX_HTML}"
  }

  // If not found at direct path, try with pages/ prefix (dev mode build output structure)
  if !@fs.path_exists(file_path) {
    let pages_path = "\{dist_dir}/pages\{path}"
    if @fs.path_exists(pages_path) {
      if @fs.is_dir(pages_path) {
        file_path = "\{pages_path}/\{INDEX_HTML}"
      } else {
        file_path = pages_path
      }
    } else if path == "/\{INDEX_HTML}" {
      // Root request — serve list page at pages/_listing/index.html
      let root_index = "\{dist_dir}/pages/_listing/\{INDEX_HTML}"
      if @fs.path_exists(root_index) {
        file_path = root_index
      }
    } else if path.has_suffix(".js") && !path[1:].contains("/") {
      // Deep fallback: /{slug}.js → pages/{slug}/{slug}.js
      let slug = path[1:path.length() - 3]
      let deep_path = "\{dist_dir}/pages/\{slug}/\{slug}.js"
      if @fs.path_exists(deep_path) {
        file_path = deep_path
      }
    }
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
    ..send_response(200, "OK", extra_headers={ "Content-Type": content_type })
    ..write(body)
    .end_response()
  } else {
    conn
    ..send_response(404, "Not Found", extra_headers={
      "Content-Type": "text/plain",
    })
    ..write("\{path} Not Found")
    .end_response()
  }
}

///|
fn inject_reload_script(html : String) -> String {
  match html.find("</body>") {
    Some(idx) =>
      html[0:idx].to_owned() + live_reload_script + html[idx:].to_owned()
    None => html + live_reload_script // no </body> tag, append at end
  }
}
