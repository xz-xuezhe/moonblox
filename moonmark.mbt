// MoonMark public API — called from user projects

///|
/// Build a static site from markdown files.
/// `config_path` points to a JSON config file (default: `moonmark.json`).
/// Component maps allow users to register their own render functions.
pub fn build(
  config_path? : String = "moonmark.json",
  inline_components? : Map[String, (Map[String, @ast.Value]) -> String] = Map([]),
  container_components? : Map[
    String,
    (Map[String, @ast.Value], String) -> String,
  ] = Map([]),
) -> Unit raise {
  let config_text = @fs.read_file_to_string(config_path)
  let input_dir = read_json_field(config_text, "input", "posts")
  let output_dir = read_json_field(config_text, "output", "dist")
  let theme_dir = read_json_field(config_text, "theme", "theme")
  // Auto-scan components directory
  let comp_dir = read_json_field(config_text, "components", "components")
  let discovered = @convert.scan_components(comp_dir)
  for k in discovered.keys() {
    let info = discovered[k]
    let kind = if info.is_container { "container" } else { "inline" }
    println("Found component: \{k} (\{kind})")
  }
  @fs.create_dir("\{output_dir}/components")
  let scripts = component_scripts(output_dir)
  let posts = @fs.read_dir(input_dir)
  for i = 0; i < posts.length(); i = i + 1 {
    let name = posts[i]
    if name.has_suffix(".md") {
      let input_path = "\{input_dir}/\{name}"
      let content = @fs.read_file_to_string(input_path)
      let doc = @convert.parse_markdown(content)
      let title = name.trim_end(chars=".md").to_owned()
      let html = @render.render_document(
        doc,
        title~,
        theme_dir~,
        scripts~,
        inline_components~,
        container_components~,
      )
      let output_name = name.trim_end(chars=".md").to_owned() + ".html"
      @fs.write_string_to_file("\{output_dir}/\{output_name}", html)
      println("Built: \{output_dir}/\{output_name}")
    }
  }
}

// Simple JSON string field extraction without full parser dependency

///|
fn read_json_field(json : String, key : String, default : String) -> String {
  let search = "\"\{key}\""
  match json.find_string(search) {
    Some(i) => {
      let after_key = json[i + search.length():].to_owned()
      let colon = after_key.find_char(':')
      match colon {
        Some(c) => {
          let after_colon = after_key[c + 1:].trim().to_owned()
          if after_colon.has_prefix("\"") {
            let content = after_colon[1:].to_owned()
            let quote = content.find_char('"')
            match quote {
              Some(q) => content[0:q].to_owned()
              None => default
            }
          } else {
            default
          }
        }
        None => default
      }
    }
    None => default
  }
}

///|
fn String::find_char(self : String, ch : Char) -> Int? {
  let len = self.length()
  for i = 0; i < len; i = i + 1 {
    match self.get_char(i) {
      Some(c) if c == ch => return Some(i)
      _ => ()
    }
  }
  None
}

///|
fn String::find_string(self : String, needle : String) -> Int? {
  let len = self.length()
  let nlen = needle.length()
  for i = 0; i + nlen <= len; i = i + 1 {
    if self[i:i + nlen] == needle {
      return Some(i)
    }
  }
  None
}

///|
fn component_scripts(_output_dir : String) -> String {
  "<script type=\"module\" src=\"components/components.js\"></script>"
}
