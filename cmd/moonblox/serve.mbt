///|
/// moonblox serve — dev server with file watching and live reload
pub async fn serve(dir : String, port : Int) -> Unit {
  guard @fs.path_exists(dir) else {
    println("Error: directory not found: \{dir}")
    return
  }

  let dist_dir = "\{dir}/dist"

  // Initial build
  println("Building...")
  let _ = build(dir)

  // Setup file watcher
  let watcher = @afs.Watcher(dir, ignored_paths=fn(path) {
    path.contains("_moonblox") ||
    path.contains("dist/") ||
    path.contains(".mooncakes")
  })

  // Start HTTP server (exact warren pattern)
  let server = @http.Server(@socket.Addr::parse("127.0.0.1:\{port}"), reuse_addr=true)
  println("  Server: http://localhost:\{port}")

  // Match warren's run_forever call exactly
  let _ = server.run_forever(
    (request, _, conn) => handle_request(dist_dir, request, conn),
    allow_failure=true,
    max_connections=64,
  )

  // Watch → rebuild loop
  println("Watching for changes...")
  while true {
    watcher.wait_any()
    // Debounce: wait for filesystem to settle after batch changes
    @async.sleep(300)
    println("Change detected, rebuilding...")
    let _ = build(dir)
    println("Rebuilt. Refresh browser to see changes.")
  }
}

///|
async fn handle_request(
  dist_dir : String,
  request : @http.Request,
  conn : @http.ServerConnection,
) -> Unit {
  // Match warren's Meth is Get guard
  guard request.meth is Get else {
    conn
    ..send_response(405, "Method Not Allowed", extra_headers={"Content-Type": "text/plain"})
    ..write("Method Not Allowed")
    .end_response()
    return
  }

  // WebSocket upgrade
  if request.path == "/__moonblox/events" {
    let ws = @websocket.from_http_server(request, conn)
    defer ws.close()
    let _ = ws.send_text("connected")
    return
  }

  let path = if request.path == "/" { "/index.html" } else { request.path }
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

  // Serve file or 404 (match warren's VFS pattern)
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