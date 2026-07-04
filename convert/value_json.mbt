// Serialize MoonBlox Value to JSON string

///|
/// Convert a Value tree to a JSON string
pub fn value_to_json(v : @ast.Value) -> String {
  match v {
    @ast.Value::Str(s) => {
      let sb = StringBuilder::new()
      sb.write_char('"')
      sb.write_string(escape_json(s))
      sb.write_char('"')
      sb.to_string()
    }
    @ast.Value::Number(n) => n.to_string()
    @ast.Value::Bool(true) => "true"
    @ast.Value::Bool(false) => "false"
    @ast.Value::Array(arr) => {
      let sb = StringBuilder::new()
      sb.write_char('[')
      for i = 0; i < arr.length(); i = i + 1 {
        if i > 0 {
          sb.write_char(',')
        }
        sb.write_string(value_to_json(arr[i]))
      }
      sb.write_char(']')
      sb.to_string()
    }
    @ast.Value::Record(map) => {
      let sb = StringBuilder::new()
      sb.write_char('{')
      let keys = map.keys().to_array()
      for i = 0; i < keys.length(); i = i + 1 {
        if i > 0 {
          sb.write_char(',')
        }
        let k = keys[i]
        sb.write_char('"')
        sb.write_string(k)
        sb.write_string("\":")
        sb.write_string(value_to_json(map[k]))
      }
      sb.write_char('}')
      sb.to_string()
    }
    @ast.Value::Funcall(name, args) => {
      let sb = StringBuilder::new()
      sb.write_char('{')
      sb.write_char('"')
      sb.write_string(name)
      sb.write_string("\":")
      sb.write_string(value_to_json(@ast.Value::Record(args)))
      sb.write_char('}')
      sb.to_string()
    }
    @ast.Value::Var(s) => {
      let sb = StringBuilder::new()
      sb.write_char('"')
      sb.write_string(escape_json(s))
      sb.write_char('"')
      sb.to_string()
    }
  }
}

///|
fn escape_json(s : String) -> String {
  let sb = StringBuilder::new()
  let len = s.length()
  for i = 0; i < len; i = i + 1 {
    match s.get_char(i) {
      Some('"') => sb.write_string("\\\"")
      Some('\\') => sb.write_string("\\\\")
      Some('\n') => sb.write_string("\\n")
      Some('\t') => sb.write_string("\\t")
      Some(c) => sb.write_char(c)
      None => ()
    }
  }
  sb.to_string()
}
