///|
pub fn metric(
  value? : Double = 0.0,
  label? : String = "",
  prefix? : String = "",
  suffix? : String = "",
) -> @rabbita.Html {
  let val_str = value.to_string()
  let empty : Array[@rabbita.Html] = []
  let label_kids = if label == "" {
    empty
  } else {
    [@html.div(class="metric__label", [@html.text(label)])]
  }
  @html.div(
    class="metric",
    label_kids +
    [
      @html.span(class="metric__value", [
        @html.text("\{prefix}\{val_str}\{suffix}"),
      ]),
    ],
  )
}
