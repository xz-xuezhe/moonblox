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

// Render mdast inline to HTML

///|
fn render_md_inline(inline : @markdown.Inline) -> String {
  match inline {
    @markdown.Inline::Text(content~, ..) => escape(content)
    @markdown.Inline::Code(content=code, ..) => {
      let sb = StringBuilder::new()
      sb.write_string("<code>")
      sb.write_string(escape(code))
      sb.write_string("</code>")
      sb.to_string()
    }
    @markdown.Inline::Emphasis(children~, ..) => {
      let sb = StringBuilder::new()
      sb.write_string("<em>")
      sb.write_string(render_md_inlines(children))
      sb.write_string("</em>")
      sb.to_string()
    }
    @markdown.Inline::Strong(children~, ..) => {
      let sb = StringBuilder::new()
      sb.write_string("<strong>")
      sb.write_string(render_md_inlines(children))
      sb.write_string("</strong>")
      sb.to_string()
    }
    @markdown.Inline::Strikethrough(children~, ..) => {
      let sb = StringBuilder::new()
      sb.write_string("<del>")
      sb.write_string(render_md_inlines(children))
      sb.write_string("</del>")
      sb.to_string()
    }
    @markdown.Inline::Link(children~, url~, ..) => {
      let sb = StringBuilder::new()
      sb.write_string("<a href=\"")
      sb.write_string(escape(url))
      sb.write_string("\">")
      sb.write_string(render_md_inlines(children))
      sb.write_string("</a>")
      sb.to_string()
    }
    @markdown.Inline::Image(alt~, url~, ..) => {
      let sb = StringBuilder::new()
      sb.write_string("<img src=\"")
      sb.write_string(escape(url))
      sb.write_string("\" alt=\"")
      sb.write_string(escape(alt))
      sb.write_string("\" />")
      sb.to_string()
    }
    @markdown.Inline::Autolink(url~, ..) => {
      let sb = StringBuilder::new()
      sb.write_string("<a href=\"")
      sb.write_string(escape(url))
      sb.write_string("\">")
      sb.write_string(escape(url))
      sb.write_string("</a>")
      sb.to_string()
    }
    @markdown.Inline::SoftBreak(..) => "\n"
    @markdown.Inline::HardBreak(..) => "<br />\n"
    @markdown.Inline::WikiLink(target~, label~, ..) => {
      let display = if label != "" { label } else { target }
      escape(display)
    }
    @markdown.Inline::RefLink(children~, ..) => render_md_inlines(children)
    @markdown.Inline::HtmlInline(html~, ..) => html
    @markdown.Inline::RefImage(..) => ""
    @markdown.Inline::FootnoteReference(..) => ""
  }
}

///|
fn render_md_inlines(inlines : Array[@markdown.Inline]) -> String {
  let sb = StringBuilder::new()
  for i = 0; i < inlines.length(); i = i + 1 {
    sb.write_string(render_md_inline(inlines[i]))
  }
  sb.to_string()
}

// Render our AST Inline (either mdast or component)

///|
fn render_inline(inline : @ast.Inline) -> String {
  match inline {
    @ast.Inline::Markdown(md) => render_md_inline(md)
    @ast.Inline::Component(name, args) => render_component(name, args)
  }
}

///|
fn render_inlines(inlines : Array[@ast.Inline]) -> String {
  let sb = StringBuilder::new()
  for i = 0; i < inlines.length(); i = i + 1 {
    sb.write_string(render_inline(inlines[i]))
  }
  sb.to_string()
}

///|
fn render_component(name : String, args : Map[String, @ast.Value]) -> String {
  match name {
    "badge" => @components.render_badge(args)
    _ => "<!-- unknown inline component: \{name} -->"
  }
}

// --- Block rendering (unchanged) ---

