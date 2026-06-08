/// Badge inline component: @badge(text: "experimental", tone: "warning")
pub(all) struct BadgeProps {
  text : String
  tone : String = "default"
}

/// Rabbita view
pub fn view(props : BadgeProps) -> @rabbita.Html {
  @html.span(class="badge badge--\{props.tone}", [@html.text(props.text)])
}
