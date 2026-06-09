///|
pub(all) struct CalloutProps {
  type_ : String
  title : String
}

///|
pub fn CalloutProps::new(
  type_? : String = "note",
  title? : String = "",
) -> CalloutProps {
  CalloutProps::{ type_, title }
}

///|
pub fn callout_cell(
  props : CalloutProps,
  children : Array[@rabbita.Html],
) -> @rabbita.Cell {
  @rabbita.static_cell(
    {
      let empty : Array[@rabbita.Html] = []
      let title_kids : Array[@rabbita.Html] = if props.title == "" {
        empty
      } else {
        [@html.div(class="callout__title", [@html.text(props.title)])]
      }
      @html.div(class="callout callout--\{props.type_}", title_kids + children)
    },
  )
}
