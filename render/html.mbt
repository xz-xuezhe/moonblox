// MoonMark AST → HTML renderer

///|
fn escape(s : String) -> String {
  let len = s.length()
  let sb = StringBuilder::new()
  let mut i = 0
  while i < len {
    match s.get_char(i) {
      Some('&') => sb.write_string("&amp;")
      Some('<') => sb.write_string("&lt;")
      Some('>') => sb.write_string("&gt;")
      Some('"') => sb.write_string("&quot;")
      Some(c) => sb.write_char(c)
      None => ()
    }
    i = i + 1
  }
  sb.to_string()
}

// Batch-render markdown text to inline HTML via md_to_html

///|
fn inline_md_to_html(md : String) -> String {
  if md == "" {
    return ""
  }
  let html = @markdown.md_to_html(md)
  let trimmed = html.trim()
  if trimmed.has_prefix("<p>") && trimmed.has_suffix("</p>") {
    trimmed[3:trimmed.length() - 4].to_owned()
  } else {
    trimmed.to_owned()
  }
}

// Render AST inlines: consecutive Markdown nodes are serialized back
// to markdown and rendered in one batch via md_to_html; component nodes
// are rendered individually and flush the batch.

///|
fn render_inlines(
  inlines : Array[@ast.Inline],
  inline_components : Map[String, (Map[String, @ast.Value]) -> String],
) -> String {
  let sb = StringBuilder::new()
  let mut md_batch = StringBuilder::new()
  for i = 0; i < inlines.length(); i = i + 1 {
    match inlines[i] {
      @ast.Inline::Markdown(md) =>
        md_batch.write_string(@convert.inline_to_md(md))
      @ast.Inline::Component(name, args) => {
        sb.write_string(inline_md_to_html(md_batch.to_string()))
        md_batch = StringBuilder::new()
        sb.write_string(render_inline_component(name, args, inline_components))
      }
    }
  }
  sb.write_string(inline_md_to_html(md_batch.to_string()))
  sb.to_string()
}

///|
fn render_inline_component(
  name : String,
  args : Map[String, @ast.Value],
  components : Map[String, (Map[String, @ast.Value]) -> String],
) -> String {
  match components.get(name) {
    Some(render) => render(args)
    None => "<!-- unknown inline component: \{name} -->"
  }
}

///|
fn render_container_component(
  name : String,
  args : Map[String, @ast.Value],
  body : String,
  components : Map[String, (Map[String, @ast.Value], String) -> String],
) -> String {
  match components.get(name) {
    Some(render) => render(args, body)
    None => "<!-- unknown container: \{name} -->\{body}"
  }
}

// --- Block rendering (unchanged) ---

///|
fn render_block(
  block : @ast.Block,
  inlines : Map[String, (Map[String, @ast.Value]) -> String],
  containers : Map[String, (Map[String, @ast.Value], String) -> String],
) -> String {
  match block {
    @ast.Block::Paragraph(p) => {
      let sb = StringBuilder::new()
      sb.write_string("<p>")
      sb.write_string(render_inlines(p.children, inlines))
      sb.write_string("</p>")
      sb.to_string()
    }
    @ast.Block::Heading(h) => {
      let sb = StringBuilder::new()
      sb.write_string("<h")
      sb.write_string(h.level.to_string())
      sb.write_string(">")
      sb.write_string(render_inlines(h.children, inlines))
      sb.write_string("</h")
      sb.write_string(h.level.to_string())
      sb.write_string(">")
      sb.to_string()
    }
    @ast.Block::CodeBlock(cb) => {
      let sb = StringBuilder::new()
      match cb.info {
        Some(lang) => {
          sb.write_string("<pre><code class=\"language-")
          sb.write_string(escape(lang))
          sb.write_string("\">")
        }
        None => sb.write_string("<pre><code>")
      }
      sb.write_string(escape(cb.content))
      sb.write_string("</code></pre>")
      sb.to_string()
    }
    @ast.Block::ContainerComponent(cc) => {
      let body = render_blocks(cc.children, inlines, containers)
      render_container_component(cc.name, cc.args, body, containers)
    }
    @ast.Block::BlockQuote(children) => {
      let sb = StringBuilder::new()
      sb.write_string("<blockquote>\n")
      sb.write_string(render_blocks(children, inlines, containers))
      sb.write_string("</blockquote>")
      sb.to_string()
    }
    @ast.Block::List(lst) => {
      let sb = StringBuilder::new()
      if lst.tight {
        sb.write_string("<ul class=\"tight\">\n")
      } else {
        sb.write_string("<ul>\n")
      }
      sb.write_string(render_list_items(lst.items, inlines, containers))
      sb.write_string("</ul>")
      sb.to_string()
    }
    @ast.Block::ThematicBreak => "<hr />\n"
  }
}

///|
fn render_blocks(
  blocks : Array[@ast.Block],
  inlines : Map[String, (Map[String, @ast.Value]) -> String],
  containers : Map[String, (Map[String, @ast.Value], String) -> String],
) -> String {
  let sb = StringBuilder::new()
  for i = 0; i < blocks.length(); i = i + 1 {
    sb.write_string(render_block(blocks[i], inlines, containers))
    sb.write_char('\n')
  }
  sb.to_string()
}

///|
fn render_list_items(
  items : Array[@ast.ListItem],
  inlines : Map[String, (Map[String, @ast.Value]) -> String],
  containers : Map[String, (Map[String, @ast.Value], String) -> String],
) -> String {
  let sb = StringBuilder::new()
  for i = 0; i < items.length(); i = i + 1 {
    sb.write_string("<li>")
    sb.write_string(render_blocks(items[i].children, inlines, containers))
    sb.write_string("</li>\n")
  }
  sb.to_string()
}

///|
/// Render a MoonMark Document to a complete HTML page.
/// Reads theme/style.css and theme/page.html from the given directory.
/// Component maps map component names to user-provided render functions.
pub fn render_document(
  doc : @ast.Document,
  title? : String,
  theme_dir? : String = "theme",
  inline_components? : Map[String, (Map[String, @ast.Value]) -> String] = Map([]),
  container_components? : Map[
    String,
    (Map[String, @ast.Value], String) -> String,
  ] = Map([]),
) -> String raise {
  let body = render_blocks(
    doc.children,
    inline_components,
    container_components,
  )
  let page_title = title.unwrap_or("Document")
  let css_path = "\{theme_dir}/style.css"
  let html_path = "\{theme_dir}/page.html"
  let style = @fs.read_file_to_string(css_path)
  let template = @fs.read_file_to_string(html_path)
  template
  .replace(old="{{title}}", new=escape(page_title))
  .replace(old="{{style}}", new=style)
  .replace(old="{{body}}", new=body)
}
