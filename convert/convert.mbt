// mdast → MoonMark AST converter
// Single-pass: intercept @directives from raw paragraph text before markdown inline parsing

// --- Directive scanning on raw text ---

///|
fn is_name_start(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}

///|
fn is_name_char(c : Char) -> Bool {
  is_name_start(c) || (c >= '0' && c <= '9') || c == '_' || c == '-'
}

///|
fn find_at_sign(s : String, start : Int) -> Int? {
  let len = s.length()
  let mut i = start
  while i < len {
    match s.get_char(i) {
      Some('`') =>
        // Skip code span — find matching closing backtick
        i = skip_code_span(s, i)
      Some('@') =>
        if i + 1 < len {
          match s.get_char(i + 1) {
            Some(c) if is_name_start(c) => return Some(i)
            _ => i = i + 1
          }
        } else {
          i = i + 1
        }
      _ => i = i + 1
    }
  }
  None
}

///|
fn skip_code_span(s : String, start : Int) -> Int {
  let len = s.length()
  // Count consecutive backticks
  let mut count = 1
  let mut i = start + 1
  while i < len {
    match s.get_char(i) {
      Some('`') => {
        count = count + 1
        i = i + 1
      }
      _ => break
    }
  }
  // Find matching closing sequence of same length
  while i < len {
    match s.get_char(i) {
      Some('`') => {
        let mut matched = 0
        let mut j = i
        while j < len && matched < count {
          match s.get_char(j) {
            Some('`') => {
              matched = matched + 1
              j = j + 1
            }
            _ => break
          }
        }
        if matched == count {
          return j
        }
        i = j
      }
      Some('\\') => i = i + 1
      _ => ()
    }
    i = i + 1
  }
  len
}

// Find the end of a directive starting at @ position (after the @ sign)

///|
fn find_directive_end(s : String, start : Int) -> Int? {
  let len = s.length()
  let mut i = start
  // Skip name
  while i < len {
    match s.get_char(i) {
      Some(c) if is_name_char(c) => i = i + 1
      _ => break
    }
  }
  // Skip whitespace, expect '('
  while i < len {
    match s.get_char(i) {
      Some(' ') | Some('\t') => i = i + 1
      _ => break
    }
  }
  guard i < len else { return None }
  guard s.get_char(i) is Some('(') else { return None }
  // Track paren depth, skipping strings
  let mut depth = 1
  let mut j = i + 1
  while j < len && depth > 0 {
    match s.get_char(j) {
      Some('(') => depth = depth + 1
      Some(')') => depth = depth - 1
      Some('"') => j = skip_string(s, j)
      _ => ()
    }
    if depth > 0 {
      j = j + 1
    }
  }
  guard depth == 0 else { return None }
  Some(j + 1)
}

///|
fn skip_string(s : String, start : Int) -> Int {
  let len = s.length()
  let mut j = start + 1
  while j < len {
    match s.get_char(j) {
      Some('"') => return j
      Some('\\') => j = j + 1
      _ => ()
    }
    j = j + 1
  }
  start
}

// Parse inline content: intercept @directives, delegate rest to markdown

///|
fn parse_inline_content(text : String) -> Array[@ast.Inline] {
  let result : Array[@ast.Inline] = []
  let len = text.length()
  let mut pos = 0
  while pos < len {
    let at = find_at_sign(text, pos)
    match at {
      Some(at_pos) => {
        if at_pos > pos {
          push_md_inlines(result, text[pos:at_pos])
        }
        let end = find_directive_end(text, at_pos + 1)
        match end {
          Some(end_pos) => {
            let directive = text[at_pos + 1:end_pos].to_owned()
            match @parser.parse_inline_directive(directive) {
              Some((name, args)) =>
                result.push(@ast.Inline::Component(name, args))
              None => push_md_inlines(result, text[at_pos:end_pos])
            }
            pos = end_pos
          }
          None =>
            // @ without valid (...) — not a directive, keep scanning
            pos = at_pos + 1
        }
      }
      None => {
        push_md_inlines(result, text[pos:])
        break
      }
    }
  }
  result
}

///|
fn push_md_inlines(result : Array[@ast.Inline], text : StringView) -> Unit {
  let inlines = @markdown.parse_inlines(text.to_owned())
  for i = 0; i < inlines.length(); i = i + 1 {
    result.push(@ast.Inline::Markdown(inlines[i]))
  }
}

///|
fn wrap_md_text(s : String) -> @ast.Inline {
  @ast.Inline::Markdown(
    @markdown.Inline::Text(content=s, span=@markdown.Span::empty()),
  )
}

///|
fn get_inline_text(inline : @ast.Inline) -> String? {
  match inline {
    @ast.Inline::Markdown(@markdown.Inline::Text(content~, ..)) => Some(content)
    _ => None
  }
}

// --- Inline content extraction from blocks ---

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

// Extract inline text from a block's span in the source, parse it directly

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
  // Find the newline before the underline
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

// --- Block conversion ---

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

