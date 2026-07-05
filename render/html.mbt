// MoonBlox AST → rabbita Cell renderer

// --- Inline rendering ---

///|
/// Convert Markdown inlines directly to rabbita Html nodes.
/// Component inlines are dispatched via inline_cells.
fn render_inlines(
  inlines : Array[@ast.Inline],
  inline_cells : Map[String, (Map[String, @ast.Value]) -> @rabbita.Cell],
) -> Array[@rabbita.Html] {
  let result : Array[@rabbita.Html] = []
  for i = 0; i < inlines.length(); i = i + 1 {
    match inlines[i] {
      @ast.Inline::Markdown(md) => result.push(md_inline_to_html(md))
      @ast.Inline::Component(name, args) =>
        match inline_cells.get(name) {
          Some(cell_fn) => result.push(cell_fn(args).view())
          None =>
            result.push(@html.span([@html.text("<!-- unknown: \{name} -->")]))
        }
    }
  }
  result
}

///|
/// Map each @markdown.Inline variant to its @rabbita.Html equivalent.
fn md_inline_to_html(inline : @markdown.Inline) -> @rabbita.Html {
  match inline {
    @markdown.Inline::Text(content~, ..) => @html.text(content)
    @markdown.Inline::Code(content~, ..) => @html.code([@html.text(content)])
    @markdown.Inline::Emphasis(children~, ..) =>
      @html.em(md_inlines_to_html(children))
    @markdown.Inline::Strong(children~, ..) =>
      @html.strong(md_inlines_to_html(children))
    @markdown.Inline::Strikethrough(children~, ..) =>
      @html.del(md_inlines_to_html(children))
    @markdown.Inline::Link(children~, url~, title~, ..) => {
      let kids = md_inlines_to_html(children)
      if title == "" {
        @html.a(href=url, kids)
      } else {
        @html.a(href=url, title~, kids)
      }
    }
    @markdown.Inline::Image(alt~, url~, title~, ..) =>
      if title == "" {
        @html.img(src=url, alt~)
      } else {
        @html.img(src=url, alt~, title~)
      }
    @markdown.Inline::SoftBreak(..) => @html.text("\n")
    @markdown.Inline::HardBreak(..) => @html.br()
    @markdown.Inline::Autolink(url~, is_email~, ..) => {
      let href = if is_email { "mailto:" + url } else { url }
      @html.a(href~, [@html.text(url)])
    }
    @markdown.Inline::HtmlInline(html~, ..) => @html.text(html)
    @markdown.Inline::WikiLink(target~, label~, fragment~, ..) => {
      let href = if fragment == "" { target } else { target + "#" + fragment }
      let text = if label == "" { href } else { label }
      @html.a(href~, [@html.text(text)])
    }
    @markdown.Inline::RefLink(children~, ..) =>
      @html.span(md_inlines_to_html(children))
    @markdown.Inline::FootnoteReference(label~, ..) =>
      @html.sup([@html.text("[^" + label + "]")])
    @markdown.Inline::RefImage(alt~, ..) => @html.text("![" + alt + "]")
  }
}

///|
fn md_inlines_to_html(
  inlines : Array[@markdown.Inline],
) -> Array[@rabbita.Html] {
  let result : Array[@rabbita.Html] = []
  for i = 0; i < inlines.length(); i = i + 1 {
    result.push(md_inline_to_html(inlines[i]))
  }
  result
}

// --- Block rendering ---

///|
fn render_block(
  block : @ast.Block,
  inline_cells : Map[String, (Map[String, @ast.Value]) -> @rabbita.Cell],
  container_cells : Map[
    String,
    (Map[String, @ast.Value], Array[@rabbita.Html]) -> @rabbita.Cell,
  ],
) -> @rabbita.Cell {
  match block {
    @ast.Block::Paragraph(p) =>
      @rabbita.static_cell(@html.p(render_inlines(p.children, inline_cells)))
    @ast.Block::Heading(h) =>
      @rabbita.static_cell(render_heading(h.level, h.children, inline_cells))
    @ast.Block::CodeBlock(cb) => @rabbita.static_cell(render_code_block(cb))
    @ast.Block::ContainerComponent(cc) =>
      render_container(cc, inline_cells, container_cells)
    @ast.Block::BlockQuote(children) => {
      let kids : Array[@rabbita.Html] = []
      for i = 0; i < children.length(); i = i + 1 {
        kids.push(
          render_block(children[i], inline_cells, container_cells).view(),
        )
      }
      @rabbita.static_cell(@html.blockquote(kids))
    }
    @ast.Block::List(lst) =>
      @rabbita.static_cell(render_list(lst, inline_cells, container_cells))
    @ast.Block::Table(t) => @rabbita.static_cell(render_table(t, inline_cells))
    @ast.Block::ThematicBreak => @rabbita.static_cell(@html.hr())
  }
}

