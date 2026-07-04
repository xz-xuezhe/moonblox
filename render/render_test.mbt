// MoonBlox render module tests

///|
/// Parse MoonBlox Document to HTML string
fn render_doc(doc : @ast.Document) -> String {
  @rabbita.render_to_string(render_document(doc))
}

///|
/// Parse Markdown string to MoonBlox Document
fn parse_simple(md : String) -> @ast.Document {
  @convert.parse_markdown(md)
}

///|
/// Parse Markdown with YAML front matter to MoonBlox Document
fn parse_markdown_with_meta(md : String) -> @ast.Document {
  @convert.parse_markdown(md)
}

// --- Block types ---

///|
test "render: empty document" {
  let doc = parse_simple("")
  let html = render_doc(doc)
  assert_eq(html, "<div></div>")
}

///|
test "render: paragraph" {
  let doc = parse_simple("Hello world")
  let html = render_doc(doc)
  assert_eq(html, "<div><p>Hello world</p></div>")
}

///|
test "render: heading h1" {
  let doc = parse_simple("# Title")
  let html = render_doc(doc)
  assert_eq(html, "<div><h1>Title</h1></div>")
}

///|
test "render: heading h2" {
  let doc = parse_simple("## Subtitle")
  let html = render_doc(doc)
  assert_eq(html, "<div><h2>Subtitle</h2></div>")
}

///|
test "render: code block" {
  let doc = parse_simple("```\ncode\n```")
  let html = render_doc(doc)
  assert_eq(html.contains("code"), true)
  assert_eq(html.contains("<pre>"), true)
}

///|
test "render: code block with language" {
  let doc = parse_simple("```python\ncode\n```")
  let html = render_doc(doc)
  assert_eq(html.contains("<pre>"), true)
  assert_eq(html.contains("language-python"), true)
  assert_eq(html.contains("code"), true)
}

///|
test "render: thematic break" {
  let doc = parse_simple("---")
  let html = render_doc(doc)
  assert_eq(html.contains("<hr>"), true)
}

///|
test "render: blockquote" {
  let doc = parse_simple("> quoted")
  let html = render_doc(doc)
  assert_eq(html.contains("<blockquote>"), true)
}

///|
test "render: unordered list" {
  let doc = parse_simple("- item1\n- item2")
  let html = render_doc(doc)
  assert_eq(html.contains("<ul>"), true)
  assert_eq(html.contains("<li>"), true)
  assert_eq(html.contains("item1"), true)
  assert_eq(html.contains("item2"), true)
}

///|
test "render: ordered list" {
  let doc = parse_simple("1. first\n2. second")
  let html = render_doc(doc)
  // Note: render_list always produces <ul> (no ordered list distinction yet)
  assert_eq(html.contains("<ul>"), true)
  assert_eq(html.contains("<li>"), true)
  assert_eq(html.contains("first"), true)
}

///|
test "render: table" {
  let doc = parse_simple("| A | B |\n|---|---|\n| 1 | 2 |")
  let html = render_doc(doc)
  assert_eq(html.contains("<table>"), true)
  assert_eq(html.contains("<thead>"), true)
  assert_eq(html.contains("<tbody>"), true)
  assert_eq(html.contains("<th>"), true)
  assert_eq(html.contains("<td>"), true)
}

// --- Inline formatting ---

///|
test "render: bold" {
  let doc = parse_simple("**bold**")
  let html = render_doc(doc)
  assert_eq(html.contains("<strong>"), true)
}

///|
test "render: italic" {
  let doc = parse_simple("*italic*")
  let html = render_doc(doc)
  assert_eq(html.contains("<em>"), true)
}

///|
test "render: inline code" {
  let doc = parse_simple("`code`")
  let html = render_doc(doc)
  assert_eq(html.contains("<code>"), true)
}

///|
test "render: link" {
  let doc = parse_simple("[link](https://example.com)")
  let html = render_doc(doc)
  assert_eq(html.contains("<a"), true)
  assert_eq(html.contains("href"), true)
}

///|
test "render: image" {
  let doc = parse_simple("![alt](https://img.png)")
  let html = render_doc(doc)
  assert_eq(html.contains("<img"), true)
  assert_eq(html.contains("alt="), true)
}

///|
test "render: strikethrough" {
  let doc = parse_simple("~~strike~~")
  let html = render_doc(doc)
  assert_eq(html.contains("<del>"), true)
}

// --- Front matter ---

///|
test "render: front matter title" {
  let doc = parse_markdown_with_meta("---\ntitle: Test\n---\n\ncontent")
  let html = render_doc(doc)
  assert_eq(html.contains("<h1"), true)
  assert_eq(html.contains("Test"), true)
  assert_eq(html.contains("content"), true)
}

///|
test "render: front matter date" {
  let doc = parse_markdown_with_meta("---\ndate: 2024-01-01\n---\n\ntext")
  let html = render_doc(doc)
  assert_eq(html.contains("<time"), true)
  assert_eq(html.contains("2024-01-01"), true)
}

///|
test "render: no front matter" {
  let doc = parse_simple("just text")
  let html = render_doc(doc)
  // Should not have page-title h1 when no front matter
  assert_eq(html.contains("page-title"), false)
}

// --- Edge cases ---

///|
test "render: multiple blocks" {
  let doc = parse_simple("# H1\n\npara\n\n## H2")
  let html = render_doc(doc)
  assert_eq(html.contains("<h1>H1</h1>"), true)
  assert_eq(html.contains("<p>para</p>"), true)
  assert_eq(html.contains("<h2>H2</h2>"), true)
}

///|
test "render: empty heading" {
  let doc = parse_simple("# ")
  let html = render_doc(doc)
  assert_eq(html.contains("<h1>"), true)
}

///|
test "render: nested formatting" {
  let doc = parse_simple("**bold *and italic***")
  let html = render_doc(doc)
  assert_eq(html.contains("<strong>"), true)
}
