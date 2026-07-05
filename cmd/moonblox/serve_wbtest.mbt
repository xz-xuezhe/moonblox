///|
test "is_safe_request_path: allows absolute site paths" {
  assert_eq(is_safe_request_path("/index.html"), true)
  assert_eq(is_safe_request_path("/posts/hello/index.html"), true)
  assert_eq(is_safe_request_path("/style.css"), true)
}

///|
test "is_safe_request_path: rejects traversal and non-absolute paths" {
  assert_eq(is_safe_request_path("../secret"), false)
  assert_eq(is_safe_request_path("/../secret"), false)
  assert_eq(is_safe_request_path("/posts/../../secret"), false)
  assert_eq(is_safe_request_path("index.html"), false)
  assert_eq(is_safe_request_path("/posts\\secret"), false)
}
