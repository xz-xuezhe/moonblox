/// SVG line chart: @chart(x_label: "Step", y_label: "Reward")
pub(all) struct ChartProps {
  x_label : String = "x"
  y_label : String = "y"
  points : String = ""
}

pub fn view(props : ChartProps) -> @rabbita.Html {
  let svg =
    "<svg viewBox=\"0 0 400 200\"><polyline fill=\"none\" stroke=\"#007bff\" stroke-width=\"2\" points=\"" +
    props.points +
    "\"></polyline></svg>"
  @html.div(attrs=@html.Attrs::inner_html(@html.Attrs::default(), svg), [])
}
