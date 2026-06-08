/// Callout container: :::callout(type: "note", title: "Tip")
pub(all) struct CalloutProps {
  type_ : String = "note"
  title : String = ""
}

/// Rabbita view with pre-rendered markdown body
pub fn view(props : CalloutProps, body : String) -> @rabbita.Html {
  let title_html = if props.title == "" {
    [] : Array[@rabbita.Html]
  } else {
    [@html.div(class="callout__title", [@html.text(props.title)])]
  }
  // Inject pre-rendered HTML body
  let inner = @html.Attrs::inner_html(@html.Attrs::default(), body)
  let body_node = @html.node("div", inner, [])
  let children = title_html + [body_node]
  @html.div(class="callout callout--\{props.type_}", children)
}
