// Directive argument parser for MoonMark
// Parses @name(key: "val", key2: 42) into component name and args

///|
fn is_name_char(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') ||
  (c >= 'A' && c <= 'Z') ||
  (c >= '0' && c <= '9') ||
  c == '_' ||
  c == '-'
}

///|
fn is_digit(c : Char) -> Bool {
  c >= '0' && c <= '9'
}

///|
fn skip_spaces(s : String, i : Int) -> Int {
  let mut j = i
  let len = s.length()
  while j < len {
    match s.get_char(j) {
      Some(' ') | Some('\t') | Some('\n') | Some('\r') => j = j + 1
      _ => break
    }
  }
  j
}

///|
fn pop_name(s : String, i : Int) -> (Int, String)? {
  let mut j = i
  let len = s.length()
  while j < len {
    match s.get_char(j) {
      Some(c) if is_name_char(c) => j = j + 1
      _ => break
    }
  }
  guard j > i else { return None }
  Some((j, s[i:j].to_owned()))
}

///|
fn pop_string(s : String, i : Int) -> (Int, String)? {
  let len = s.length()
  guard i < len else { return None }
  guard s.get_char(i) is Some('"') else { return None }
  let mut j = i + 1
  while j < len {
    match s.get_char(j) {
      Some('"') => return Some((j + 1, s[i + 1:j].to_owned()))
      Some('\\') => j = j + 1
      _ => j = j
    }
    j = j + 1
  }
  None
}

///|
fn pop_number(s : String, i : Int) -> (Int, Double)? {
  let len = s.length()
  let mut j = i
  let mut has_dot = false
  guard j < len else { return None }
  match s.get_char(j) {
    Some('-') => j = j + 1
    _ => ()
  }
  while j < len {
    match s.get_char(j) {
      Some(c) if is_digit(c) => j = j + 1
      Some('.') if !has_dot => {
        has_dot = true
        j = j + 1
      }
      _ => break
    }
  }
  guard j > i else { return None }
  let mut result = 0.0
  let mut frac_div = 1.0
  let mut in_frac = false
  let mut k = i
  let sign = match s.get_char(k) {
    Some('-') => {
      k = k + 1
      -1.0
    }
    _ => 1.0
  }
  while k < j {
    match s.get_char(k) {
      Some(c) if is_digit(c) => {
        let d = (c.to_int() - '0'.to_int()).to_double()
        if in_frac {
          frac_div = frac_div * 10.0
          result = result + d / frac_div
        } else {
          result = result * 10.0 + d
        }
      }
      Some('.') => in_frac = true
      _ => ()
    }
    k = k + 1
  }
  Some((j, result * sign))
}

///|
fn pop_bool(s : String, i : Int) -> (Int, Bool)? {
  let len = s.length()
  if i + 4 <= len && s[i:i + 4] == "true" {
    Some((i + 4, true))
  } else if i + 5 <= len && s[i:i + 5] == "false" {
    Some((i + 5, false))
  } else {
    None
  }
}

///|
fn pop_value(s : String, i : Int) -> (Int, @ast.Value)? {
  let j = skip_spaces(s, i)
  guard j < s.length() else { return None }
  match s.get_char(j) {
    Some('"') => {
      guard pop_string(s, j) is Some((k, str)) else { return None }
      Some((k, @ast.Value::Str(str)))
    }
    Some(c) if is_digit(c) || c == '-' => {
      guard pop_number(s, j) is Some((k, n)) else { return None }
      Some((k, @ast.Value::Number(n)))
    }
    Some('t') | Some('f') => {
      guard pop_bool(s, j) is Some((k, b)) else { return None }
      Some((k, @ast.Value::Bool(b)))
    }
    Some('[') => {
      guard pop_array(s, j) is Some((k, arr)) else { return None }
      Some((k, @ast.Value::Array(arr)))
    }
    Some('{') => {
      guard pop_record(s, j) is Some((k, rec)) else { return None }
      Some((k, @ast.Value::Record(rec)))
    }
    _ => None
  }
}

///|
fn pop_array(s : String, i : Int) -> (Int, Array[@ast.Value])? {
  let len = s.length()
  guard i < len else { return None }
  guard s.get_char(i) is Some('[') else { return None }
  let mut j = i + 1
  let items : Array[@ast.Value] = []
  j = skip_spaces(s, j)
  guard j < len else { return None }
  match s.get_char(j) {
    Some(']') => return Some((j + 1, items))
    _ => ()
  }
  while true {
    j = skip_spaces(s, j)
    guard pop_value(s, j) is Some((k, val)) else { return None }
    j = k
    items.push(val)
    j = skip_spaces(s, j)
    guard j < len else { return None }
    match s.get_char(j) {
      Some(',') => j = j + 1
      _ => break
    }
  }
  j = skip_spaces(s, j)
  guard j < len else { return None }
  guard s.get_char(j) is Some(']') else { return None }
  Some((j + 1, items))
}

