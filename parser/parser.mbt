///|
pub(all) enum Token {
  IDENT(String)
  STRING(String)
  NUMBER(Double)
  BOOL(Bool)
  LPAREN
  RPAREN
  LBRACKET
  RBRACKET
  LBRACE
  RBRACE
  COLON
  COMMA
} derive(Debug, Eq)

///|
pub fn Token::kind(self : Token) -> TokenKind {
  match self {
    IDENT(_) => TK_IDENT
    STRING(_) => TK_STRING
    NUMBER(_) => TK_NUMBER
    BOOL(_) => TK_BOOL
    LPAREN => TK_LPAREN
    RPAREN => TK_RPAREN
    LBRACKET => TK_LBRACKET
    RBRACKET => TK_RBRACKET
    LBRACE => TK_LBRACE
    RBRACE => TK_RBRACE
    COLON => TK_COLON
    COMMA => TK_COMMA
  }
}

///|
pub(all) enum TokenKind {
  TK_IDENT
  TK_STRING
  TK_NUMBER
  TK_BOOL
  TK_LPAREN
  TK_RPAREN
  TK_LBRACKET
  TK_RBRACKET
  TK_LBRACE
  TK_RBRACE
  TK_COLON
  TK_COMMA
} derive(Eq)

///|
pub impl Show for TokenKind with fn output(self, logger) {
  logger.write_string(
    match self {
      TK_IDENT => "IDENT"
      TK_STRING => "STRING"
      TK_NUMBER => "NUMBER"
      TK_BOOL => "BOOL"
      TK_LPAREN => "\"(\""
      TK_RPAREN => "\")\""
      TK_LBRACKET => "\"[\""
      TK_RBRACKET => "\"]\""
      TK_LBRACE => "\"{\""
      TK_RBRACE => "\"}\""
      TK_COLON => "\":\""
      TK_COMMA => "\",\""
    },
  )
}

///|
pub impl Debug for TokenKind with fn to_repr(self) {
  match self {
    TK_IDENT => to_repr("IDENT")
    TK_STRING => to_repr("STRING")
    TK_NUMBER => to_repr("NUMBER")
    TK_BOOL => to_repr("BOOL")
    TK_LPAREN => to_repr("(")
    TK_RPAREN => to_repr(")")
    TK_LBRACKET => to_repr("[")
    TK_RBRACKET => to_repr("]")
    TK_LBRACE => to_repr("{")
    TK_RBRACE => to_repr("}")
    TK_COLON => to_repr(":")
    TK_COMMA => to_repr(",")
  }
}

///|
pub suberror ParseError {
  UnexpectedToken(Token, (Int, Int), Array[TokenKind])
  UnexpectedEndOfInput(Int, Array[TokenKind])
} derive(Debug)

///|
/// Cursor over a token array for recursive descent parsing.
priv struct Parser {
  tokens : Array[(Token, Int, Int)]
  mut pos : Int
}

///|
fn Parser::new(tokens : Array[(Token, Int, Int)]) -> Parser {
  { tokens, pos: 0 }
}

///|
fn Parser::eof_pos(self : Parser) -> Int {
  if self.pos > 0 {
    self.tokens[self.pos - 1].2
  } else {
    0
  }
}

///|
fn Parser::peek(self : Parser) -> (Token, Int, Int)? {
  if self.pos < self.tokens.length() {
    Some(self.tokens[self.pos])
  } else {
    None
  }
}

///|
fn Parser::peek_at(self : Parser, offset : Int) -> (Token, Int, Int)? {
  let idx = self.pos + offset
  if idx < self.tokens.length() {
    Some(self.tokens[idx])
  } else {
    None
  }
}

///|
fn Parser::check(self : Parser, kind : TokenKind) -> Bool {
  match self.peek() {
    Some((tok, _, _)) => tok.kind() == kind
    None => false
  }
}

///|
fn Parser::advance(self : Parser) -> (Token, Int, Int) raise ParseError {
  match self.peek() {
    Some(tok) => {
      self.pos = self.pos + 1
      tok
    }
    None => raise ParseError::UnexpectedEndOfInput(self.eof_pos(), [])
  }
}

///|
fn Parser::expect(self : Parser, kind : TokenKind) -> Unit raise ParseError {
  match self.peek() {
    Some(tok) =>
      if tok.0.kind() == kind {
        self.pos = self.pos + 1
      } else {
        raise ParseError::UnexpectedToken(tok.0, (tok.1, tok.2), [kind])
      }
    None => raise ParseError::UnexpectedEndOfInput(self.eof_pos(), [kind])
  }
}

///|
fn Parser::expect_ident(self : Parser) -> String raise ParseError {
  match self.peek() {
    Some((Token::IDENT(name), _, _)) => {
      self.pos = self.pos + 1
      name
    }
    Some(tok) =>
      raise ParseError::UnexpectedToken(tok.0, (tok.1, tok.2), [TK_IDENT])
    None => raise ParseError::UnexpectedEndOfInput(self.eof_pos(), [TK_IDENT])
  }
}

///|
fn Parser::starts_value(self : Parser) -> Bool {
  match self.peek() {
    Some((Token::IDENT(_), _, _)) => true
    Some((Token::STRING(_), _, _)) => true
    Some((Token::NUMBER(_), _, _)) => true
    Some((Token::BOOL(_), _, _)) => true
    Some((Token::LBRACKET, _, _)) => true
    Some((Token::LBRACE, _, _)) => true
    _ => false
  }
}

