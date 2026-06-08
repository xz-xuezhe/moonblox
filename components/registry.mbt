// Component registry: maps component names to render functions.
// To add a new component, implement a render function and add it here.

///|
/// Render an inline component by name: @name(key: val, ...)
pub fn render_inline(name : String, args : Map[String, @ast.Value]) -> String {
  match name {
    "badge" => render_badge(args)
    _ => "<!-- unknown inline component: \{name} -->"
  }
}

///|
/// Render a container component by name: :::name(key: val, ...)
pub fn render_container(
  name : String,
  args : Map[String, @ast.Value],
  body : String,
) -> String {
  match name {
    "callout" => render_callout(args, body)
    _ => "<!-- unknown container: \{name} -->\{body}"
  }
}
