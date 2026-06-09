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
        let empty : Array[@rabbita.Html] = []
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
    @markdown.Inline::HtmlInline(html~, ..) => {
      let empty : Array[@rabbita.Html] = []
      @html.span(attrs=@html.Attrs::build().inner_html(html), empty)
    }
    @markdown.Inline::WikiLink(target~, label~, fragment~, ..) => {
      let href = if fragment == "" { target } else { target + "#" + fragment }
      let text = if label == "" { href } else { label }
      @html.a(href~, [@html.text(text)])
    }
    @markdown.Inline::RefLink(children~, ..) =>
      @html.span(md_inlines_to_html(children))
    @markdown.Inline::RefImage(..) | @markdown.Inline::FootnoteReference(..) =>
      @html.text("")
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
    @ast.Block::ThematicBreak => @rabbita.static_cell(@html.hr())
  }
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
    let kids : Array[@rabbita.Html] = []
    for j = 0; j < item.children.length(); j = j + 1 {
      kids.push(
        render_block(item.children[j], inline_cells, container_cells).view(),
      )
    }
    items.push(@html.li(kids))
  }
  @html.ul(items)
}

// --- Document rendering ---

///|
/// Build a Cell tree for the document body.
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
  for i = 0; i < doc.children.length(); i = i + 1 {
    let cell = render_block(doc.children[i], inline_cells, container_cells)
    children.push(cell.view())
  }
  @rabbita.static_cell(@html.div(children))
}
