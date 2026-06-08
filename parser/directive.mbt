// Public API: wire lexer → generated parser → result

/// Parse an inline directive string: name(key: val, ...)
/// Returns (name, args) on success
pub fn parse_inline_directive(input : String) -> (String, Map[String, @ast.Value])? {
  let tokens = tokenize(input)
  try Some(directive(tokens)) catch {
    _ => None
  }
}

/// Parse a container block header: :::name(key: val, ...)
/// Returns (name, args) on success
pub fn parse_container_header(input : String) -> (String, Map[String, @ast.Value])? {
  // Strip the leading ::: before parsing
  let len = input.length()
  guard len >= 3 else { return None }
  guard input.get_char(0) is Some(':') else { return None }
  guard input.get_char(1) is Some(':') else { return None }
  guard input.get_char(2) is Some(':') else { return None }
  let inner = input[3:len].to_owned()
  parse_inline_directive(inner)
}
