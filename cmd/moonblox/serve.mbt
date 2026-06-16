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

  // Setup file watcher on project root (ignore _moonblox/ and dist/)
  let watcher = @afs.Watcher(dir, ignored_paths=fn(path) {
    path.contains("_moonblox") ||
    path.contains("dist/") ||
    path.contains(".mooncakes")
  })

  // Start HTTP server
  let server = @http.Server(@socket.Addr::parse("127.0.0.1:\{port}"))
  println("  Server: http://localhost:\{port}")

  let _ = server.run_forever(async fn(
    req : @http.Request,
    _reader,
    conn : @http.ServerConnection,
  ) -> Unit {
    // WebSocket upgrade for live reload
    if req.path == "/__moonblox/events" {
      let ws = @websocket.from_http_server(req, conn)
      // Keep connection alive, send reload on rebuild
      let _ = ws.send_text("connected")
    } else {
      let path = if req.path == "/" { "/index.html" } else { req.path }
      let file_path = "\{dist_dir}\{path}"
      let content_type = if path.has_suffix(".html") {
        "text/html"
      } else if path.has_suffix(".css") {
        "text/css"
      } else if path.has_suffix(".js") {
        "text/javascript"
      } else {
        "application/octet-stream"
      }
      try {
        if @fs.path_exists(file_path) && !@fs.is_dir(file_path) {
          let content = @fs.read_file_to_string(file_path)
          let body = if path.has_suffix(".html") {
            inject_reload_script(content)
          } else {
            content
          }
          conn
          ..send_response(200, "OK", extra_headers={
            "Content-Type": content_type,
          })
          ..write(body)
          .end_response()
        } else {
          conn
          ..send_response(404, "Not Found", extra_headers={
            "Content-Type": "text/plain",
          })
          ..write("404 Not Found\n")
          .end_response()
        }
      } catch {
        _ =>
          conn
          ..send_response(500, "Internal Error", extra_headers={
            "Content-Type": "text/plain",
          })
          ..write("500 Internal Error\n")
          .end_response()
      }
    }
  })

  // Watch → rebuild loop
  println("Watching for changes...")
  while true {
    watcher.wait_any()
    println("Change detected, rebuilding...")
    let _ = build(dir)
    println("Rebuilt. Refresh browser to see changes.")
  }
}

///|
fn inject_reload_script(html : String) -> String {
  let script =
    #|<script>
    #|(function() {
    #|  var ws = new WebSocket('ws://' + location.host + '/__moonblox/events');
    #|  ws.onmessage = function(e) { if (e.data === 'reload') location.reload(); };
    #|  ws.onclose = function() { setTimeout(function() { location.reload(); }, 2000); };
    #|})();
    #|</script>
    #|
    #|</body>
  html.replace_all(old="</body>", new=script)
}
