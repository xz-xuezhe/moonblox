///|
pub fn counter(
  value? : Double = 0.0,
  on_change? : (Double) -> Unit = fn(_) { () },
) -> @rabbita.Html {
  @html.div(class="counter", [
    @html.button(on_click=@cmd.custom_cmd(fn(_) { on_change(value - 1.0) }), [
      @html.text("-"),
    ]),
    @html.span(class="counter__value", [@html.text(value.to_string())]),
    @html.button(on_click=@cmd.custom_cmd(fn(_) { on_change(value + 1.0) }), [
      @html.text("+"),
    ]),
  ])
}
