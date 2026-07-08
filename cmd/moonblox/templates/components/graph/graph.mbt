///|
pub fn graph(
  value? : Double = 0.0,
  max? : Double = 100.0,
  label? : String = "",
) -> @rabbita.Html {
  let pct = if max <= 0.0 { 0.0 } else { value / max * 100.0 }
  let h = if pct < 1.0 { 1.0 } else { pct }
  let empty : Array[@rabbita.Html] = []
  let label_kids = if label == "" {
    empty
  } else {
    [@html.div(class="graph__label", [@html.text(label)])]
  }
  @html.div(
    class="graph",
    [
      @html.div(class="graph__bar-container", [
        @html.div(class="graph__bar", style=["height: \{h.to_string()}%"], [
          @html.text(value.to_string()),
        ]),
      ]),
    ] +
    label_kids,
  )
}