///|
fn render_block(block : @ast.Block) -> String {
  match block {
    @ast.Block::Paragraph(p) => {
      let sb = StringBuilder::new()
      sb.write_string("<p>")
      sb.write_string(render_inlines(p.children))
      sb.write_string("</p>")
      sb.to_string()
    }
    @ast.Block::Heading(h) => {
      let sb = StringBuilder::new()
      sb.write_string("<h")
      sb.write_string(h.level.to_string())
      sb.write_string(">")
      sb.write_string(render_inlines(h.children))
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
      let body = render_blocks(cc.children)
      match cc.name {
        "callout" => @components.render_callout(cc.args, body)
        _ => {
          let sb = StringBuilder::new()
          sb.write_string("<!-- unknown container: ")
          sb.write_string(cc.name)
          sb.write_string(" -->")
          sb.write_string(body)
          sb.to_string()
        }
      }
    }
    @ast.Block::BlockQuote(children) => {
      let sb = StringBuilder::new()
      sb.write_string("<blockquote>\n")
      sb.write_string(render_blocks(children))
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
      sb.write_string(render_list_items(lst.items))
      sb.write_string("</ul>")
      sb.to_string()
    }
    @ast.Block::ThematicBreak => "<hr />\n"
  }
}

///|
fn render_blocks(blocks : Array[@ast.Block]) -> String {
  let sb = StringBuilder::new()
  for i = 0; i < blocks.length(); i = i + 1 {
    sb.write_string(render_block(blocks[i]))
    sb.write_char('\n')
  }
  sb.to_string()
}

///|
fn render_list_items(items : Array[@ast.ListItem]) -> String {
  let sb = StringBuilder::new()
  for i = 0; i < items.length(); i = i + 1 {
    sb.write_string("<li>")
    sb.write_string(render_blocks(items[i].children))
    sb.write_string("</li>\n")
  }
  sb.to_string()
}

///|
/// Render a MoonMark Document to a complete HTML page
pub fn render_document(doc : @ast.Document, title? : String) -> String {
  let body = render_blocks(doc.children)
  let page_title = title.unwrap_or("Document")
  let sb = StringBuilder::new()
  sb.write_string("<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n")
  sb.write_string("  <meta charset=\"UTF-8\">\n")
  sb.write_string(
    "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n",
  )
  sb.write_string("  <title>")
  sb.write_string(escape(page_title))
  sb.write_string("</title>\n")
  sb.write_string("  <style>\n")
  sb.write_string(
    "    body { font-family: system-ui, sans-serif; max-width: 800px; margin: 0 auto; padding: 2rem; line-height: 1.6; }\n",
  )
  sb.write_string(
    "    .badge { display: inline-block; padding: 0.1em 0.5em; border-radius: 4px; font-size: 0.85em; font-weight: 600; }\n",
  )
  sb.write_string("    .badge--default { background: #e5e5e5; color: #333; }\n")
  sb.write_string(
    "    .badge--warning { background: #fff3cd; color: #856404; }\n",
  )
  sb.write_string("    .badge--info { background: #d1ecf1; color: #0c5460; }\n")
  sb.write_string(
    "    .badge--success { background: #d4edda; color: #155724; }\n",
  )
  sb.write_string(
    "    .badge--error { background: #f8d7da; color: #721c24; }\n",
  )
  sb.write_string(
    "    .callout { border-left: 4px solid; padding: 1rem; margin: 1rem 0; border-radius: 4px; }\n",
  )
  sb.write_string(
    "    .callout--note { border-color: #007bff; background: #f0f7ff; }\n",
  )
  sb.write_string(
    "    .callout--warning { border-color: #ffc107; background: #fffdf0; }\n",
  )
  sb.write_string(
    "    .callout--tip { border-color: #28a745; background: #f0fff4; }\n",
  )
  sb.write_string(
    "    .callout--error { border-color: #dc3545; background: #fff5f5; }\n",
  )
  sb.write_string(
    "    .callout__title { font-weight: 700; margin-bottom: 0.5rem; }\n",
  )
  sb.write_string(
    "    pre { background: #f5f5f5; padding: 1rem; border-radius: 4px; overflow-x: auto; }\n",
  )
  sb.write_string(
    "    code { background: #f0f0f0; padding: 0.2em 0.4em; border-radius: 3px; font-size: 0.9em; }\n",
  )
  sb.write_string("    pre code { background: none; padding: 0; }\n")
  sb.write_string("  </style>\n</head>\n<body>\n")
  sb.write_string(body)
  sb.write_string("\n</body>\n</html>\n")
  sb.to_string()
}
