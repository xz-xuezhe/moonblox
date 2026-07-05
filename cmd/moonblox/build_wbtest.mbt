// Unit tests for structured block parser and code generator functions
// in build.mbt. Whitebox tests (*_wbtest.mbt) can access private functions.

///|
test "is_name_char: letters" {
  assert_eq(is_name_char('a'), true)
  assert_eq(is_name_char('Z'), true)
  assert_eq(is_name_char('0'), true)
  assert_eq(is_name_char('_'), true)
  assert_eq(is_name_char('-'), true)
  assert_eq(is_name_char('!'), false)
  assert_eq(is_name_char(' '), false)
  assert_eq(is_name_char('@'), false)
}

///|
test "is_name_char: edge cases" {
  assert_eq(is_name_char('.'), false)
  assert_eq(is_name_char('/'), false)
  assert_eq(is_name_char(':'), false)
  assert_eq(is_name_char('('), false)
  assert_eq(is_name_char(')'), false)
}

///|
test "has_removed_cache_entry: detects missing old key" {
  let old_entries : Map[String, Int] = Map([
    ("posts/a.md", 1),
    ("posts/b.md", 2),
  ])
  let current_entries : Map[String, Int] = Map([("posts/a.md", 1)])
  assert_eq(has_removed_cache_entry(old_entries, current_entries), true)
}

///|
test "has_removed_cache_entry: ignores changed and added keys" {
  let old_entries : Map[String, Int] = Map([("posts/a.md", 1)])
  let current_entries : Map[String, Int] = Map([
    ("posts/a.md", 2),
    ("posts/c.md", 3),
  ])
  assert_eq(has_removed_cache_entry(old_entries, current_entries), false)
}

///|
test "is_numeric: basic" {
  assert_eq(is_numeric("123"), true)
  assert_eq(is_numeric("3.14"), true)
  assert_eq(is_numeric("0"), true)
  assert_eq(is_numeric("abc"), false)
  assert_eq(is_numeric(""), false)
  assert_eq(is_numeric("-5"), true)
}

///|
test "is_numeric: invalid" {
  assert_eq(is_numeric("12a"), false)
  assert_eq(is_numeric("."), false)
  assert_eq(is_numeric(" 1"), false)
  assert_eq(is_numeric("true"), false)
  assert_eq(is_numeric("--1"), false)
}

///|
test "is_numeric: decimal variants" {
  assert_eq(is_numeric(".5"), true)
  assert_eq(is_numeric("3."), true)
  assert_eq(is_numeric("-0.5"), true)
}

///|
test "find_matching_brace_in_text: simple" {
  let text = "{ hello }"
  let result = find_matching_brace_in_text(text, 0)
  match result {
    Some(pos) => assert_eq(pos, 8)
    None => assert_eq(true, false)
  }
}

///|
test "find_matching_brace_in_text: nested" {
  let text = "{ outer { inner } }"
  let result = find_matching_brace_in_text(text, 0)
  match result {
    Some(pos) => assert_eq(pos, 18)
    None => assert_eq(true, false)
  }
}

///|
test "find_matching_brace_in_text: no match" {
  let text = "{ unclosed"
  let result = find_matching_brace_in_text(text, 0)
  match result {
    None => assert_eq(true, true)
    Some(_) => assert_eq(true, false)
  }
}

///|
test "find_matching_brace_in_text: not a brace" {
  let text = "hello world"
  let result = find_matching_brace_in_text(text, 0)
  match result {
    None => assert_eq(true, true)
    Some(_) => assert_eq(true, false)
  }
}

///|
test "find_matching_brace_in_text: empty" {
  let text = ""
  let result = find_matching_brace_in_text(text, 0)
  match result {
    None => assert_eq(true, true)
    Some(_) => assert_eq(true, false)
  }
}

///|
test "find_matching_brace_in_text: string with braces" {
  // Braces inside quotes should be skipped
  let text = "{ \"{\" }"
  let result = find_matching_brace_in_text(text, 0)
  match result {
    Some(pos) => assert_eq(pos, 6)
    None => assert_eq(true, false)
  }
}

