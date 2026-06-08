// cmark AST → MoonMark AST converter

// --- Inline-level conversion ---

// Process a text string: find @directive patterns and split into
// Text + InlineComponent nodes

///|
fn process_text(text : String) -> Array[@ast.Inline] {
  let result : Array[@ast.Inline] = []
  let mut pos = 0
  let len = text.length()
  while pos < len {
    // Find the next '@'
    let at_pos = find_at(text, pos)
    match at_pos {
      Some(p) => {
        if p > pos {
          // Text before the @directive
          result.push(@ast.Inline::Text(text[pos:p].to_owned()))
        }
        // Try to parse a directive starting at p+1 (after @)
        let directive_end = find_directive_end(text, p + 1)
        match directive_end {
          Some(end) => {
            let directive_str = text[p + 1:end].to_owned()
            match @parser.parse_inline_directive(directive_str) {
              Some((name, args)) =>
                result.push(@ast.Inline::InlineComponent(name, args))
              None =>
                // Failed to parse — treat @ as plain text
                result.push(@ast.Inline::Text(text[p:end].to_owned()))
            }
            pos = end
          }
          None => {
            // No valid directive after @ — treat as text
            result.push(@ast.Inline::Text("@"))
            pos = p + 1
          }
        }
      }
      None => {
        // No more @ — rest is text
        result.push(@ast.Inline::Text(text[pos:len].to_owned()))
        break
      }
    }
  }
  result
}

// Find the next '@' in string starting from pos