// If a paragraph starts with :::name(...), extract it as a container

///|
fn try_extract_container(
  inlines : Array[@ast.Inline],
) -> (String, Map[String, @ast.Value], String)? {
  guard inlines.length() > 0 else { return None }
  guard get_inline_text(inlines[0]) is Some(first) else { return None }
  guard first.has_prefix(":::") else { return None }
  // Reconstruct full text with proper line breaks
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

// --- Inline → Markdown serialization (for container detection) ---

///|
fn inline_to_markdown(inlines : Array[@ast.Inline]) -> String {
  let sb = StringBuilder::new()
  for i = 0; i < inlines.length(); i = i + 1 {
    match inlines[i] {
      @ast.Inline::Markdown(md) => sb.write_string(inline_text(md))
      @ast.Inline::Component(name, args) => {
        sb.write_char('@')
        sb.write_string(name)
        sb.write_string(args_to_md(args))
      }
    }
  }
  sb.to_string()
}

// Extract text from a mdast Inline, approximating back to markdown

///|
fn inline_text(inline : @markdown.Inline) -> String {
  match inline {
    @markdown.Inline::Text(content~, ..) => content
    @markdown.Inline::Code(content~, ..) => {
      let s = StringBuilder::new()
      s.write_char('`')
      s.write_string(content)
      s.write_char('`')
      s.to_string()
    }
    @markdown.Inline::Emphasis(children~, ..) => {
      let s = StringBuilder::new()
      s.write_char('*')
      for i = 0; i < children.length(); i = i + 1 {
        s.write_string(inline_text(children[i]))
      }
      s.write_char('*')
      s.to_string()
    }
    @markdown.Inline::Strong(children~, ..) => {
      let s = StringBuilder::new()
      s.write_string("**")
      for i = 0; i < children.length(); i = i + 1 {
        s.write_string(inline_text(children[i]))
      }
      s.write_string("**")
      s.to_string()
    }
    @markdown.Inline::Strikethrough(children~, ..) => {
      let s = StringBuilder::new()
      s.write_string("~~")
      for i = 0; i < children.length(); i = i + 1 {
        s.write_string(inline_text(children[i]))
      }
      s.write_string("~~")
      s.to_string()
    }
    @markdown.Inline::Link(children~, url~, ..) => {
      let s = StringBuilder::new()
      s.write_char('[')
      for i = 0; i < children.length(); i = i + 1 {
        s.write_string(inline_text(children[i]))
      }
      s.write_string("](")
      s.write_string(url)
      s.write_char(')')
      s.to_string()
    }
    @markdown.Inline::Image(alt~, url~, ..) => {
      let s = StringBuilder::new()
      s.write_string("![")
      s.write_string(alt)
      s.write_string("](")
      s.write_string(url)
      s.write_char(')')
      s.to_string()
    }
    @markdown.Inline::SoftBreak(..) | @markdown.Inline::HardBreak(..) => "\n"
    @markdown.Inline::Autolink(url~, ..) => url
    @markdown.Inline::HtmlInline(html~, ..) => html
    @markdown.Inline::WikiLink(target~, ..) => target
    @markdown.Inline::RefLink(children~, ..) => {
      let s = StringBuilder::new()
      for i = 0; i < children.length(); i = i + 1 {
        s.write_string(inline_text(children[i]))
      }
      s.to_string()
    }
    @markdown.Inline::RefImage(..) => ""
    @markdown.Inline::FootnoteReference(..) => ""
  }
}

///|
fn args_to_md(args : Map[String, @ast.Value]) -> String {
  let sb = StringBuilder::new()
  sb.write_char('(')
  let keys = args.keys().to_array()
  for i = 0; i < keys.length(); i = i + 1 {
    if i > 0 {
      sb.write_string(", ")
    }
    let k = keys[i]
    sb.write_string(k)
    sb.write_string(": ")
    match args[k] {
      @ast.Value::Str(s) => {
        sb.write_char('"')
        sb.write_string(s)
        sb.write_char('"')
      }
      @ast.Value::Number(n) => sb.write_string(n.to_string())
      @ast.Value::Bool(b) =>
        if b {
          sb.write_string("true")
        } else {
          sb.write_string("false")
        }
      _ => sb.write_string("...")
    }
  }
  sb.write_char(')')
  sb.to_string()
}

///|
fn split_lines(s : String) -> Array[String] {
  let result : Array[String] = []
  let len = s.length()
  let mut start = 0
  for i = 0; i < len; i = i + 1 {
    match s.get_char(i) {
      Some('\n') => {
        result.push(s[start:i].to_owned())
        start = i + 1
      }
      _ => ()
    }
  }
  if start <= len {
    result.push(s[start:len].to_owned())
  }
  result
}

///|
fn join_lines(lines : Array[String]) -> String {
  let sb = StringBuilder::new()
  for i = 0; i < lines.length(); i = i + 1 {
    if i > 0 {
      sb.write_char('\n')
    }
    sb.write_string(lines[i])
  }
  sb.to_string()
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
