// Lexer: tokenize a directive string into (Token, start, end) tuples

fn is_name_char(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') ||
  (c >= 'A' && c <= 'Z') ||
  (c >= '0' && c <= '9') ||
  c == '_' ||
  c == '-'
}

fn is_digit(c : Char) -> Bool {
  c >= '0' && c <= '9'
}

fn skip_spaces(s : String, i : Int) -> Int {
  let len = s.length()
  let mut j = i
  while j < len {
    match s.get_char(j) {
      Some(' ') | Some('\t') | Some('\n') | Some('\r') => j = j + 1
      _ => break
    }
  }
  j
}

fn lex_string(s : String, start : Int) -> (String, Int)? {
  let len = s.length()
  guard start < len else { return None }
  guard s.get_char(start) is Some('"') else { return None }
  let mut j = start + 1
  while j < len {
    match s.get_char(j) {
      Some('"') => return Some((s[start + 1:j].to_owned(), j + 1))
      Some('\\') => j = j + 1
      _ => ()
    }
    j = j + 1
  }
  None
}

fn lex_number(s : String, start : Int) -> (Double, Int)? {
  let len = s.length()
  let mut j = start
  let mut has_dot = false
  match s.get_char(j) {
    Some('-') => j = j + 1
    _ => ()
  }
  while j < len {
    match s.get_char(j) {
      Some(c) if is_digit(c) => j = j + 1
      Some('.') if !has_dot => { has_dot = true; j = j + 1 }
      _ => break
    }
  }
  guard j > start else { return None }
  let mut result = 0.0
  let mut frac_div = 1.0
  let mut in_frac = false
  let mut k = start
  let sign = match s.get_char(k) {
    Some('-') => { k = k + 1; -1.0 }
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
  Some((result * sign, j))
}

fn lex_name(s : String, start : Int) -> (String, Int) {
  let len = s.length()
  let mut j = start
  while j < len {
    match s.get_char(j) {
      Some(c) if is_name_char(c) => j = j + 1
      _ => break
    }
  }
  (s[start:j].to_owned(), j)
}

/// Tokenize a directive string into parser-compatible token array
pub fn tokenize(input : String) -> Array[(Token, Int, Int)] {
  let len = input.length()
  let tokens : Array[(Token, Int, Int)] = []
  let mut i = skip_spaces(input, 0)
  while i < len {
    let start = i
    match input.get_char(i) {
      Some('(') => { tokens.push((Token::LPAREN, start, start + 1)); i = i + 1 }
      Some(')') => { tokens.push((Token::RPAREN, start, start + 1)); i = i + 1 }
      Some('[') => { tokens.push((Token::LBRACKET, start, start + 1)); i = i + 1 }
      Some(']') => { tokens.push((Token::RBRACKET, start, start + 1)); i = i + 1 }
      Some('{') => { tokens.push((Token::LBRACE, start, start + 1)); i = i + 1 }
      Some('}') => { tokens.push((Token::RBRACE, start, start + 1)); i = i + 1 }
      Some(':') => { tokens.push((Token::COLON, start, start + 1)); i = i + 1 }
      Some(',') => { tokens.push((Token::COMMA, start, start + 1)); i = i + 1 }
      Some('"') => {
        match lex_string(input, i) {
          Some((s, next)) => { tokens.push((Token::STRING(s), start, next)); i = next }
          None => break
        }
      }
      Some(c) if is_digit(c) || c == '-' => {
        match lex_number(input, i) {
          Some((n, next)) => { tokens.push((Token::NUMBER(n), start, next)); i = next }
          None => break
        }
      }
      Some(c) if (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') => {
        let (name, next) = lex_name(input, i)
        // Check for true/false
        if name == "true" {
          tokens.push((Token::BOOL(true), start, next))
        } else if name == "false" {
          tokens.push((Token::BOOL(false), start, next))
        } else {
          tokens.push((Token::IDENT(name), start, next))
        }
        i = next
      }
      _ => break
    }
    i = skip_spaces(input, i)
  }
  tokens
}
