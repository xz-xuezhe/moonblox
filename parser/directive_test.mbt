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
