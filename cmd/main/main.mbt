/// MoonMark CLI — Markdown-first programmable site generator

///|
/// Main entry point: `moonmark build <input.md>`
fn main raise {
  let args = @env.args()
  if args.length() < 2 {
    println("Usage: moonmark build <input.md>")
    return
  }
  let cmd = args[1]
  if cmd != "build" {
    println("Unknown command: \{cmd}")
    println("Usage: moonmark build <input.md>")
    return
  }
  guard args.length() >= 3 else {
    println("Usage: moonmark build <input.md>")
    return
  }
  let input_path = args[2]
  let content = @fs.read_file_to_string(input_path)
  let doc = @convert.parse_markdown(content)
  let html = @render.render_document(doc, title=input_path)
  // Write to dist/index.html
  @fs.write_string_to_file("dist/index.html", html)
  println("Built: dist/index.html")
}