///|
test "find_matching_brace_in_text: escaped quote" {
  let text = "{ \"\\\"\" }"
  let result = find_matching_brace_in_text(text, 0)
  match result {
    Some(pos) => assert_eq(pos, 7)
    None => assert_eq(true, false)
  }
}

///|
test "is_close_marker_on_own_line: yes with newline before" {
  let md = "content\n::\nmore"
  // Position of first colon at line 2
  let pos = 8
  assert_eq(is_close_marker_on_own_line(md, pos), true)
}

///|
test "is_close_marker_on_own_line: yes at start of text" {
  let md = "::\ncontent"
  assert_eq(is_close_marker_on_own_line(md, 0), true)
}

///|
test "is_close_marker_on_own_line: yes at end of text" {
  let md = "content\n::"
  let pos = 8
  assert_eq(is_close_marker_on_own_line(md, pos), true)
}

///|
test "is_close_marker_on_own_line: yes with trailing whitespace" {
  let md = "content\n::  \nmore"
  let pos = 8
  assert_eq(is_close_marker_on_own_line(md, pos), true)
}

///|
test "is_close_marker_on_own_line: yes with leading spaces" {
  let md = "content\n  ::\nmore"
  let pos = 10
  assert_eq(is_close_marker_on_own_line(md, pos), true)
}

///|
test "is_close_marker_on_own_line: no (inline)" {
  let md = "text :: more"
  let pos = 5
  assert_eq(is_close_marker_on_own_line(md, pos), false)
}

///|
test "is_close_marker_on_own_line: no (text after)" {
  let md = "content\n:: trailing"
  let pos = 8
  assert_eq(is_close_marker_on_own_line(md, pos), false)
}

///|
test "is_close_marker_on_own_line: no (text before)" {
  let md = "content::"
  let pos = 7
  assert_eq(is_close_marker_on_own_line(md, pos), false)
}

///|
test "infer_type_and_value: number" {
  let (typ, val) = infer_type_and_value("42")
  assert_eq(typ, "Double")
  assert_eq(val, "42.0")
}

///|
test "infer_type_and_value: decimal" {
  let (typ, val) = infer_type_and_value("3.14")
  assert_eq(typ, "Double")
  assert_eq(val, "3.14")
}

///|
test "infer_type_and_value: negative number" {
  let (typ, val) = infer_type_and_value("-7")
  assert_eq(typ, "Double")
  assert_eq(val, "-7.0")
}

///|
test "infer_type_and_value: quoted string" {
  let (typ, val) = infer_type_and_value("\"hello\"")
  assert_eq(typ, "String")
  assert_eq(val, "\"hello\"")
}

///|
test "infer_type_and_value: string with escaped chars" {
  let (typ, _val) = infer_type_and_value("\"a\\\"b\"")
  assert_eq(typ, "String")
}

///|
test "infer_type_and_value: boolean true" {
  let (typ, val) = infer_type_and_value("true")
  assert_eq(typ, "Bool")
  assert_eq(val, "true")
}

///|
test "infer_type_and_value: boolean false" {
  let (typ, val) = infer_type_and_value("false")
  assert_eq(typ, "Bool")
  assert_eq(val, "false")
}

///|
test "infer_type_and_value: empty string" {
  let (typ, val) = infer_type_and_value("")
  assert_eq(typ, "String")
  assert_eq(val, "\"\"")
}

///|
test "infer_type_and_value: bare ident as string" {
  let (typ, val) = infer_type_and_value("someVar")
  assert_eq(typ, "String")
  assert_eq(val, "\"someVar\"")
}

///|
test "infer_type_and_value: number with leading/trailing spaces" {
  let (typ, val) = infer_type_and_value("  99  ")
  assert_eq(typ, "Double")
  assert_eq(val, "99.0")
}

