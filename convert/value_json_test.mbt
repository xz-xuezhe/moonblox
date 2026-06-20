///|
test "value_to_json: Str" {
  assert_eq(value_to_json(@ast.Value::Str("hello")), "\"hello\"")
}

///|
test "value_to_json: Number" {
  assert_eq(value_to_json(@ast.Value::Number(3.14)), "3.14")
}

///|
test "value_to_json: Bool true" {
  assert_eq(value_to_json(@ast.Value::Bool(true)), "true")
}

///|
test "value_to_json: Bool false" {
  assert_eq(value_to_json(@ast.Value::Bool(false)), "false")
}

///|
test "value_to_json: empty Array" {
  assert_eq(value_to_json(@ast.Value::Array([])), "[]")
}

///|
test "value_to_json: Array of mixed values" {
  assert_eq(
    value_to_json(
      @ast.Value::Array([@ast.Value::Str("a"), @ast.Value::Number(1.0)]),
    ),
    "[\"a\",1]",
  )
}

///|
test "value_to_json: empty Record" {
  let m : Map[String, @ast.Value] = Map([])
  assert_eq(value_to_json(@ast.Value::Record(m)), "{}")
}

///|
test "value_to_json: Record with entries" {
  let m : Map[String, @ast.Value] = Map([])
  m.set("key", @ast.Value::Str("val"))
  assert_eq(value_to_json(@ast.Value::Record(m)), "{\"key\":\"val\"}")
}

///|
test "value_to_json: Funcall" {
  let m : Map[String, @ast.Value] = Map([])
  assert_eq(value_to_json(@ast.Value::Funcall("fn", m)), "{\"fn\":{}}")
}

///|
test "value_to_json: nested" {
  let inner : Map[String, @ast.Value] = Map([])
  inner.set(
    "arr",
    @ast.Value::Array([@ast.Value::Number(1.0), @ast.Value::Number(2.0)]),
  )
  assert_eq(value_to_json(@ast.Value::Record(inner)), "{\"arr\":[1,2]}")
}

///|
test "value_to_json: escape special chars" {
  assert_eq(value_to_json(@ast.Value::Str("he\"llo")), "\"he\\\"llo\"")
}

///|
test "value_to_json: newline and tab in string" {
  assert_eq(value_to_json(@ast.Value::Str("a\nb\tc")), "\"a\\nb\\tc\"")
}
