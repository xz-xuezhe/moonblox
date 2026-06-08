/// Number metric display: @metric(label: "Reward", value: 0.73)
pub(all) struct MetricProps {
  label : String
  value : Double = 0.0
}

pub fn view(props : MetricProps) -> @rabbita.Html {
  @html.div(class="metric", [
    @html.span(class="metric__label", [@html.text(props.label)]),
    @html.span(class="metric__value", [@html.text(props.value.to_string())]),
  ])
}