///|
fn render_table(
  t : @ast.BlockTable,
  inline_cells : Map[String, (Map[String, @ast.Value]) -> @rabbita.Cell],
) -> @rabbita.Html {
  let align_attr = fn(align : @markdown.TableAlign) -> String {
    match align {
      @markdown.TableAlign::Left => "left"
      @markdown.TableAlign::Center => "center"
      @markdown.TableAlign::Right => "right"
      @markdown.TableAlign::None => ""
    }
  }

  let render_cell = fn(
    cell : @ast.BlockTableCell,
    tag : String,
    align : @markdown.TableAlign,
  ) -> @rabbita.Html {
    let kids = render_inlines(cell.children, inline_cells)
    let attrs = match align {
      @markdown.TableAlign::None => @html.Attrs::build()
      a => @html.Attrs::build().align(align_attr(a))
    }
    @html.node(tag, attrs, kids)
  }

  let header_cells : Array[@rabbita.Html] = []
  for i = 0; i < t.header.length(); i = i + 1 {
    let cell = t.header[i]
    let align = if i < t.alignments.length() {
      t.alignments[i]
    } else {
      @markdown.TableAlign::None
    }
    header_cells.push(render_cell(cell, "th", align))
  }
  let thead = @html.thead([@html.tr(header_cells)])

  let body_rows : Array[@rabbita.Html] = []
  for i = 0; i < t.rows.length(); i = i + 1 {
    let row = t.rows[i]
    let cells : Array[@rabbita.Html] = []
    for j = 0; j < row.length(); j = j + 1 {
      let cell = row[j]
      let align = if j < t.alignments.length() {
        t.alignments[j]
      } else {
        @markdown.TableAlign::None
      }
      cells.push(render_cell(cell, "td", align))
    }
    body_rows.push(@html.tr(cells))
  }
  let tbody = @html.tbody(body_rows)

  @html.table([thead, tbody])
}

///|
fn render_heading(
  level : Int,
  inlines : Array[@ast.Inline],
  inline_cells : Map[String, (Map[String, @ast.Value]) -> @rabbita.Cell],
) -> @rabbita.Html {
  let kids = render_inlines(inlines, inline_cells)
  match level {
    1 => @html.h1(kids)
    2 => @html.h2(kids)
    3 => @html.h3(kids)
    4 => @html.h4(kids)
    5 => @html.h5(kids)
    _ => @html.h6(kids)
  }
}

///|
fn render_code_block(cb : @ast.BlockCode) -> @rabbita.Html {
  match cb.info {
    Some(lang) =>
      @html.pre([@html.code(class="language-\{lang}", [@html.text(cb.content)])])
    None => @html.pre([@html.code([@html.text(cb.content)])])
  }
}

///|
fn render_container(
  cc : @ast.BlockContainer,
  inline_cells : Map[String, (Map[String, @ast.Value]) -> @rabbita.Cell],
  container_cells : Map[
    String,
    (Map[String, @ast.Value], Array[@rabbita.Html]) -> @rabbita.Cell,
  ],
) -> @rabbita.Cell {
  let kids : Array[@rabbita.Html] = []
  for i = 0; i < cc.children.length(); i = i + 1 {
    let child_cell = render_block(cc.children[i], inline_cells, container_cells)
    kids.push(child_cell.view())
  }
  match container_cells.get(cc.name) {
    Some(cell_fn) => cell_fn(cc.args, kids)
    None => @rabbita.static_cell(@html.div(kids))
  }
}

