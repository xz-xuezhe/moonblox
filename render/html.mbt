// MoonBlox AST → rabbita Cell renderer

// --- Inline rendering ---

///|
/// Batch consecutive Markdown inlines → serialize to markdown →
/// render via md_to_html → inject as inner_html span.
/// Component inlines break the batch and render individually.
fn render_inlines(
  inlines : Array[@ast.Inline],
  inline_cells : Map[String, (Map[String, @ast.Value]) -> @rabbita.Cell],
) -> Array[@rabbita.Html] {
  let result : Array[@rabbita.Html] = []
  let mut batch : Array[@markdown.Inline] = []
  for i = 0; i < inlines.length(); i = i + 1 {
    match inlines[i] {
      @ast.Inline::Markdown(md) => batch.push(md)
      @ast.Inline::Component(name, args) => {
        flush_md_batch(result, batch)
        batch = []
        match inline_cells.get(name) {
          Some(cell_fn) => result.push(cell_fn(args).view())
          None => {
            let msg = "<!-- unknown inline: \{name} -->"
            let attrs = @html.Attrs::build().inner_html(msg)
            let empty : Array[@rabbita.Html] = []
            result.push(@html.span(attrs~, empty))
          }
        }
      }
    }
  }
  flush_md_batch(result, batch)
  result
}

///|
fn flush_md_batch(
  result : Array[@rabbita.Html],
  batch : Array[@markdown.Inline],
) -> Unit {
  if batch.length() == 0 {
    return
  }
  let sb = StringBuilder::new()
  for i = 0; i < batch.length(); i = i + 1 {
    sb.write_string(@convert.inline_to_md(batch[i]))
  }
  let html = @markdown.md_to_html(sb.to_string()).trim()
  let inner = if html.has_prefix("<p>") && html.has_suffix("</p>") {
    html[3:html.length() - 4].to_owned()
  } else {
    html.to_owned()
  }
  let attrs = @html.Attrs::build().inner_html(inner)
  let empty : Array[@rabbita.Html] = []
  result.push(@html.span(attrs~, empty))
}

// --- Block rendering ---

///|
fn render_block(
  block : @ast.Block,
  inline_cells : Map[String, (Map[String, @ast.Value]) -> @rabbita.Cell],
  container_cells : Map[
    String,
    (Map[String, @ast.Value], String) -> @rabbita.Cell,
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
    (Map[String, @ast.Value], String) -> @rabbita.Cell,
  ],
) -> @rabbita.Cell {
  let sb = StringBuilder::new()
  for i = 0; i < cc.children.length(); i = i + 1 {
    if i > 0 {
      sb.write_char('\n')
    }
    let child_cell = render_block(cc.children[i], inline_cells, container_cells)
    sb.write_string(@rabbita.render_to_string(child_cell))
  }
  let body = sb.to_string()
  match container_cells.get(cc.name) {
    Some(cell_fn) => cell_fn(cc.args, body)
    None => {
      let empty : Array[@rabbita.Html] = []
      @rabbita.static_cell(
        @html.div(attrs=@html.Attrs::build().inner_html(body), empty),
      )
    }
  }
}

///|
fn render_list(
  lst : @ast.BlockList,
  inline_cells : Map[String, (Map[String, @ast.Value]) -> @rabbita.Cell],
  container_cells : Map[
    String,
    (Map[String, @ast.Value], String) -> @rabbita.Cell,
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
    (Map[String, @ast.Value], String) -> @rabbita.Cell,
  ] = Map([]),
) -> @rabbita.Cell {
  let children : Array[@rabbita.Html] = []
  for i = 0; i < doc.children.length(); i = i + 1 {
    let cell = render_block(doc.children[i], inline_cells, container_cells)
    children.push(cell.view())
  }
  @rabbita.static_cell(@html.div(children))
}