///|
fn find_at(s : String, start : Int) -> Int? {
  let len = s.length()
  let mut i = start
  while i < len {
    match s.get_char(i) {
      Some('@') =>
        if i + 1 < len {
          match s.get_char(i + 1) {
            Some(c) if (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') =>
              return Some(i)
            _ => ()
          }
        }
      _ => ()
    }
    i = i + 1
  }
  None
}

// Find the end of a directive starting at pos (after @)

///|
fn find_directive_end(s : String, start : Int) -> Int? {
  let len = s.length()
  let mut i = start
  // Skip name characters
  while i < len {
    match s.get_char(i) {
      Some(c) if (c >= 'a' && c <= 'z') ||
        (c >= 'A' && c <= 'Z') ||
        (c >= '0' && c <= '9') ||
        c == '_' ||
        c == '-' => i = i + 1
      _ => break
    }
  }
  // Skip whitespace
  while i < len {
    match s.get_char(i) {
      Some(' ') | Some('\t') => i = i + 1
      _ => break
    }
  }
  guard i < len else { return None }
  guard s.get_char(i) is Some('(') else { return None }
  // Find matching ')'
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

// Skip over a string literal starting at the opening quote

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

// Convert a cmark Inline node to MoonMark Inline array

///|
fn convert_inline(cmark_inline : @cmark.Inline) -> Array[@ast.Inline] {
  match cmark_inline {
    @cmark.Inline::Text(node) => process_text(node.v)
    @cmark.Inline::Emphasis(emph) => {
      let children = convert_inline(emph.v.inline)
      [@ast.Inline::Emphasis(children)]
    }
    @cmark.Inline::StrongEmphasis(emph) => {
      let children = convert_inline(emph.v.inline)
      [@ast.Inline::Strong(children)]
    }
    @cmark.Inline::CodeSpan(cs) => [@ast.Inline::CodeSpan(cs.v.code())]
    @cmark.Inline::Link(link) => {
      let children = convert_inline(link.v.text)
      let url = match link.v.reference {
        @cmark.ReferenceKind::Inline(def) =>
          def.v.dest.map(fn(n) { n.v }).unwrap_or("")
        _ => ""
      }
      [@ast.Inline::Link(url, None, children)]
    }
    @cmark.Inline::Image(img) => {
      let url = match img.v.reference {
        @cmark.ReferenceKind::Inline(def) =>
          def.v.dest.map(fn(n) { n.v }).unwrap_or("")
        _ => ""
      }
      [@ast.Inline::Image(url, None, "")]
    }
    @cmark.Inline::Break(br) =>
      match br.v.ty {
        @cmark.InlineBreakType::Hard => [@ast.Inline::HardBreak]
        @cmark.InlineBreakType::Soft => [@ast.Inline::SoftBreak]
      }
    @cmark.Inline::Autolink(link) => {
      let url = link.v.link.v
      [@ast.Inline::Link(url, None, [@ast.Inline::Text(url)])]
    }
    @cmark.Inline::RawHtml(_) => []
    @cmark.Inline::Inlines(inlines) => {
      let result : Array[@ast.Inline] = []
      let arr = inlines.v.to_array()
      for i = 0; i < arr.length(); i = i + 1 {
        let children = convert_inline(arr[i])
        for j = 0; j < children.length(); j = j + 1 {
          result.push(children[j])
        }
      }
      result
    }
    @cmark.Inline::ExtStrikethrough(st) => convert_inline(st.v.0)
    @cmark.Inline::ExtMathSpan(_) => []
  }
}

// --- Block-level conversion ---

///|
fn convert_block(cmark_block : @cmark.Block) -> Array[@ast.Block] {
  match cmark_block {
    @cmark.Block::Paragraph(p) => {
      let children = convert_inline(p.v.inline)
      [@ast.Block::Paragraph({ children, })]
    }
    @cmark.Block::Heading(h) => {
      let children = convert_inline(h.v.inline)
      [@ast.Block::Heading({ level: h.v.level, children })]
    }
    @cmark.Block::CodeBlock(cb) => {
      let code = cb.v.code.to_array().map(fn(n) { n.v }).join("")
      let info = cb.v.info_string.map(fn(n) { n.v })
      [@ast.Block::CodeBlock({ info, content: code })]
    }
    @cmark.Block::BlockQuote(bq) => {
      let children = convert_block(bq.v.block)
      [@ast.Block::BlockQuote(children)]
    }
    @cmark.Block::List(lst) => {
      let item_arr = lst.v.items.to_array()
      let items : Array[@ast.ListItem] = []
      for i = 0; i < item_arr.length(); i = i + 1 {
        let cmark_item = item_arr[i]
        let children = convert_block(cmark_item.v.block)
        items.push({ children, })
      }
      [@ast.Block::List({ tight: lst.v.tight, items })]
    }
    @cmark.Block::ThematicBreak(_) => [@ast.Block::ThematicBreak]
    @cmark.Block::BlankLine(_) => []
    @cmark.Block::Blocks(blocks) => {
      let result : Array[@ast.Block] = []
      let arr = blocks.v.to_array()
      for i = 0; i < arr.length(); i = i + 1 {
        let children = convert_block(arr[i])
        for j = 0; j < children.length(); j = j + 1 {
          result.push(children[j])
        }
      }
      result
    }
    @cmark.Block::HtmlBlock(_) => []
    @cmark.Block::LinkRefDefinition(_) => []
    @cmark.Block::ExtMathBlock(_) => []
    @cmark.Block::ExtTable(_) => []
    @cmark.Block::ExtFootnoteDefinition(_) => []
  }
}

// Serialize inline nodes back to Markdown text, preserving formatting

///|
fn inline_to_markdown(inlines : Array[@ast.Inline]) -> String {
  let sb = StringBuilder::new()
  for i = 0; i < inlines.length(); i = i + 1 {
    match inlines[i] {
      @ast.Inline::Text(s) => sb.write_string(s)
      @ast.Inline::CodeSpan(s) => {
        sb.write_char('`')
        sb.write_string(s)
        sb.write_char('`')
      }
      @ast.Inline::Strong(children) => {
        sb.write_string("**")
        sb.write_string(inline_to_markdown(children))
        sb.write_string("**")
      }
      @ast.Inline::Emphasis(children) => {
        sb.write_char('*')
        sb.write_string(inline_to_markdown(children))
        sb.write_char('*')
      }
      @ast.Inline::Link(url, _title, children) => {
        sb.write_char('[')
        sb.write_string(inline_to_markdown(children))
        sb.write_string("](")
        sb.write_string(url)
        sb.write_char(')')
      }
      @ast.Inline::Image(url, _title, alt) => {
        sb.write_string("![")
        sb.write_string(alt)
        sb.write_string("](")
        sb.write_string(url)
        sb.write_char(')')
      }
      @ast.Inline::InlineComponent(name, args) => {
        sb.write_char('@')
        sb.write_string(name)
        sb.write_string(args_to_string(args))
      }
      @ast.Inline::SoftBreak => sb.write_char('\n')
      @ast.Inline::HardBreak => sb.write_char('\n')
    }
  }
  sb.to_string()
}

// Serialize component args back to DSL syntax

///|
fn args_to_string(args : Map[String, @ast.Value]) -> String {
  let sb = StringBuilder::new()
  sb.write_char('(')
  let keys = args.keys().to_array()
  for i = 0; i < keys.length(); i = i + 1 {
    if i > 0 {
      sb.write_string(", ")
    }
    let key = keys[i]
    sb.write_string(key)
    sb.write_string(": ")
    sb.write_string(value_to_string(args[key]))
  }
  sb.write_char(')')
  sb.to_string()
}

///|
fn value_to_string(v : @ast.Value) -> String {
  match v {
    @ast.Value::Str(s) => {
      let sb = StringBuilder::new()
      sb.write_char('"')
      sb.write_string(s)
      sb.write_char('"')
      sb.to_string()
    }
    @ast.Value::Number(n) => n.to_string()
    @ast.Value::Bool(b) => if b { "true" } else { "false" }
    @ast.Value::Array(_arr) => "[...]"
    @ast.Value::Record(_map) => "{...}"
  }
}

// Try to detect and extract a single-paragraph container block
// Returns (name, args, body_lines) if this paragraph is a :::container...:::

///|
fn try_extract_container(
  inlines : Array[@ast.Inline],
) -> (String, Map[String, @ast.Value], String)? {
  // Check if first text node starts with :::
  guard inlines.length() > 0 else { return None }
  guard inlines[0] is @ast.Inline::Text(first_text) else { return None }
  guard first_text.has_prefix(":::") else { return None }
  // Parse the first line as container header
  let first_newline = find_newline_in_text(first_text)
  let header = match first_newline {
    Some(end) => first_text[0:end].to_owned()
    None => first_text
  }
  guard @parser.parse_container_header(header) is Some((name, args)) else {
    return None
  }
  // Reconstruct full text and check for closing :::
  let full_text = inline_to_markdown(inlines)
  // Split into lines and find the closing :::
  let lines = split_lines(full_text)
  guard lines.length() >= 2 else { return None }
  // Last non-empty line should be :::
  let mut last_idx = lines.length() - 1
  while last_idx > 0 {
    if lines[last_idx] != "" {
      break
    }
    last_idx = last_idx - 1
  }
  guard last_idx > 0 else { return None }
  guard lines[last_idx].trim() == ":::" else { return None }
  // Body is lines[1..last_idx]
  let body_lines : Array[String] = []
  for j = 1; j < last_idx; j = j + 1 {
    body_lines.push(lines[j])
  }
  let body = join_lines(body_lines)
  Some((name, args, body))
}

///|
fn find_newline_in_text(s : String) -> Int? {
  let len = s.length()
  let mut i = 0
  while i < len {
    match s.get_char(i) {
      Some('\n') => return Some(i)
      _ => i = i + 1
    }
  }
  None
}

// Split a string into lines by \n

///|
fn split_lines(s : String) -> Array[String] {
  let len = s.length()
  let result : Array[String] = []
  let mut start = 0
  let mut i = 0
  while i < len {
    match s.get_char(i) {
      Some('\n') => {
        result.push(s[start:i].to_owned())
        start = i + 1
      }
      _ => ()
    }
    i = i + 1
  }
  if start <= len {
    result.push(s[start:len].to_owned())
  }
  result
}

// Join an array of lines with newlines

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

// Post-process blocks to detect and convert :::name(...) ... ::: containers

///|
fn merge_container_blocks(blocks : Array[@ast.Block]) -> Array[@ast.Block] {
  let result : Array[@ast.Block] = []
  let mut i = 0
  while i < blocks.length() {
    match blocks[i] {
      @ast.Block::Paragraph(p) =>
        // Check if this paragraph is a single-block container
        match try_extract_container(p.children) {
          Some((name, args, body)) => {
            let body_doc = parse_markdown(body)
            result.push(
              @ast.Block::ContainerComponent({
                name,
                args,
                children: merge_container_blocks(body_doc.children),
              }),
            )
            i = i + 1
          }
          None => {
            // Check for multi-block container (separate opener/closer paragraphs)
            let text = inline_to_markdown(p.children)
            if text.has_prefix(":::") {
              match @parser.parse_container_header(text) {
                Some((name, args)) => {
                  let inner : Array[@ast.Block] = []
                  i = i + 1
                  while i < blocks.length() {
                    match blocks[i] {
                      @ast.Block::Paragraph(inner_p) => {
                        let inner_text = inline_to_markdown(inner_p.children)
                        if inner_text.trim() == ":::" {
                          i = i + 1
                          break
                        }
                      }
                      _ => ()
                    }
                    inner.push(blocks[i])
                    i = i + 1
                  }
                  let processed_inner = merge_container_blocks(inner)
                  result.push(
                    @ast.Block::ContainerComponent({
                      name,
                      args,
                      children: processed_inner,
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
        }
      _ => {
        result.push(blocks[i])
        i = i + 1
      }
    }
  }
  result
}

///|
/// Convert a cmark Doc to a MoonMark @ast.Document
pub fn convert_doc(cmark_doc : @cmark.Doc) -> @ast.Document {
  let children = convert_block(cmark_doc.block)
  let merged = merge_container_blocks(children)
  @ast.Document::{ children: merged }
}

///|
/// Parse a Markdown string and convert to MoonMark AST
pub fn parse_markdown(input : String) -> @ast.Document {
  let escaped = escape_directives(input)
  let doc = @cmark.Doc::from_string(escaped, strict=true)
  convert_doc(doc)
}

// Escape cmark-special characters (*, _, `) inside @name(...) directives
// so cmark's inline parser doesn't break our directive syntax.
fn escape_directives(s : String) -> String {
  let len = s.length()
  let sb = StringBuilder::new()
  let mut i = 0
  while i < len {
    match s.get_char(i) {
      Some('@') => {
        // Check if this is a directive start: @ followed by name char
        if i + 1 < len {
          match s.get_char(i + 1) {
            Some(c) if is_directive_name_start(c) => {
              // Find the opening '('
              let paren = find_opening_paren(s, i + 1)
              match paren {
                Some(paren_pos) => {
                  // Find the matching closing ')'
                  let close = find_matching_paren(s, paren_pos + 1)
                  match close {
                    Some(close_pos) => {
                      // Write @name as-is
                      sb.write_char('@')
                      // name part
                      let name_str = s[i + 1:paren_pos].to_owned()
                      sb.write_string(name_str)
                      // Open paren
                      sb.write_char('(')
                      // Escape the content between parens
                      let inner = s[paren_pos + 1:close_pos].to_owned()
                      sb.write_string(escape_special_chars(inner))
                      // Close paren
                      sb.write_char(')')
                      i = close_pos + 1
                    }
                    None => {
                      sb.write_char('@')
                      i = i + 1
                    }
                  }
                }
                None => {
                  sb.write_char('@')
                  i = i + 1
                }
              }
            }
            _ => {
              sb.write_char('@')
              i = i + 1
            }
          }
        } else {
          sb.write_char('@')
          i = i + 1
        }
      }
      Some(c) => {
        sb.write_char(c)
        i = i + 1
      }
      None => break
    }
  }
  sb.to_string()
}

fn is_directive_name_start(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}

fn find_opening_paren(s : String, pos : Int) -> Int? {
  let len = s.length()
  let mut i = pos
  while i < len {
    match s.get_char(i) {
      Some(c) if (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_' || c == '-' => i = i + 1
      Some(' ') | Some('\t') => i = i + 1
      Some('(') => return Some(i)
      _ => return None
    }
  }
  None
}

fn find_matching_paren(s : String, start : Int) -> Int? {
  let len = s.length()
  let mut depth = 1
  let mut i = start
  while i < len && depth > 0 {
    match s.get_char(i) {
      Some('(') => depth = depth + 1
      Some(')') => depth = depth - 1
      Some('"') => i = skip_string(s, i)
      _ => ()
    }
    if depth > 0 {
      i = i + 1
    }
  }
  guard depth == 0 else { return None }
  Some(i)
}

fn escape_special_chars(s : String) -> String {
  let len = s.length()
  let sb = StringBuilder::new()
  let mut i = 0
  while i < len {
    match s.get_char(i) {
      Some('*') => sb.write_string("\\*")
      Some('_') => sb.write_string("\\_")
      Some('`') => sb.write_string("\\`")
      Some(c) => sb.write_char(c)
      None => ()
    }
    i = i + 1
  }
  sb.to_string()
}
