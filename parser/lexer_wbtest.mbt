///|
test "tokenize: empty" {
  assert_eq(tokenize("").length(), 0)
}

///|
test "tokenize: whitespace only" {
  assert_eq(tokenize("   ").length(), 0)
}

///|
test "tokenize: name only" {
  let tokens = tokenize("myName")
  assert_eq(tokens.length(), 1)
  let (token, start, end) = tokens[0]
  assert_eq(start, 0)
  assert_eq(end, 6)
  match token {
    Token::IDENT("myName") => ()
    _ => {
      println("expected IDENT")
      assert_eq(1, 2)
    }
  }
}

///|
test "tokenize: bool true" {
  let tokens = tokenize("x: true")
  assert_eq(tokens.length(), 3)
  match tokens[2].0 {
    Token::BOOL(true) => ()
    _ => {
      println("expected BOOL(true)")
      assert_eq(1, 2)
    }
  }
}

///|
test "tokenize: bool false" {
  let tokens = tokenize("x: false")
  match tokens[2].0 {
    Token::BOOL(false) => ()
    _ => {
      println("expected BOOL(false)")
      assert_eq(1, 2)
    }
  }
}

///|
test "tokenize: string" {
  let tokens = tokenize("x: \"hello\"")
  assert_eq(tokens.length(), 3)
  match tokens[2].0 {
    Token::STRING("hello") => ()
    _ => {
      println("expected STRING")
      assert_eq(1, 2)
    }
  }
}

///|
test "tokenize: number" {
  let tokens = tokenize("x: 42")
  assert_eq(tokens.length(), 3)
  match tokens[2].0 {
    Token::NUMBER(n) => assert_eq(n == 42.0, true)
    _ => {
      println("expected NUMBER")
      assert_eq(1, 2)
    }
  }
}

///|
test "tokenize: negative number" {
  let tokens = tokenize("x: -3.14")
  assert_eq(tokens.length(), 3)
  match tokens[2].0 {
    Token::NUMBER(n) => assert_eq(n == -3.14, true)
    _ => {
      println("expected NUMBER")
      assert_eq(1, 2)
    }
  }
}

///|
test "tokenize: array" {
  let tokens = tokenize("x: [1, 2]")
  assert_eq(tokens.length(), 7)
  // [1, 2] -> LBRACKET, NUMBER(1), COMMA, NUMBER(2), RBRACKET
  match tokens[2].0 {
    Token::LBRACKET => ()
    _ => {
      println("expected LBRACKET")
      assert_eq(1, 2)
    }
  }
  match tokens[3].0 {
    Token::NUMBER(n) => assert_eq(n == 1.0, true)
    _ => {
      println("expected NUMBER")
      assert_eq(1, 2)
    }
  }
}

///|
test "tokenize: record" {
  let tokens = tokenize("x: {a: 1}")
  assert_eq(tokens.length(), 7)
  match tokens[2].0 {
    Token::LBRACE => ()
    _ => {
      println("expected LBRACE")
      assert_eq(1, 2)
    }
  }
}

///|
test "tokenize: nested funcall" {
  let tokens = tokenize("f(a: 1)")
  assert_eq(tokens.length(), 6)
  // f, LPAREN, a, COLON, 1, RPAREN
  match tokens[0].0 {
    Token::IDENT("f") => ()
    _ => {
      println("expected IDENT f")
      assert_eq(1, 2)
    }
  }
}

///|
test "tokenize: full example" {
  let tokens = tokenize("name(x: 1, y: \"hi\", z: [true])")
  // name ( x : 1 , y : "hi" , z : [ true ] )
  assert_eq(tokens.length(), 16)
}

///|
test "tokenize: keyword true false not confused" {
  let tokens = tokenize("x: true, y: false")
  // true and false are BOOL tokens, not IDENT
  match tokens[2].0 {
    Token::BOOL(true) => ()
    _ => {
      println("expected BOOL true")
      assert_eq(1, 2)
    }
  }
  match tokens[6].0 {
    Token::BOOL(false) => ()
    _ => {
      println("expected BOOL false")
      assert_eq(1, 2)
    }
  }
}

///|
test "is_name_char: basic" {
  assert_eq(is_name_char('a'), true)
  assert_eq(is_name_char('z'), true)
  assert_eq(is_name_char('A'), true)
  assert_eq(is_name_char('Z'), true)
  assert_eq(is_name_char('0'), true)
  assert_eq(is_name_char('9'), true)
  assert_eq(is_name_char('_'), true)
  assert_eq(is_name_char('-'), true)
  assert_eq(is_name_char(' '), false)
  assert_eq(is_name_char('('), false)
}

///|
test "lex_string: basic" {
  let result = lex_string("\"hello\"", 0)
  assert_eq(result is Some(_), true)
  let (s, next) = result.unwrap()
  assert_eq(s, "hello")
  assert_eq(next, 7)
}

///|
test "lex_string: escaped quote" {
  let result = lex_string("\"he\\\"llo\"", 0)
  assert_eq(result is Some(_), true)
  let (s, _) = result.unwrap()
  assert_eq(s, "he\\\"llo")
}

///|
test "lex_string: unterminated" {
  let result = lex_string("\"hello", 0)
  assert_eq(result is None, true)
}

///|
test "lex_number: integer" {
  let result = lex_number("42", 0)
  assert_eq(result is Some(_), true)
  let (n, next) = result.unwrap()
  assert_eq(n == 42.0, true)
  assert_eq(next, 2)
}

///|
test "lex_number: decimal" {
  let result = lex_number("3.14", 0)
  assert_eq(result is Some(_), true)
  let (n, next) = result.unwrap()
  assert_eq(n == 3.14, true)
  assert_eq(next, 4)
}

///|
test "lex_number: negative" {
  let result = lex_number("-5", 0)
  assert_eq(result is Some(_), true)
  let (n, _) = result.unwrap()
  assert_eq(n == -5.0, true)
}

///|
test "lex_number: sign only returns value zero" {
  let result = lex_number("-", 0)
  // The lexer accepts lone '-' as a valid number (sign with zero value)
  assert_eq(result is Some(_), true)
  let (n, _) = result.unwrap()
  assert_eq(n == 0.0, true)
}

///|
test "skip_spaces: basic" {
  let result = skip_spaces("  abc", 0)
  assert_eq(result, 2)
}

///|
test "skip_spaces: none" {
  let result = skip_spaces("abc", 0)
  assert_eq(result, 0)
}
