pub(all) struct BadgeProps {
  text : String
  tone : String
}

pub fn badge_cell(args : Map[String, @ast.Value]) -> @rabbita.Cell {
  let text = match args.get("text") { Some(@ast.Value::Str(s)) => s; _ => "" }
  let tone = match args.get("tone") { Some(@ast.Value::Str(s)) => s; _ => "default" }
  @rabbita.static_cell(@html.span(class="badge badge--\{tone}", [@html.text(text)]))
}