///|
test "parse_model_to_vars: basic" {
  let vars = parse_model_to_vars("count = 0, name = \"guest\"")
  assert_eq(vars.length(), 2)
  let (n0, t0, v0) = vars[0]
  assert_eq(n0, "count")
  assert_eq(t0, "Double")
  assert_eq(v0, "0.0")
  let (n1, t1, v1) = vars[1]
  assert_eq(n1, "name")
  assert_eq(t1, "String")
  assert_eq(v1, "\"guest\"")
}

///|
test "parse_model_to_vars: empty" {
  let vars = parse_model_to_vars("")
  assert_eq(vars.length(), 0)
}

///|
test "parse_model_to_vars: with spaces" {
  let vars = parse_model_to_vars("  x  =  10  ,  y  =  20  ")
  assert_eq(vars.length(), 2)
  let (nx, tx, vx) = vars[0]
  assert_eq(nx, "x")
  assert_eq(tx, "Double")
  assert_eq(vx, "10.0")
  let (ny, ty, vy) = vars[1]
  assert_eq(ny, "y")
  assert_eq(ty, "Double")
  assert_eq(vy, "20.0")
}

///|
test "parse_model_to_vars: bool value" {
  let vars = parse_model_to_vars("active = true")
  assert_eq(vars.length(), 1)
  let (n, t, v) = vars[0]
  assert_eq(n, "active")
  assert_eq(t, "Bool")
  assert_eq(v, "true")
}

///|
test "parse_model_to_vars: no equals sign defaults to string" {
  let vars = parse_model_to_vars("msg")
  assert_eq(vars.length(), 1)
  let (n, t, v) = vars[0]
  assert_eq(n, "msg")
  assert_eq(t, "String")
  assert_eq(v, "\"\"")
}

///|
test "parse_model_to_vars: single var no comma" {
  let vars = parse_model_to_vars("count = 0")
  assert_eq(vars.length(), 1)
  let (n, t, v) = vars[0]
  assert_eq(n, "count")
  assert_eq(t, "Double")
  assert_eq(v, "0.0")
}

///|
test "parse_model_to_vars: string with comma inside" {
  let vars = parse_model_to_vars("title = \"hello, world\"")
  assert_eq(vars.length(), 1)
  let (n, t, v) = vars[0]
  assert_eq(n, "title")
  assert_eq(t, "String")
  assert_eq(v, "\"hello, world\"")
}

///|
test "generate_composite_cell: no vars no body" {
  let vars : Array[(String, String, String)] = []
  let callbacks : Map[String, Bool] = Map([])
  let result = generate_composite_cell("test", vars, "", callbacks)
  assert_eq(result.contains("static_cell"), true)
  assert_eq(result.contains("@html.div([])"), true)
  assert_eq(result.contains("pub fn test_cell"), true)
}

///|
test "generate_composite_cell: with single var" {
  let vars : Array[(String, String, String)] = [("count", "Double", "0.0")]
  let callbacks : Map[String, Bool] = Map([])
  let result = generate_composite_cell("counter", vars, "", callbacks)
  assert_eq(result.contains("simple_cell"), true)
  assert_eq(result.contains("CounterModel"), true)
  assert_eq(result.contains("count : Double"), true)
  assert_eq(result.contains("SetCount"), true)
  assert_eq(result.contains("CounterMsg"), true)
  assert_eq(result.contains("pub fn counter_cell"), true)
}

///|
test "generate_composite_cell: with body component refs" {
  let vars : Array[(String, String, String)] = []
  let callbacks : Map[String, Bool] = Map([])
  let body = "Hello @badge(text=\"new\", tone=\"info\")"
  let result = generate_composite_cell("test", vars, body, callbacks)
  assert_eq(result.contains("static_cell"), true)
  assert_eq(result.contains("@badge.badge("), true)
  assert_eq(result.contains("text=\"new\""), true)
  assert_eq(result.contains("tone=\"info\""), true)
}

