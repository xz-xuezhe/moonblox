// Directive encoding: @name(args) → <!--mm name(args)-->
// Encoded as HTML comments so markdown parser treats directive content
// as raw text, naturally protected from emphasis/code span interference.

///|
fn is_name_start(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}

///|
fn is_name_char(c : Char) -> Bool {
  is_name_start(c) || (c >= '0' && c <= '9') || c == '_' || c == '-'
}

///|
fn find_at(s : String, start : Int) -> Int? {
  let len = s.length()
  for i = start; i < len; i = i + 1 {
    match s.get_char(i) {
      Some('@') =>
        if i + 1 < len {
          match s.get_char(i + 1) {
            Some(c) if is_name_start(c) => return Some(i)
            _ => ()
          }
        }
      _ => ()
    }
  }
  None
}

///|
fn directive_end(s : String, start : Int) -> Int? {
  let len = s.length()
  let mut i = start
  while i < len {
    match s.get_char(i) {
      Some(c) if is_name_char(c) => i = i + 1
      _ => break
    }
  }
  while i < len {
    match s.get_char(i) {
      Some(' ') | Some('\t') => i = i + 1
      _ => break
    }
  }
  guard i < len else { return None }
  guard s.get_char(i) is Some('(') else { return None }
  let mut depth = 1
  let mut j = i + 1
  while j < len && depth > 0 {
    match s.get_char(j) {
      Some('(') => depth = depth + 1
      Some(')') => depth = depth - 1
      Some('"') => {
        j = j + 1
        while j < len {
          match s.get_char(j) {
            Some('"') => break
            Some('\\') => j = j + 1
            _ => ()
          }
          j = j + 1
        }
      }
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
fn collapse_newlines(s : StringView) -> String {
  let sb = StringBuilder::new()
  let len = s.length()
  for i = 0; i < len; i = i + 1 {
    match s.get_char(i) {
      Some('\n') | Some('\r') => sb.write_char(' ')
      Some(c) => sb.write_char(c)
      None => ()
    }
  }
  sb.to_string()
}

///|
fn encode_directives(text : String) -> String {
  let len = text.length()
  let sb = StringBuilder::new()
  let mut i = 0
  while i < len {
    let at = find_at(text, i)
    match at {
      Some(at_pos) => {
        sb.write_string(text[i:at_pos].to_owned())
        let end = directive_end(text, at_pos + 1)
        match end {
          Some(end_pos) => {
            let directive = collapse_newlines(text[at_pos + 1:end_pos])
            sb.write_string("<!--mm ")
            sb.write_string(directive)
            sb.write_string("-->")
            i = end_pos
          }
          None => {
            sb.write_char('@')
            i = at_pos + 1
          }
        }
      }
      None => {
        sb.write_string(text[i:len].to_owned())
        break
      }
    }
  }
  sb.to_string()
}

///|
fn parse_inline_content(text : String) -> Array[@ast.Inline] {
  let encoded = encode_directives(text)
  let md_inlines = @markdown.parse_inlines(encoded)
  decode_inlines(md_inlines)
}

///|
fn decode_inlines(inlines : Array[@markdown.Inline]) -> Array[@ast.Inline] {
  let result : Array[@ast.Inline] = []
  for i = 0; i < inlines.length(); i = i + 1 {
    match inlines[i] {
      @markdown.Inline::HtmlInline(html~, ..) =>
        if html.has_prefix("<!--mm ") && html.has_suffix("-->") {
          let start = "<!--mm ".length()
          let end = html.length() - "-->".length()
          let inner = html[start:end].to_owned()
          match @parser.parse_inline_directive(inner) {
            Some((name, args)) =>
              result.push(@ast.Inline::Component(name, args))
            None => {
              let text = "@" + inner
              for j = 0; j < text.length(); j = j + 1 {
                result.push(wrap_md_text(text[j:j + 1].to_owned()))
              }
            }
          }
        } else {
          result.push(@ast.Inline::Markdown(inlines[i]))
        }
      _ => result.push(@ast.Inline::Markdown(inlines[i]))
    }
  }
  result
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
