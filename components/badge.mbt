///|
/// Render a badge inline component
/// @badge(text: "experimental", tone: "warning")
pub fn render_badge(args : Map[String, @ast.Value]) -> String {
  let text = match args["text"] {
    @ast.Value::Str(s) => s
    _ => ""
  }
  let tone = match args["tone"] {
    @ast.Value::Str(s) => s
    _ => "default"
  }
  let sb = StringBuilder::new()
  sb.write_string("<span class=\"badge badge--")
  sb.write_string(tone)
  sb.write_string("\">")
  sb.write_string(text)
  sb.write_string("</span>")
  sb.to_string()
}
