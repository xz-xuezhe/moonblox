// mdast Block → MoonBlox Block conversion + container block detection

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
        None =>
          match try_extract_structured_block(inlines) {
            Some((name, args, body_blocks)) =>
              [
                @ast.Block::ContainerComponent({
                  name,
                  args,
                  children: body_blocks,
                }),
              ]
            None => [@ast.Block::Paragraph({ children: inlines })]
          }
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
      } else if trimmed.has_prefix("::") && trimmed.contains("{") {
        // Structured block header: ::name { key: val, ... }
        match @parser.parse_structured_header(trimmed) {
          Some((_name, _args)) =>
            [@ast.Block::Paragraph({ children: [wrap_md_text(html)] })]
          None => []
        }
      } else if trimmed == "::" {
        // Closing :: — consumed
        []
      } else {
        []
      }
    }
    @markdown.Block::BlankLines(..) => []
    @markdown.Block::Table(header~, alignments~, rows~, ..) => {
      fn convert_table_cell(cell : @markdown.TableCell) -> @ast.BlockTableCell {
        { children: parse_span_inlines(source, cell.span) }
      }
      [
        @ast.Block::Table({
          header: header.map(convert_table_cell),
          alignments,
          rows: rows.map(fn(row) { row.map(convert_table_cell) }),
        }),
      ]
    }
    @markdown.Block::FootnoteDefinition(span~, ..) => {
      let inlines = parse_span_inlines(source, span)
      [@ast.Block::Paragraph({ children: inlines })]
    }
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

///|
fn find_matching_brace(s : String, start : Int) -> Int? {
  let len = s.length()
  guard start < len else { return None }
  guard s.get_char(start) is Some('{') else { return None }
  let mut depth = 1
  let mut i = start + 1
  while i < len && depth > 0 {
    match s.get_char(i) {
      Some('{') => depth = depth + 1
      Some('}') => depth = depth - 1
      _ => ()
    }
    if depth > 0 {
      i = i + 1
    }
  }
  if depth == 0 {
    Some(i)
  } else {
    None
  }
}

///|
/// Check if the first inline starts a structured block header: ::name { ... }
fn is_structured_header(inlines : Array[@ast.Inline]) -> Bool {
  guard inlines.length() > 0 else { return false }
  guard get_inline_text(inlines[0]) is Some(first) else { return false }
  guard first.has_prefix("::") else { return false }
  guard first.length() >= 3 else { return false }
  guard first.get_char(2) is Some(c) && c != ':' else { return false }
  first.contains("{")
}

///|
/// Extract body from multi-line structured block content.
/// Returns None if no closing :: found.
fn extract_multi_line_body(
  lines : Array[String],
  after_record : String,
  name : String,
  args : Map[String, @ast.Value],
) -> (String, Map[String, @ast.Value], Array[@ast.Block])? {
  let body_lines : Array[String] = []
  if after_record.trim() != "" {
    body_lines.push(after_record)
  }
  // First pass: look for :: on its own line
  let mut found_close = false
  let mut j = 1
  while j < lines.length() {
    if lines[j].trim() == "::" {
      found_close = true
      j = j + 1
      break
    }
    body_lines.push(lines[j])
    j = j + 1
  }
  // Second pass: look for :: at end of the last body line
  if !found_close && body_lines.length() > 0 {
    let last_idx = body_lines.length() - 1
    let last = body_lines[last_idx].trim().to_owned()
    match last.find("::") {
      Some(pos) => {
        let after = last[pos + 2:].trim()
        if after == "" {
          found_close = true
          let body_part = last[0:pos].trim().to_owned()
          body_lines[last_idx] = body_part
        }
      }
      None => ()
    }
  }
  if !found_close {
    return None
  }
  let body_str = join_lines(body_lines)
  let body_doc = parse_markdown(body_str)
  Some((name, args, body_doc.children))
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

// --- Structured block detection ---

///|
fn try_extract_structured_block(
  inlines : Array[@ast.Inline],
) -> (String, Map[String, @ast.Value], Array[@ast.Block])? {
  guard inlines.length() > 0 else { return None }
  guard get_inline_text(inlines[0]) is Some(first) else { return None }
  guard first.has_prefix("::") && !first.has_prefix(":::") else { return None }
  let text = inline_to_markdown(inlines)
  let lines = split_lines(text)
  guard lines.length() >= 1 else { return None }
  let first_line = lines[0].trim().to_owned()
  guard first_line.length() >= 3 else { return None }
  guard first_line.contains("{") else { return None }
  // Strip :: and parse the header
  let inner = first_line[2:].trim().to_owned()
  match inner.find("{") {
    None => None
    Some(brace_idx) => {
      let name = inner[0:brace_idx].trim().to_owned()
      if name == "" {
        return None
      }
      match find_matching_brace(inner, brace_idx) {
        Some(close_brace) => {
          let header = "::" +
            name +
            " " +
            inner[brace_idx:close_brace + 1].to_owned()
          match @parser.parse_structured_header(header) {
            Some((parsed_name, args)) => {
              let after_record = inner[close_brace + 1:].to_owned()
              if lines.length() == 1 {
                // Inline form: everything on one line
                let rest = after_record.trim().to_owned()
                match rest.find("::") {
                  Some(close_pos) => {
                    let after_close = rest[close_pos + 2:].trim()
                    if after_close != "" {
                      return None
                    }
                    let body_text = rest[0:close_pos].trim().to_owned()
                    let body_doc = parse_markdown(body_text)
                    Some((parsed_name, args, body_doc.children))
                  }
                  None => None
                }
              } else {
                extract_multi_line_body(lines, after_record, parsed_name, args)
              }
            }
            None => None
          }
        }
        None => None
      }
    }
  }
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
        } else if is_structured_header(p.children) {
          match @parser.parse_structured_header(text.trim().to_owned()) {
            Some((name, args)) => {
              let inner : Array[@ast.Block] = []
              i = i + 1
              while i < blocks.length() {
                match blocks[i] {
                  @ast.Block::Paragraph(inner_p) => {
                    let t = inline_to_markdown(inner_p.children).trim()
                    if t == "::" {
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
/// Parse a Markdown string and convert to MoonBlox AST
pub fn parse_markdown(input : String) -> @ast.Document {
  let result = @markdown.parse(input)
  let children = convert_blocks(result.document.children, input)
  let merged = merge_containers(children)
  let meta : Map[String, String] = match result.document.frontmatter {
    Some(fm) => {
      let m : Map[String, String] = Map([])
      for i = 0; i < fm.entries.length(); i = i + 1 {
        let (k, v) = fm.entries[i]
        m.set(k, v)
      }
      m
    }
    None => Map([])
  }
  @ast.Document::{ children: merged, meta }
}
