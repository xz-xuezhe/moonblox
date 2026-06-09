///|
pub(all) struct BadgeProps {
  text : String
  tone : String
}

///|
pub fn BadgeProps::new(
  text? : String = "",
  tone? : String = "default",
) -> BadgeProps {
  BadgeProps::{ text, tone }
}

///|
pub fn badge_cell(props : BadgeProps) -> @rabbita.Cell {
  @rabbita.static_cell(
    @html.span(class="badge badge--\{props.tone}", [@html.text(props.text)]),
  )
}