///|
fn pop_record(s : String, i : Int) -> (Int, Map[String, @ast.Value])? {
  let len = s.length()
  guard i < len else { return None }
  guard s.get_char(i) is Some('{') else { return None }
  let mut j = i + 1
  let map : Map[String, @ast.Value] = Map([])
  j = skip_spaces(s, j)
  guard j < len else { return None }
  match s.get_char(j) {
    Some('}') => return Some((j + 1, map))
    _ => ()
  }
  while true {
    j = skip_spaces(s, j)
    guard pop_name(s, j) is Some((k, key)) else { return None }
    j = skip_spaces(s, k)
    guard j < len else { return None }
    guard s.get_char(j) is Some(':') else { return None }
    j = skip_spaces(s, j + 1)
    guard pop_value(s, j) is Some((m, val)) else { return None }
    j = m
    map.set(key, val)
    j = skip_spaces(s, j)
    guard j < len else { return None }
    match s.get_char(j) {
      Some(',') => j = j + 1
      _ => break
    }
  }
  j = skip_spaces(s, j)
  guard j < len else { return None }
  guard s.get_char(j) is Some('}') else { return None }
  Some((j + 1, map))
}

///|
fn pop_pair(s : String, i : Int) -> (Int, String, @ast.Value)? {
  let mut j = skip_spaces(s, i)
  guard pop_name(s, j) is Some((k, key)) else { return None }
  j = skip_spaces(s, k)
  guard j < s.length() else { return None }
  guard s.get_char(j) is Some(':') else { return None }
  j = skip_spaces(s, j + 1)
  guard pop_value(s, j) is Some((m, val)) else { return None }
  Some((m, key, val))
}

///|
fn pop_args(s : String, i : Int) -> (Int, Map[String, @ast.Value])? {
  let mut j = i
  let args : Map[String, @ast.Value] = Map([])
  while j < s.length() {
    j = skip_spaces(s, j)
    guard j < s.length() else { break }
    match s.get_char(j) {
      Some(')') => break
      _ => ()
    }
    guard pop_pair(s, j) is Some((k, key, val)) else { return None }
    j = k
    args.set(key, val)
    j = skip_spaces(s, j)
    guard j < s.length() else { break }
    match s.get_char(j) {
      Some(',') => j = j + 1
      _ => break
    }
  }
  Some((j, args))
}

///|
/// Parse an inline directive string: name(key: val, ...)
/// Returns (name, args) on success
pub fn parse_inline_directive(
  input : String,
) -> (String, Map[String, @ast.Value])? {
  let len = input.length()
  guard len > 0 else { return None }
  guard pop_name(input, 0) is Some((i, name)) else { return None }
  let i2 = skip_spaces(input, i)
  guard i2 < len else { return None }
  guard input.get_char(i2) is Some('(') else { return None }
  guard pop_args(input, i2 + 1) is Some((j, args)) else { return None }
  let j2 = skip_spaces(input, j)
  guard j2 < len else { return None }
  guard input.get_char(j2) is Some(')') else { return None }
  let j3 = skip_spaces(input, j2 + 1)
  guard j3 == len else { return None }
  Some((name, args))
}

///|
/// Parse a container block header: :::name(key: val, ...)
/// Returns (name, args) on success
pub fn parse_container_header(
  input : String,
) -> (String, Map[String, @ast.Value])? {
  let len = input.length()
  guard len >= 3 else { return None }
  guard input.get_char(0) is Some(':') else { return None }
  guard input.get_char(1) is Some(':') else { return None }
  guard input.get_char(2) is Some(':') else { return None }
  guard pop_name(input, 3) is Some((i, name)) else { return None }
  let i2 = skip_spaces(input, i)
  guard i2 < len else { return Some((name, Map([]))) }
  match input.get_char(i2) {
    Some('(') => {
      guard pop_args(input, i2 + 1) is Some((j, args)) else { return None }
      let j2 = skip_spaces(input, j)
      guard j2 < len else { return None }
      guard input.get_char(j2) is Some(')') else { return None }
      let j3 = skip_spaces(input, j2 + 1)
      guard j3 == len else { return None }
      Some((name, args))
    }
    _ => {
      let j3 = skip_spaces(input, i2)
      guard j3 == len else { return None }
      Some((name, Map([])))
    }
  }
}
