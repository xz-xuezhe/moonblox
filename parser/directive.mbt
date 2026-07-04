// Public API: wire lexer → generated parser → result

///|
/// Parse an inline directive string: name(key: val, ...)
/// Returns (name, args) on success
pub fn parse_inline_directive(
  input : String,
) -> (String, Map[String, @ast.Value])? {
  let tokens = tokenize(input)
  Some(directive(tokens)) catch {
    _ => None
  }
}

///|
/// Parse a structured block header: ::name { key: val, ... }
/// Strips :: prefix, wraps as name({ ... }) to use the existing directive parser,
/// and extracts the record contents as the args map.
pub fn parse_structured_header(
  input : String,
) -> (String, Map[String, @ast.Value])? {
  let trimmed = input.trim().to_owned()
  let len = trimmed.length()
  guard len >= 2 else { return None }
  guard trimmed.get_char(0) is Some(':') else { return None }
  guard trimmed.get_char(1) is Some(':') else { return None }
  let inner = trimmed[2:].trim().to_owned()
  match inner.find("{") {
    None => None
    Some(brace_idx) => {
      let name = inner[0:brace_idx].trim().to_owned()
      if name == "" {
        return None
      }
      let rest = inner[brace_idx:].trim().to_owned()
      let wrapped = name + "(" + rest + ")"
      match parse_inline_directive(wrapped) {
        Some((_, args)) =>
          // The record was parsed as a single arg with key "_"
          match args["_"] {
            @ast.Value::Record(rec) => Some((name, rec))
            _ => Some((name, Map([])))
          }
        None => None
      }
    }
  }
}

///|
/// Parse a container block header: :::name(key: val, ...)
/// Returns (name, args) on success
pub fn parse_container_header(
  input : String,
) -> (String, Map[String, @ast.Value])? {
  // Strip the leading ::: before parsing
  let len = input.length()
  guard len >= 3 else { return None }
  guard input.get_char(0) is Some(':') else { return None }
  guard input.get_char(1) is Some(':') else { return None }
  guard input.get_char(2) is Some(':') else { return None }
  let inner = input[3:len].to_owned()
  parse_inline_directive(inner)
}
