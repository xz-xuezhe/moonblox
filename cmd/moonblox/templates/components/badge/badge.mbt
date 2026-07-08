///|
pub fn badge(text? : String = "", tone? : String = "default") -> @rabbita.Html {
  @html.span(class="badge badge--\{tone}", [@html.text(text)])
}
