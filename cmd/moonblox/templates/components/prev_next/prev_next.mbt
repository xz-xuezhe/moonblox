///|
/// Previous/Next page navigation for documentation.
/// Reads from window.__MOONBLOX_PREV_NEXT__ injected by the build system.
pub fn prev_next() -> @rabbita.Html {
  let children : Array[@rabbita.Html] = []
  @html.nav(
    class="prev-next",
    attrs=@html.Attrs::build().aria_label("Page navigation"),
    children,
  )
}
