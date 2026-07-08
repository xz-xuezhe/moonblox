///|
test "parse_inline_directive: just name" {
  let result = parse_inline_directive("name")
  assert_eq(result is None, true)
}

///|
test "parse_inline_directive: name with empty parens" {
  let result = parse_inline_directive("name()")
  assert_eq(result is Some(_), true)
  let (name, args) = result.unwrap()
  assert_eq(name, "name")
  assert_eq(args.length(), 0)
}

///|
test "parse_inline_directive: single arg" {
  let result = parse_inline_directive("name(x: 1)")
  assert_eq(result is Some(_), true)
  let (name, args) = result.unwrap()
  assert_eq(name, "name")
  assert_eq(args.length(), 1)
  match args["x"] {
    @ast.Value::Number(n) => assert_eq(n == 1.0, true)
    _ => assert_eq("expected Number", "")
  }
}

///|
test "parse_inline_directive: string arg" {
  let result = parse_inline_directive("name(x: \"hello\")")
  assert_eq(result is Some(_), true)
  let (_, args) = result.unwrap()
  match args["x"] {
    @ast.Value::Str(s) => assert_eq(s, "hello")
    _ => assert_eq("expected Str", "")
  }
}

///|
test "parse_inline_directive: bool args" {
  let result = parse_inline_directive("name(x: true, y: false)")
  assert_eq(result is Some(_), true)
  let (_, args) = result.unwrap()
  match args["x"] {
    @ast.Value::Bool(true) => ()
    _ => assert_eq("expected Bool true", "")
  }
  match args["y"] {
    @ast.Value::Bool(false) => ()
    _ => assert_eq("expected Bool false", "")
  }
}

///|
test "parse_inline_directive: array" {
  let result = parse_inline_directive("name(x: [1, 2])")
  assert_eq(result is Some(_), true)
  let (_, args) = result.unwrap()
  match args["x"] {
    @ast.Value::Array(arr) => assert_eq(arr.length(), 2)
    _ => assert_eq("expected Array", "")
  }
}

///|
test "parse_inline_directive: record" {
  let result = parse_inline_directive("name(x: {a: 1})")
  assert_eq(result is Some(_), true)
  let (_, args) = result.unwrap()
  match args["x"] {
    @ast.Value::Record(rec) => assert_eq(rec.length(), 1)
    _ => assert_eq("expected Record", "")
  }
}

///|
test "parse_inline_directive: funcall" {
  let result = parse_inline_directive("name(f(a: 1))")
  assert_eq(result is Some(_), true)
  let (_, args) = result.unwrap()
  // funcall without key becomes positional arg with key "_"
  match args["_"] {
    @ast.Value::Funcall(fn_name, _) => assert_eq(fn_name, "f")
    _ => assert_eq("expected Funcall", "")
  }
}

///|
test "parse_inline_directive: unterminated" {
  let result = parse_inline_directive("name(")
  assert_eq(result is None, true)
}

///|
test "parse_container_header: basic" {
  let result = parse_container_header(":::name(x: 1)")
  assert_eq(result is Some(_), true)
  let (name, args) = result.unwrap()
  assert_eq(name, "name")
  assert_eq(args.length(), 1)
}

///|
test "parse_container_header: short colon" {
  let result = parse_container_header("::")
  assert_eq(result is None, true)
}

///|
test "parse_container_header: not a container" {
  let result = parse_container_header(":not")
  assert_eq(result is None, true)
}

///|
test "parse_inline_directive - var reference" {
  let result = parse_inline_directive("name(x: foo)")
  assert_eq(result is Some(_), true)
  let (name, args) = result.unwrap()
  assert_eq(name, "name")
  assert_eq(args.length(), 1)
  match args["x"] {
    @ast.Value::Var(name) => assert_eq(name, "foo")
    _ => {
      println("expected Var(foo)")
      assert_eq(1, 2)
    }
  }
}

