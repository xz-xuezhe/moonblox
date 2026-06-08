/// Interactive slider: @slider(param: "reward", min: 0, max: 1, value: 0.5)
pub(all) struct SliderProps {
  param : String
  min : Double = 0.0
  max : Double = 1.0
  value : Double = 0.5
}

pub fn view(props : SliderProps) -> @rabbita.Html {
  @html.div(class="slider", [
    @html.label([@html.text("\{props.param}: \{props.value}")]),
  ])
}