///|
test "generate_composite_cell: with callback on referenced component" {
  let vars : Array[(String, String, String)] = [("count", "Double", "0.0")]
  let callbacks : Map[String, Bool] = Map([("slider", true)])
  let body = "Value: @slider(value=count)"
  let result = generate_composite_cell("panel", vars, body, callbacks)
  assert_eq(result.contains("simple_cell"), true)
  assert_eq(result.contains("model.count"), true)
  assert_eq(result.contains("on_change"), true)
  assert_eq(result.contains("SetCount"), true)
}

///|
test "generate_composite_cell: multiple vars" {
  let vars : Array[(String, String, String)] = [
    ("x", "Double", "0.0"),
    ("label", "String", "\"\""),
    ("active", "Bool", "true"),
  ]
  let callbacks : Map[String, Bool] = Map([])
  let result = generate_composite_cell("widget", vars, "", callbacks)
  assert_eq(result.contains("simple_cell"), true)
  assert_eq(result.contains("x : Double"), true)
  assert_eq(result.contains("label : String"), true)
  assert_eq(result.contains("active : Bool"), true)
  assert_eq(result.contains("SetX"), true)
  assert_eq(result.contains("SetLabel"), true)
  assert_eq(result.contains("SetActive"), true)
  assert_eq(result.contains("WidgetModel"), true)
}

///|
test "generate_composite_cell: static with body component refs no model var" {
  let vars : Array[(String, String, String)] = []
  let callbacks : Map[String, Bool] = Map([("slider", true)])
  let body = "@slider(value: 50)"
  let result = generate_composite_cell("panel", vars, body, callbacks)
  assert_eq(result.contains("static_cell"), true)
  // No model var used, so on_change should not be auto-wired
  assert_eq(result.contains("on_change"), false)
}

///|
test "capitalize: basic" {
  assert_eq(capitalize("hello"), "Hello")
  assert_eq(capitalize("world"), "World")
}

///|
test "capitalize: edge cases" {
  assert_eq(capitalize(""), "")
  assert_eq(capitalize("Hello"), "Hello")
  assert_eq(capitalize("123"), "123")
  assert_eq(capitalize("a"), "A")
}

///|
test "capitalize: single lowercase" {
  assert_eq(capitalize("a"), "A")
  assert_eq(capitalize("z"), "Z")
}

///|
test "get_set_msg_for_var: found" {
  let vars : Array[(String, String, String)] = [("count", "Double", "0.0")]
  let result = get_set_msg_for_var(vars, "count")
  match result {
    Some(msg) => assert_eq(msg, "SetCount")
    None => assert_eq(true, false)
  }
}

///|
test "get_set_msg_for_var: not found" {
  let vars : Array[(String, String, String)] = [("count", "Double", "0.0")]
  let result = get_set_msg_for_var(vars, "missing")
  match result {
    None => assert_eq(true, true)
    Some(_) => assert_eq(true, false)
  }
}

///|
test "get_set_msg_for_var: empty vars" {
  let vars : Array[(String, String, String)] = []
  let result = get_set_msg_for_var(vars, "anything")
  match result {
    None => assert_eq(true, true)
    Some(_) => assert_eq(true, false)
  }
}

///|
test "find_matching_paren: simple" {
  let text = "(hello)"
  let result = find_matching_paren(text, 0)
  match result {
    Some(pos) => assert_eq(pos, 6)
    None => assert_eq(true, false)
  }
}

///|
test "find_matching_paren: nested" {
  let text = "(a(b)c)"
  let result = find_matching_paren(text, 0)
  match result {
    Some(pos) => assert_eq(pos, 6)
    None => assert_eq(true, false)
  }
}

///|
test "find_matching_paren: no opening paren" {
  let text = "hello"
  let result = find_matching_paren(text, 0)
  match result {
    None => assert_eq(true, true)
    Some(_) => assert_eq(true, false)
  }
}

///|
test "find_matching_paren: no closing paren" {
  let text = "(hello"
  let result = find_matching_paren(text, 0)
  match result {
    None => assert_eq(true, true)
    Some(_) => assert_eq(true, false)
  }
}

