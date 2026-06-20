///|
pub(all) struct CounterProps {
  initial : Double
}

///|
pub fn CounterProps::new(initial? : Double = 0.0) -> CounterProps {
  CounterProps::{ initial, }
}

///|
priv enum CounterMsg {
  Increment
  Decrement
}

///|
priv struct CounterModel {
  count : Double
}

///|
fn counter_update(msg : CounterMsg, model : CounterModel) -> CounterModel {
  match msg {
    Increment => CounterModel::{ count: model.count + 1.0 }
    Decrement => CounterModel::{ count: model.count - 1.0 }
  }
}

///|
fn counter_view(
  emit : @cmd.Emit[CounterMsg],
  model : CounterModel,
) -> @rabbita.Html {
  @html.div(class="counter", [
    @html.button(on_click=emit(Decrement), [@html.text("-")]),
    @html.span(class="counter__value", [@html.text(model.count.to_string())]),
    @html.button(on_click=emit(Increment), [@html.text("+")]),
  ])
}

///|
pub fn counter_cell(props : CounterProps) -> @rabbita.Cell {
  @rabbita.simple_cell(
    model=CounterModel::{ count: props.initial },
    update=counter_update,
    view=counter_view,
  )
}