///|
/// Strip leading list marker ("- ", "* ", "1. ", etc.) from an inline array.
fn strip_list_marker(inlines : Array[@ast.Inline]) -> Array[@ast.Inline] {
  if inlines.length() == 0 {
    return inlines
  }
  match inlines[0] {
    @ast.Inline::Markdown(@markdown.Inline::Text(content~, span~)) => {
      let trimmed = content.trim_start()
      let is_bullet = trimmed.has_prefix("- ") ||
        trimmed.has_prefix("* ") ||
        trimmed.has_prefix("+ ")
      let is_ordered = trimmed.length() >= 2 &&
        trimmed.get_char(0) is Some(c) &&
        c >= '0' &&
        c <= '9' &&
        trimmed.get_char(1) is Some('.') &&
        (trimmed.length() == 2 || trimmed.get_char(2) is Some(' '))
      if is_bullet {
        let new_content = trimmed[2:].to_owned()
        let result : Array[@ast.Inline] = [
          @ast.Inline::Markdown(
            @markdown.Inline::Text(content=new_content, span~),
          ),
        ]
        for k = 1; k < inlines.length(); k = k + 1 {
          result.push(inlines[k])
        }
        result
      } else if is_ordered {
        let dot_pos = 2
        let after_dot = if trimmed.length() > dot_pos &&
          trimmed.get_char(dot_pos) is Some(' ') {
          dot_pos + 1
        } else {
          dot_pos
        }
        let new_content = trimmed[after_dot:].to_owned()
        let result : Array[@ast.Inline] = [
          @ast.Inline::Markdown(
            @markdown.Inline::Text(content=new_content, span~),
          ),
        ]
        for k = 1; k < inlines.length(); k = k + 1 {
          result.push(inlines[k])
        }
        result
      } else {
        inlines
      }
    }
    _ => inlines
  }
}

///|
/// Strip leading list marker from the first paragraph in a block array.
fn strip_first_paragraph_marker(
  blocks : Array[@ast.Block],
) -> Array[@ast.Block] {
  if blocks.length() == 0 {
    return blocks
  }
  let result : Array[@ast.Block] = []
  match blocks[0] {
    @ast.Block::Paragraph(p) => {
      let stripped = strip_list_marker(p.children)
      result.push(@ast.Block::Paragraph({ children: stripped }))
    }
    _ => result.push(blocks[0])
  }
  for k = 1; k < blocks.length(); k = k + 1 {
    result.push(blocks[k])
  }
  result
}

///|
fn render_list(
  lst : @ast.BlockList,
  inline_cells : Map[String, (Map[String, @ast.Value]) -> @rabbita.Cell],
  container_cells : Map[
    String,
    (Map[String, @ast.Value], Array[@rabbita.Html]) -> @rabbita.Cell,
  ],
) -> @rabbita.Html {
  let items : Array[@rabbita.Html] = []
  for i = 0; i < lst.items.length(); i = i + 1 {
    let item = lst.items[i]
    let stripped_children = strip_first_paragraph_marker(item.children)
    let kids : Array[@rabbita.Html] = []
    for j = 0; j < stripped_children.length(); j = j + 1 {
      kids.push(
        render_block(stripped_children[j], inline_cells, container_cells).view(),
      )
    }
    items.push(@html.li(kids))
  }
  if lst.ordered {
    @html.ol(items)
  } else {
    @html.ul(items)
  }
}

// --- Document rendering ---

///|
/// Build a Cell tree for the document body, injecting front-matter metadata.
pub fn render_document(
  doc : @ast.Document,
  inline_cells? : Map[String, (Map[String, @ast.Value]) -> @rabbita.Cell] = Map([],
  ),
  container_cells? : Map[
    String,
    (Map[String, @ast.Value], Array[@rabbita.Html]) -> @rabbita.Cell,
  ] = Map([]),
) -> @rabbita.Cell {
  let children : Array[@rabbita.Html] = []
  let mut injected_title = false
  // Inject title from front matter
  match doc.meta.get("title") {
    Some(title) => {
      children.push(@html.h1(class="page-title", [@html.text(title)]))
      injected_title = true
    }
    None => ()
  }
  // Inject date from front matter
  match doc.meta.get("date") {
    Some(date) =>
      children.push(
        @html.time(class="page-date", datetime=date, [@html.text(date)]),
      )
    None => ()
  }
  // Render document blocks, skipping first h1 if already injected from front matter
  for i = 0; i < doc.children.length(); i = i + 1 {
    if injected_title && i == 0 {
      match doc.children[0] {
        @ast.Block::Heading(h) if h.level == 1 => continue
        _ => ()
      }
    }
    let cell = render_block(doc.children[i], inline_cells, container_cells)
    children.push(cell.view())
  }
  @rabbita.static_cell(@html.div(children))
}