///|
test "parse_inline_directive - array of records" {
  let result = parse_inline_directive("name(x: [{a: 1}, {b: 2}])")
  assert_eq(result is Some(_), true)
  let (name, args) = result.unwrap()
  assert_eq(name, "name")
  match args["x"] {
    @ast.Value::Array(arr) => {
      assert_eq(arr.length(), 2)
      match arr[0] {
        @ast.Value::Record(r1) => {
          assert_eq(r1.length(), 1)
          match r1["a"] {
            @ast.Value::Number(n) => assert_eq(n == 1.0, true)
            _ => {
              println("expected Number(1)")
              assert_eq(1, 2)
            }
          }
        }
        _ => {
          println("expected Record")
          assert_eq(1, 2)
        }
      }
      match arr[1] {
        @ast.Value::Record(r2) => {
          assert_eq(r2.length(), 1)
          match r2["b"] {
            @ast.Value::Number(n) => assert_eq(n == 2.0, true)
            _ => {
              println("expected Number(2)")
              assert_eq(1, 2)
            }
          }
        }
        _ => {
          println("expected Record")
          assert_eq(1, 2)
        }
      }
    }
    _ => {
      println("expected Array")
      assert_eq(1, 2)
    }
  }
}

///|
test "parse_inline_directive - funcall in record" {
  let result = parse_inline_directive("name(x: {a: f(b: 1)})")
  assert_eq(result is Some(_), true)
  let (_, args) = result.unwrap()
  match args["x"] {
    @ast.Value::Record(rec) => {
      assert_eq(rec.length(), 1)
      match rec["a"] {
        @ast.Value::Funcall(fname, fargs) => {
          assert_eq(fname, "f")
          assert_eq(fargs.length(), 1)
          match fargs["b"] {
            @ast.Value::Number(n) => assert_eq(n == 1.0, true)
            _ => {
              println("expected Number")
              assert_eq(1, 2)
            }
          }
        }
        _ => {
          println("expected Funcall")
          assert_eq(1, 2)
        }
      }
    }
    _ => {
      println("expected Record")
      assert_eq(1, 2)
    }
  }
}

///|
test "parse_inline_directive - nested array in record" {
  let result = parse_inline_directive("name(a: {b: [1, 2, 3]})")
  assert_eq(result is Some(_), true)
  let (_, args) = result.unwrap()
  match args["a"] {
    @ast.Value::Record(rec) =>
      match rec["b"] {
        @ast.Value::Array(arr) => assert_eq(arr.length(), 3)
        _ => {
          println("expected Array")
          assert_eq(1, 2)
        }
      }
    _ => {
      println("expected Record")
      assert_eq(1, 2)
    }
  }
}

///|
test "parse_inline_directive - trailing comma in args" {
  let result = parse_inline_directive("name(a, b,)")
  assert_eq(result is Some(_), true)
  let (name, args) = result.unwrap()
  assert_eq(name, "name")
  // Should have 2 positional args (both stored with key "_")
  match args["_"] {
    @ast.Value::Var(v) => assert_eq(v == "a" || v == "b", true)
    _ => ()
  }
}

///|
test "parse_inline_directive - missing value after colon" {
  let result = parse_inline_directive("name(x: )")
  assert_eq(result is None, true)
}

///|
test "parse_inline_directive - unclosed bracket" {
  let result = parse_inline_directive("name(x: [1, 2)")
  assert_eq(result is None, true)
}

///|
test "parse_inline_directive - colon without key" {
  let result = parse_inline_directive("name(: a)")
  assert_eq(result is None, true)
}

///|
test "parse_inline_directive - consecutive commas" {
  // Parser accepts consecutive commas; empty slot is skipped
  let result = parse_inline_directive("name(a, , b)")
  assert_eq(result is Some(_), true)
  let (name, args) = result.unwrap()
  assert_eq(name, "name")
  // Second positional arg (key "_") overwrites the first
  match args["_"] {
    @ast.Value::Var(v) => assert_eq(v, "b")
    _ => {
      println("expected Var")
      assert_eq(1, 2)
    }
  }
}

