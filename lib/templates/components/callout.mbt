pub(all) struct CalloutProps {
  type_ : String
  title : String
}

pub fn callout_cell(args : Map[String, @ast.Value], body : String) -> @rabbita.Cell {
  let type_ = match args.get("type") { Some(@ast.Value::Str(s)) => s; _ => "note" }
  let title = match args.get("title") { Some(@ast.Value::Str(s)) => s; _ => "" }
  @rabbita.static_cell({
    let empty : Array[@rabbita.Html] = []
    let title_kids : Array[@rabbita.Html] = if title == "" {
      empty
    } else {
      [@html.div(class="callout__title", [@html.text(title)])]
    }
    let attrs = @html.Attrs::build().inner_html(body)
    let body_node = @html.div(attrs=attrs, empty)
    @html.div(class="callout callout--\{type_}", title_kids + [body_node])
  })
}
