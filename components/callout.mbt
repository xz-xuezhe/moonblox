///|
/// Render a callout container component
/// :::callout(type: "warning", title: "Note")
pub fn render_callout(args : Map[String, @ast.Value], body : String) -> String {
  let callout_type = match args["type"] {
    @ast.Value::Str(s) => s
    _ => "note"
  }
  let title = match args["title"] {
    @ast.Value::Str(s) => s
    _ => ""
  }
  let sb = StringBuilder::new()
  sb.write_string("<div class=\"callout callout--")
  sb.write_string(callout_type)
  sb.write_string("\">\n")
  if title != "" {
    sb.write_string("<div class=\"callout__title\">")
    sb.write_string(title)
    sb.write_string("</div>\n")
  }
  sb.write_string(body)
  sb.write_string("\n</div>")
  sb.to_string()
}