///|
test "parse_inline_directive - empty input" {
  let result = parse_inline_directive("")
  assert_eq(result is None, true)
}

///|
test "parse_structured_header - basic" {
  let result = parse_structured_header("::name { k: 1 }")
  assert_eq(result is Some(_), true)
  let (name, args) = result.unwrap()
  assert_eq(name, "name")
  assert_eq(args.length(), 1)
  match args["k"] {
    @ast.Value::Number(n) => assert_eq(n == 1.0, true)
    _ => {
      println("expected Number(1)")
      assert_eq(1, 2)
    }
  }
}

///|
test "parse_structured_header - empty record" {
  let result = parse_structured_header("::name {}")
  assert_eq(result is Some(_), true)
  let (name, args) = result.unwrap()
  assert_eq(name, "name")
  assert_eq(args.length(), 0)
}

///|
test "parse_structured_header - no brace" {
  let result = parse_structured_header("::name")
  assert_eq(result is None, true)
}

///|
test "parse_structured_header - multiple fields" {
  let result = parse_structured_header(
    "::chart { type: \"line\", data: [1, 2] }",
  )
  assert_eq(result is Some(_), true)
  let (name, args) = result.unwrap()
  assert_eq(name, "chart")
  assert_eq(args.length(), 2)
  match args["type"] {
    @ast.Value::Str(s) => assert_eq(s, "line")
    _ => {
      println("expected Str(line)")
      assert_eq(1, 2)
    }
  }
  match args["data"] {
    @ast.Value::Array(arr) => assert_eq(arr.length(), 2)
    _ => {
      println("expected Array")
      assert_eq(1, 2)
    }
  }
}

///|
test "parse_structured_header - with leading/trailing spaces" {
  let result = parse_structured_header("  ::name { k: 1 }  ")
  assert_eq(result is Some(_), true)
  let (name, args) = result.unwrap()
  assert_eq(name, "name")
  assert_eq(args.length(), 1)
}

///|
test "parse_structured_header - short colon prefix" {
  let result = parse_structured_header(":name")
  assert_eq(result is None, true)
}

///|
test "parse_structured_header - too short input" {
  let result = parse_structured_header("::")
  assert_eq(result is None, true)
}

///|
test "directive - missing parens" {
  let tokens : Array[(Token, Int, Int)] = [(Token::IDENT("name"), 0, 4)]
  let _ = directive(tokens) catch {
    _ =>
      // Expected parse error
      return
  }
  // Should have raised ParseError, not reached here
  println("expected ParseError for missing parens")
  assert_eq(1, 2)
}

///|
test "directive - unclosed paren" {
  let tokens : Array[(Token, Int, Int)] = [
    (Token::IDENT("name"), 0, 4),
    (Token::LPAREN, 4, 5),
  ]
  let _ = directive(tokens) catch { _ => return }
  println("expected ParseError for unclosed paren")
  assert_eq(1, 2)
}

///|
test "directive - unexpected token in args" {
  let tokens : Array[(Token, Int, Int)] = [
    (Token::IDENT("name"), 0, 4),
    (Token::LPAREN, 4, 5),
    (Token::LPAREN, 5, 6),
    (Token::RPAREN, 6, 7),
  ]
  let _ = directive(tokens) catch { _ => return }
  println("expected ParseError for unexpected token")
  assert_eq(1, 2)
}

///|
test "directive - with initial_pos parameter" {
  let tokens : Array[(Token, Int, Int)] = [
    (Token::IDENT("test"), 0, 4),
    (Token::LPAREN, 4, 5),
    (Token::RPAREN, 5, 6),
  ]
  // Test that initial_pos is accepted (backward compat)
  let result1 = directive(tokens, initial_pos=0)
  let result2 = directive(tokens, initial_pos=42)
  assert_eq(result1.0, "test")
  assert_eq(result2.0, "test")
  assert_eq(result1.1.length(), 0)
  assert_eq(result2.1.length(), 0)
}
