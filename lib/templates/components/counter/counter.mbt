///|
pub(all) struct CounterProps {
  initial : Double
}

///|
enum CounterMsg {
  Increment
  Decrement
}

///|
struct CounterModel {
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
pub fn counter_cell(args : Map[String, @ast.Value]) -> @rabbita.Cell {
  let initial = match args.get("initial") {
    Some(@ast.Value::Number(n)) => n
    _ => 0.0
  }
  @rabbita.simple_cell(
    model=CounterModel::{ count: initial },
    update=counter_update,
    view=counter_view,
  )
}
