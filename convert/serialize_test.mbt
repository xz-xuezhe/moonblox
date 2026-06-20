///|
test "inline_to_md: Text" {
  let inline = @markdown.Inline::Text(
    content="hello",
    span=@markdown.Span::empty(),
  )
  assert_eq(inline_to_md(inline), "hello")
}

///|
test "inline_to_md: Code" {
  let inline = @markdown.Inline::Code(
    content="x",
    backtick_count=1,
    span=@markdown.Span::empty(),
  )
  assert_eq(inline_to_md(inline), "`x`")
}

///|
test "inline_to_md: Emphasis" {
  let inline = @markdown.Inline::Emphasis(
    marker=@markdown.EmphasisMarker::Asterisk,
    children=[@markdown.Inline::Text(content="i", span=@markdown.Span::empty())],
    span=@markdown.Span::empty(),
  )
  assert_eq(inline_to_md(inline), "*i*")
}

///|
test "inline_to_md: Strong" {
  let inline = @markdown.Inline::Strong(
    marker=@markdown.EmphasisMarker::Asterisk,
    children=[@markdown.Inline::Text(content="b", span=@markdown.Span::empty())],
    span=@markdown.Span::empty(),
  )
  assert_eq(inline_to_md(inline), "**b**")
}

///|
test "inline_to_md: Link" {
  let inline = @markdown.Inline::Link(
    children=[
      @markdown.Inline::Text(content="text", span=@markdown.Span::empty()),
    ],
    url="https://example.com",
    title="",
    span=@markdown.Span::empty(),
  )
  assert_eq(inline_to_md(inline), "[text](https://example.com)")
}

///|
test "inline_to_md: Image" {
  let inline = @markdown.Inline::Image(
    alt="alt text",
    url="img.png",
    title="",
    span=@markdown.Span::empty(),
  )
  assert_eq(inline_to_md(inline), "![alt text](img.png)")
}

///|
test "inline_to_md: SoftBreak" {
  let inline = @markdown.Inline::SoftBreak(span=@markdown.Span::empty())
  assert_eq(inline_to_md(inline), "\n")
}

///|
test "inline_to_md: HardBreak" {
  let inline = @markdown.Inline::HardBreak(
    style=@markdown.HardBreakStyle::Backslash,
    span=@markdown.Span::empty(),
  )
  assert_eq(inline_to_md(inline), "\n")
}

///|
test "inline_to_md: Autolink" {
  let inline = @markdown.Inline::Autolink(
    url="https://x.com",
    is_email=false,
    span=@markdown.Span::empty(),
  )
  assert_eq(inline_to_md(inline), "https://x.com")
}

///|
test "inline_to_md: HtmlInline" {
  let inline = @markdown.Inline::HtmlInline(
    html="<br>",
    span=@markdown.Span::empty(),
  )
  assert_eq(inline_to_md(inline), "<br>")
}

///|
test "inline_to_md: WikiLink" {
  let inline = @markdown.Inline::WikiLink(
    target="page",
    label="",
    fragment="",
    span=@markdown.Span::empty(),
  )
  assert_eq(inline_to_md(inline), "page")
}

///|
test "inline_to_md: RefLink" {
  let inline = @markdown.Inline::RefLink(
    children=[
      @markdown.Inline::Text(content="text", span=@markdown.Span::empty()),
    ],
    label="",
    span=@markdown.Span::empty(),
  )
  assert_eq(inline_to_md(inline), "text")
}