///|
test "scan_for_colons: basic" {
  let text = "before :: after"
  let result = scan_for_colons(text, 0)
  match result {
    Some(pos) => assert_eq(pos, 7)
    None => assert_eq(true, false)
  }
}

///|
test "scan_for_colons: no match" {
  let text = "no colons here"
  let result = scan_for_colons(text, 0)
  match result {
    None => assert_eq(true, true)
    Some(_) => assert_eq(true, false)
  }
}

///|
test "scan_for_colons: from offset" {
  let text = ":: first :: second"
  let result = scan_for_colons(text, 3)
  match result {
    Some(pos) => assert_eq(pos, 9)
    None => assert_eq(true, false)
  }
}

///|
test "scan_for_colons: single colon only" {
  let text = "just : one"
  let result = scan_for_colons(text, 0)
  match result {
    None => assert_eq(true, true)
    Some(_) => assert_eq(true, false)
  }
}

///|
test "args_has_onchange: has it" {
  let args : Array[(String, String)] = [
    ("value", "42"),
    ("on_change", "fn(v) { ... }"),
  ]
  assert_eq(args_has_onchange(args), true)
}

///|
test "args_has_onchange: does not have it" {
  let args : Array[(String, String)] = [("value", "42"), ("tone", "info")]
  assert_eq(args_has_onchange(args), false)
}

///|
test "args_has_onchange: empty" {
  let args : Array[(String, String)] = []
  assert_eq(args_has_onchange(args), false)
}

///|
test "date_to_sortable: basic" {
  assert_eq(date_to_sortable("2024-01-15"), "20240115")
}

///|
test "date_to_sortable: with letters" {
  assert_eq(date_to_sortable("Jan 2024"), "2024")
}

///|
test "date_to_sortable: empty" {
  assert_eq(date_to_sortable(""), "")
}

///|
test "date_to_sortable: no digits" {
  assert_eq(date_to_sortable("abc"), "")
}

///|
test "parse_params: basic" {
  let params = parse_params("a : String, b : Double")
  assert_eq(params.length(), 2)
  assert_eq(params[0], "a : String")
  assert_eq(params[1], "b : Double")
}

///|
test "parse_params: with defaults" {
  let params = parse_params("a : String = \"hello\", b : Double = 0.0")
  assert_eq(params.length(), 2)
  assert_eq(params[0], "a : String = \"hello\"")
  assert_eq(params[1], "b : Double = 0.0")
}

///|
test "parse_params: with nested generics" {
  let params = parse_params("items : Array[String], cb : (Int) -> Unit")
  assert_eq(params.length(), 2)
  assert_eq(params[0], "items : Array[String]")
  assert_eq(params[1], "cb : (Int) -> Unit")
}

///|
test "parse_params: empty" {
  let params = parse_params("")
  assert_eq(params.length(), 0)
}

///|
test "parse_param_decl: with type and default" {
  let (name, typ, default) = parse_param_decl("name : String = \"world\"")
  assert_eq(name, "name")
  assert_eq(typ, "String")
  assert_eq(default, "\"world\"")
}

///|
test "parse_param_decl: with type only" {
  let (name, typ, default) = parse_param_decl("count : Double")
  assert_eq(name, "count")
  assert_eq(typ, "Double")
  assert_eq(default, "")
}

///|
test "parse_param_decl: with tilde label" {
  let (name, typ, default) = parse_param_decl("~name : String")
  assert_eq(name, "name")
  assert_eq(typ, "String")
  assert_eq(default, "")
}

///|
test "parse_param_decl: no type annotation" {
  let (name, typ, default) = parse_param_decl("msg")
  assert_eq(name, "msg")
  assert_eq(typ, "String")
  assert_eq(default, "")
}

///|
test "parse_param_decl: with default no type" {
  let (name, typ, default) = parse_param_decl("msg = \"hello\"")
  assert_eq(name, "msg")
  assert_eq(typ, "String")
  assert_eq(default, "\"hello\"")
}
