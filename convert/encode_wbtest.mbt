///|
test "encode_directives: basic" {
  assert_eq(encode_directives("hi @name(x:1)"), "hi <!--mm name(x:1)-->")
}

///|
test "encode_directives: empty" {
  assert_eq(encode_directives(""), "")
}

///|
test "encode_directives: no at sign" {
  assert_eq(encode_directives("hello world"), "hello world")
}

///|
test "encode_directives: at without parens" {
  assert_eq(encode_directives("@name"), "@name")
}

///|
test "encode_directives: multiple directives" {
  assert_eq(
    encode_directives("@a(x:1) and @b(y:2)"),
    "<!--mm a(x:1)--> and <!--mm b(y:2)-->",
  )
}

///|
test "encode_directives: nested funcall" {
  // @f(a: @g(b: 1)) — the inner @g is inside parens and treated as part of the outer directive
  let result = encode_directives("@f(a: @g(b: 1))")
  assert_eq(result, "<!--mm f(a: @g(b: 1))-->")
}

///|
test "collapse_newlines: basic" {
  let sv = "line1\nline2\rline3".to_string_view()
  assert_eq(collapse_newlines(sv), "line1 line2 line3")
}

///|
test "is_name_start: basic" {
  assert_eq(is_name_start('a'), true)
  assert_eq(is_name_start('z'), true)
  assert_eq(is_name_start('A'), true)
  assert_eq(is_name_start('Z'), true)
  assert_eq(is_name_start('0'), false)
  assert_eq(is_name_start('-'), false)
  assert_eq(is_name_start(' '), false)
}

///|
test "encode_directives: skip single backtick code span" {
  assert_eq(encode_directives("use `@name(x: 1)` here"), "use `@name(x: 1)` here")
}

///|
test "encode_directives: skip double backtick code span" {
  assert_eq(encode_directives("use ``@name(x: 1)`` here"), "use ``@name(x: 1)`` here")
}

///|
test "encode_directives: directive before and after code span" {
  assert_eq(
    encode_directives("@a(x:1) text `@b(y:2)` text @c(z:3)"),
    "<!--mm a(x:1)--> text `@b(y:2)` text <!--mm c(z:3)-->",
  )
}

///|
test "encode_directives: unmatched backtick treated as code span" {
  assert_eq(encode_directives("`@a(x:1)"), "`@a(x:1)")
}
