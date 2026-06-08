// mdast Block → MoonMark Block conversion + container block detection

// Extract inline text from a block's span in the source, strip trailing \n

///|
fn raw_span_text(source : String, span : @markdown.Span) -> String {
  let raw = source[span.from:span.to].to_owned()
  let len = raw.length()
  if len > 0 && raw.get_char(len - 1) is Some('\n') {
    raw[0:len - 1].to_owned()
  } else {
    raw
  }
}

///|
fn parse_span_inlines(
  source : String,
  span : @markdown.Span,
) -> Array[@ast.Inline] {
  parse_inline_content(raw_span_text(source, span))
}

///|
fn strip_atx_prefix(raw : String, level : Int) -> String {
  let len = raw.length()
  let mut i = 0
  while i < len && i < level && raw.get_char(i) is Some('#') {
    i = i + 1
  }
  if i < len && raw.get_char(i) is Some(' ') {
    i = i + 1
  }
  if i >= len {
    raw
  } else {
    raw[i:].to_owned()
  }
}

///|
fn strip_setext_suffix(raw : String) -> String {
  let len = raw.length()
  let mut end = len
  for i = 0; i < len; i = i + 1 {
    match raw.get_char(i) {
      Some('\n') => {
        end = i
        break
      }
      _ => ()
    }
  }
  if end > 0 && end < len {
    raw[0:end].to_owned()
  } else {
    raw
  }
}

///|
fn convert_block(block : @markdown.Block, source : String) -> Array[@ast.Block] {
  match block {
    @markdown.Block::Paragraph(children=_, span~, ..) => {
      let inlines = parse_span_inlines(source, span)
      match try_extract_container(inlines) {
        Some((name, args, body)) => {
          let body_doc = parse_markdown(body)
          [
            @ast.Block::ContainerComponent({
              name,
              args,
              children: body_doc.children,
            }),
          ]
        }
        None => [@ast.Block::Paragraph({ children: inlines })]
      }
    }
    @markdown.Block::Heading(level~, style~, children=_, span~, ..) => {
      let raw = raw_span_text(source, span)
      let text = match style {
        @markdown.HeadingStyle::Atx => strip_atx_prefix(raw, level)
        @markdown.HeadingStyle::Setext => strip_setext_suffix(raw)
      }
      let inlines = parse_inline_content(text)
      [@ast.Block::Heading({ level, children: inlines })]
    }
    @markdown.Block::FencedCode(info~, code~, ..) => {
      let lang = if info == "" { None } else { Some(info) }
      [@ast.Block::CodeBlock({ info: lang, content: code })]
    }
    @markdown.Block::IndentedCode(code~, ..) =>
      [@ast.Block::CodeBlock({ info: None, content: code })]
    @markdown.Block::Blockquote(children~, ..) => {
      let converted = convert_blocks(children, source)
      [@ast.Block::BlockQuote(converted)]
    }
    @markdown.Block::BulletList(tight~, items~, ..) => {
      let list_items : Array[@ast.ListItem] = []
      for i = 0; i < items.length(); i = i + 1 {
        list_items.push(@ast.ListItem::{
          children: convert_blocks(items[i].children, source),
        })
      }
      [@ast.Block::List({ tight, items: list_items })]
    }
    @markdown.Block::OrderedList(tight~, items~, ..) => {
      let list_items : Array[@ast.ListItem] = []
      for i = 0; i < items.length(); i = i + 1 {
        list_items.push(@ast.ListItem::{
          children: convert_blocks(items[i].children, source),
        })
      }
      [@ast.Block::List({ tight, items: list_items })]
    }
    @markdown.Block::ThematicBreak(..) => [@ast.Block::ThematicBreak]
    @markdown.Block::HtmlBlock(html~, ..) => {
      let trimmed = html.trim().to_owned()
      if trimmed.has_prefix(":::") {
        match @parser.parse_container_header(trimmed) {
          Some((_name, _args)) =>
            [@ast.Block::Paragraph({ children: [wrap_md_text(html)] })]
          None =>
            if trimmed == ":::" {
              [@ast.Block::Paragraph({ children: [wrap_md_text(":::")] })]
            } else {
              []
            }
        }
      } else {
        []
      }
    }
    @markdown.Block::BlankLines(..) => []
    @markdown.Block::Table(..) => []
    @markdown.Block::FootnoteDefinition(..) => []
  }
}

///|
fn convert_blocks(
  blocks : Array[@markdown.Block],
  source : String,
) -> Array[@ast.Block] {
  let result : Array[@ast.Block] = []
  for i = 0; i < blocks.length(); i = i + 1 {
    let converted = convert_block(blocks[i], source)
    for j = 0; j < converted.length(); j = j + 1 {
      result.push(converted[j])
    }
  }
  result
}

// --- Container block detection ---

///|
fn try_extract_container(
  inlines : Array[@ast.Inline],
) -> (String, Map[String, @ast.Value], String)? {
  guard inlines.length() > 0 else { return None }
  guard get_inline_text(inlines[0]) is Some(first) else { return None }
  guard first.has_prefix(":::") else { return None }
  let text = inline_to_markdown(inlines)
  let lines = split_lines(text)
  guard lines.length() >= 2 else { return None }
  guard lines[0].has_prefix(":::") && lines[0] != ":::" else { return None }
  guard @parser.parse_container_header(lines[0]) is Some((name, args)) else {
    return None
  }
  let mut last_idx = lines.length() - 1
  while last_idx > 0 && lines[last_idx] == "" {
    last_idx = last_idx - 1
  }
  guard last_idx > 0 && lines[last_idx].trim() == ":::" else { return None }
  let body_lines : Array[String] = []
  for j = 1; j < last_idx; j = j + 1 {
    body_lines.push(lines[j])
  }
  Some((name, args, join_lines(body_lines)))
}

// --- Multi-block container merging ---

///|
fn merge_containers(blocks : Array[@ast.Block]) -> Array[@ast.Block] {
  let result : Array[@ast.Block] = []
  let mut i = 0
  while i < blocks.length() {
    match blocks[i] {
      @ast.Block::Paragraph(p) => {
        let text = inline_to_markdown(p.children)
        if text.has_prefix(":::") {
          match @parser.parse_container_header(text.trim().to_owned()) {
            Some((name, args)) => {
              let inner : Array[@ast.Block] = []
              i = i + 1
              while i < blocks.length() {
                match blocks[i] {
                  @ast.Block::Paragraph(inner_p) => {
                    let t = inline_to_markdown(inner_p.children).trim()
                    if t == ":::" {
                      i = i + 1
                      break
                    }
                  }
                  _ => ()
                }
                inner.push(blocks[i])
                i = i + 1
              }
              let processed = merge_containers(inner)
              result.push(
                @ast.Block::ContainerComponent({
                  name,
                  args,
                  children: processed,
                }),
              )
            }
            None => {
              result.push(blocks[i])
              i = i + 1
            }
          }
        } else {
          result.push(blocks[i])
          i = i + 1
        }
      }
      _ => {
        result.push(blocks[i])
        i = i + 1
      }
    }
  }
  result
}

// --- Public API ---

///|
/// Parse a Markdown string and convert to MoonMark AST
pub fn parse_markdown(input : String) -> @ast.Document {
  let result = @markdown.parse(input)
  let children = convert_blocks(result.document.children, input)
  let merged = merge_containers(children)
  @ast.Document::{ children: merged }
}