///|
fn Parser::parse_directive(
  self : Parser,
) -> (String, Map[String, @ast.Value]) raise ParseError {
  let name = self.expect_ident()
  self.expect(TK_LPAREN)
  let args = self.parse_args_opt()
  self.expect(TK_RPAREN)
  (name, args)
}

///|
fn Parser::parse_args_opt(
  self : Parser,
) -> Map[String, @ast.Value] raise ParseError {
  if self.check(TK_RPAREN) {
    Map([])
  } else {
    self.parse_args()
  }
}

///|
fn Parser::parse_args(
  self : Parser,
) -> Map[String, @ast.Value] raise ParseError {
  let map : Map[String, @ast.Value] = Map([])
  let (key, val) = self.parse_arg()
  map.set(key, val)
  while true {
    if self.check(TK_COMMA) {
      self.expect(TK_COMMA)
      if self.starts_value() {
        let (key2, val2) = self.parse_arg()
        map.set(key2, val2)
      }
    } else {
      break
    }
  }
  map
}

///|
fn Parser::parse_arg(self : Parser) -> (String, @ast.Value) raise ParseError {
  match (self.peek_at(0), self.peek_at(1)) {
    (Some((Token::IDENT(key), _, _)), Some((Token::COLON, _, _))) => {
      self.expect(TK_IDENT)
      self.expect(TK_COLON)
      let val = self.parse_value()
      (key, val)
    }
    _ => {
      let val = self.parse_value()
      ("_", val)
    }
  }
}

///|
fn Parser::parse_value(self : Parser) -> @ast.Value raise ParseError {
  match self.peek() {
    None =>
      raise ParseError::UnexpectedEndOfInput(self.eof_pos(), [
        TK_IDENT,
        TK_STRING,
        TK_NUMBER,
        TK_BOOL,
        TK_LBRACKET,
        TK_LBRACE,
      ])
    Some(tok) =>
      match tok {
        (Token::STRING(s), _, _) => {
          ignore(self.advance())
          @ast.Value::Str(s)
        }
        (Token::NUMBER(n), _, _) => {
          ignore(self.advance())
          @ast.Value::Number(n)
        }
        (Token::BOOL(b), _, _) => {
          ignore(self.advance())
          @ast.Value::Bool(b)
        }
        (Token::LBRACKET, _, _) => {
          ignore(self.advance())
          let arr = self.parse_values()
          self.expect(TK_RBRACKET)
          @ast.Value::Array(arr)
        }
        (Token::LBRACE, _, _) => {
          let rec = self.parse_record()
          @ast.Value::Record(rec)
        }
        (Token::IDENT(_), _, _) =>
          match self.peek_at(1) {
            Some((Token::LPAREN, _, _)) => {
              let name = self.expect_ident()
              self.expect(TK_LPAREN)
              let args = self.parse_args_opt()
              self.expect(TK_RPAREN)
              @ast.Value::Funcall(name, args)
            }
            _ => {
              let name = self.expect_ident()
              @ast.Value::Var(name)
            }
          }
        (tok, start_pos, end_pos) =>
          raise ParseError::UnexpectedToken(tok, (start_pos, end_pos), [
            TK_IDENT,
            TK_STRING,
            TK_NUMBER,
            TK_BOOL,
            TK_LBRACKET,
            TK_LBRACE,
          ])
      }
  }
}

///|
fn Parser::parse_values(self : Parser) -> Array[@ast.Value] raise ParseError {
  let arr : Array[@ast.Value] = []
  if self.check(TK_RBRACKET) {
    return arr
  }
  arr.push(self.parse_value())
  while true {
    if self.check(TK_COMMA) {
      self.expect(TK_COMMA)
      arr.push(self.parse_value())
    } else {
      break
    }
  }
  arr
}

///|
fn Parser::parse_record(
  self : Parser,
) -> Map[String, @ast.Value] raise ParseError {
  self.expect(TK_LBRACE)
  if self.check(TK_RBRACE) {
    self.expect(TK_RBRACE)
    return Map([])
  }
  let map = self.parse_record_fields()
  self.expect(TK_RBRACE)
  map
}

///|
fn Parser::parse_record_fields(
  self : Parser,
) -> Map[String, @ast.Value] raise ParseError {
  let map : Map[String, @ast.Value] = Map([])
  while true {
    let (key, val) = self.parse_record_field()
    map.set(key, val)
    if self.check(TK_COMMA) {
      self.expect(TK_COMMA)
    } else {
      break
    }
  }
  map
}

///|
fn Parser::parse_record_field(
  self : Parser,
) -> (String, @ast.Value) raise ParseError {
  let key = self.expect_ident()
  self.expect(TK_COLON)
  let val = self.parse_value()
  (key, val)
}

///|
/// Parse a directive from token array into a (name, args) pair.
/// Raises ParseError on invalid input.
pub fn directive(
  tokens : Array[(Token, Int, Int)],
  initial_pos? : Int,
) -> (String, Map[String, @ast.Value]) raise ParseError {
  let _ = initial_pos // reserved for backward compatibility
  let parser = Parser::new(tokens)
  parser.parse_directive()
}
