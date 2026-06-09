/// moonblox build — generate temp project in _moonblox/, compile, assemble dist/

async fn main {
  let args = @env.args()
  guard args.length() >= 3 else {
    println("Usage: moonblox build <project_dir>")
    return
  }
  let dir = args[2]
  guard @fs.path_exists(dir) else {
    println("Error: directory not found: \{dir}")
    return
  }

  let build_dir = "\{dir}/_moonblox"
  let engine_version = "0.1.0" // embedded at compile time

  // Clean and recreate _moonblox/
  try {
    if @fs.path_exists(build_dir) {
      remove_dir_all(build_dir)
    }
    try! @fs.create_dir(build_dir)
    try! @fs.create_dir("\{build_dir}/components")
    try! @fs.create_dir("\{build_dir}/theme")
  } catch {
    e => {
      println("Error: failed to create _moonblox/: \{e}")
      return
    }
  }

  // Generate moon.mod.json
  generate_moon_mod(build_dir, engine_version)

  // Copy user content first (moon.pkg needs components to exist)
  copy_components(dir, build_dir)
  copy_theme(dir, build_dir)

  // Generate moon.pkg with component imports
  generate_moon_pkg(build_dir)

  // Scan components, generate _registry.mbt
  scan_components("\{build_dir}/components", build_dir)

  // Generate main.mbt from markdown
  let posts_dir = "\{dir}/posts"
  try {
    if @fs.path_exists(posts_dir) {
      let files = @fs.read_dir(posts_dir)
      for i = 0; i < files.length(); i = i + 1 {
        let name = files[i]
        if name.has_suffix(".md") {
          let content = @fs.read_file_to_string("\{posts_dir}/\{name}")
          @fs.write_string_to_file("\{build_dir}/main.mbt", generate_main_mbt(content))
          println("Generated: main.mbt from \{name}")
        }
      }
    }
  } catch { _ => () }

  // Collect CSS: base.css + component .css files
  let css = collect_css(build_dir)

  // Run moon build
  println("Building JS...")
  let result = @process.run("moon", ["build", "--target", "js", "--release"], cwd=build_dir)
  guard result == 0 else {
    println("Error: moon build failed with exit code \{result}")
    return
  }

  // Assemble dist/
  let dist_dir = "\{dir}/dist"
  try {
    if !@fs.path_exists(dist_dir) { try! @fs.create_dir(dist_dir) }
  } catch { _ => () }

  // Copy JS artifact
  let js_dir = "\{build_dir}/_build/js/release/build"
  try {
    if @fs.path_exists(js_dir) {
      for f in @fs.read_dir(js_dir) {
        if f.has_suffix(".js") {
          @fs.write_string_to_file("\{dist_dir}/index.js", @fs.read_file_to_string("\{js_dir}/\{f}"))
          println("Copied: \{f} -> dist/index.js")
        }
      }
    }
  } catch { _ => println("Warning: JS copy failed") }

  // Write index.html
  let html =
    "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n  <meta charset=\"UTF-8\">\n  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n  <title>MoonBlox</title>\n  <link rel=\"stylesheet\" href=\"style.css\">\n</head>\n<body>\n  <div id=\"app\"></div>\n  <script src=\"index.js\" type=\"module\"></script>\n</body>\n</html>\n"
  try @fs.write_string_to_file("\{dist_dir}/index.html", html) catch { _ => () }

  if css != "" {
    try @fs.write_string_to_file("\{dist_dir}/style.css", css) catch { _ => () }
  }

  println("Built: \{dist_dir}/")
}

/// Remove a directory and all its contents recursively
fn remove_dir_all(dir : String) -> Unit raise {
  guard @fs.path_exists(dir) else { return }
  for f in @fs.read_dir(dir) {
    let path = "\{dir}/\{f}"
    if @fs.is_dir(path) {
      remove_dir_all(path)
    } else {
      try @fs.remove_file(path) catch { _ => () }
    }
  }
  try! @fs.remove_dir(dir)
}

/// Generate moon.mod.json
fn generate_moon_mod(build_dir : String, version : String) -> Unit raise {
  let engine_dep = match @env.get_env_var("MOONBLOX_PATH") {
    Some(path) => "\"xz-xuezhe/moonblox\": { \"path\": \"" + path + "\" }"
    None => "\"xz-xuezhe/moonblox\": \"" + version + "\""
  }
  let content = "{\n" +
    "  \"name\": \"moonblox-build\",\n" +
    "  \"preferred-target\": \"js\",\n" +
    "  \"deps\": {\n" +
    "    " + engine_dep + ",\n" +
    "    \"moonbit-community/rabbita\": \"0.12.4\",\n" +
    "    \"mizchi/markdown\": \"0.6.2\"\n" +
    "  }\n" +
    "}\n"
  @fs.write_string_to_file("\{build_dir}/moon.mod.json", content)
}

/// Generate moon.pkg with component package imports
fn generate_moon_pkg(build_dir : String) -> Unit raise {
  let comp_dir = "\{build_dir}/components"
  let parts : Array[String] = []
  parts.push("import {\n")
  parts.push("  \"xz-xuezhe/moonblox/ast\",\n")
  parts.push("  \"xz-xuezhe/moonblox/convert\",\n")
  parts.push("  \"xz-xuezhe/moonblox/render\",\n")
  parts.push("  \"moonbit-community/rabbita\",\n")

  // Import each component package
  if @fs.path_exists(comp_dir) {
    for name in @fs.read_dir(comp_dir) {
      if @fs.path_exists("\{comp_dir}/\{name}/moon.pkg") {
        parts.push("  \"moonblox-build/components/\{name}\",\n")
      }
    }
  }
  parts.push("}\n\n")
  parts.push("supported_targets = \"js\"\n")
  parts.push("options(\n  \"is-main\": true,\n)\n")
  @fs.write_string_to_file("\{build_dir}/moon.pkg", join_strings(parts, ""))
}

fn join_strings(ss : Array[String], sep : String) -> String {
  let sb = StringBuilder::new()
  for i = 0; i < ss.length(); i = i + 1 {
    sb.write_string(ss[i])
  }
  sb.to_string()
}

/// Copy user's components/ into _moonblox/components/
fn copy_components(src_root : String, build_dir : String) -> Unit raise {
  let src = "\{src_root}/components"
  guard @fs.path_exists(src) else { return }
  for name in @fs.read_dir(src) {
    let src_dir = "\{src}/\{name}"
    if @fs.is_dir(src_dir) {
      let dst_dir = "\{build_dir}/components/\{name}"
      try! @fs.create_dir(dst_dir)
      for f in @fs.read_dir(src_dir) {
        if f != "_build" && f != ".mooncakes" {
          let src_file = "\{src_dir}/\{f}"
          if !@fs.is_dir(src_file) {
            @fs.write_string_to_file("\{dst_dir}/\{f}", @fs.read_file_to_string(src_file))
          }
        }
      }
      println("Copied: components/\{name}/")
    }
  }
}

/// Copy user's theme/ into _moonblox/theme/
fn copy_theme(src_root : String, build_dir : String) -> Unit raise {
  let src = "\{src_root}/theme"
  guard @fs.path_exists(src) else { return }
  for f in @fs.read_dir(src) {
    let src_file = "\{src}/\{f}"
    if !@fs.is_dir(src_file) {
      @fs.write_string_to_file("\{build_dir}/theme/\{f}", @fs.read_file_to_string(src_file))
    }
  }
}

/// Scan components/*/ subdirectories and generate _registry.mbt
fn scan_components(dir : String, out_dir : String) -> Unit raise {
  guard @fs.path_exists(dir) else { return }
  let subdirs = @fs.read_dir(dir)
  let inline_s : Array[String] = []
  let container_s : Array[String] = []
  for i = 0; i < subdirs.length(); i = i + 1 {
    let comp_name = subdirs[i]
    let comp_dir = "\{dir}/\{comp_name}"
    if @fs.path_exists("\{comp_dir}/moon.pkg") {
      let mbt_path = "\{comp_dir}/\{comp_name}.mbt"
      if @fs.path_exists(mbt_path) {
        let content = @fs.read_file_to_string(mbt_path)
        let has_cell = content.contains("_cell(args") || content.contains("_cell(args:")
        if has_cell {
          if content.contains(", body:") || content.contains(", body :") {
            container_s.push(comp_name)
          } else {
            inline_s.push(comp_name)
          }
        }
      }
    }
  }
  inline_s.sort()
  container_s.sort()

  let sb = StringBuilder::new()
  sb.write_string(
    #|// Auto-generated by scanner — DO NOT EDIT
    #|
    #|fn inline_cells() -> Map[String, (Map[String, @ast.Value]) -> @rabbita.Cell] {
    #|  let m : Map[String, (Map[String, @ast.Value]) -> @rabbita.Cell] = Map([])
    #|
  )
  for i = 0; i < inline_s.length(); i = i + 1 {
    let c = inline_s[i]
    sb.write_string("  m.set(\"\{c}\", fn(args) { @\{c}.\{c}_cell(args) })\n")
  }
  sb.write_string("  m\n}\n\n")
  sb.write_string(
    #|fn container_cells() -> Map[String, (Map[String, @ast.Value], String) -> @rabbita.Cell] {
    #|  let m : Map[String, (Map[String, @ast.Value], String) -> @rabbita.Cell] = Map([])
    #|
  )
  for i = 0; i < container_s.length(); i = i + 1 {
    let c = container_s[i]
    sb.write_string("  m.set(\"\{c}\", fn(args, body) { @\{c}.\{c}_cell(args, body) })\n")
  }
  sb.write_string("  m\n}\n")
  @fs.write_string_to_file("\{out_dir}/_registry.mbt", sb.to_string())
  println("Generated: _registry.mbt (\{inline_s.length()} inline, \{container_s.length()} container)")
}

/// Collect CSS: theme/base.css + component .css files
fn collect_css(build_dir : String) -> String raise {
  let sb = StringBuilder::new()
  if @fs.path_exists("\{build_dir}/theme/base.css") {
    try {
      sb.write_string(@fs.read_file_to_string("\{build_dir}/theme/base.css"))
      sb.write_char('\n')
    } catch { _ => () }
  }
  let comp_dir = "\{build_dir}/components"
  if @fs.path_exists(comp_dir) {
    let subdirs = @fs.read_dir(comp_dir)
    subdirs.sort()
    for i = 0; i < subdirs.length(); i = i + 1 {
      let name = subdirs[i]
      let css_path = "\{comp_dir}/\{name}/\{name}.css"
      if @fs.path_exists(css_path) {
        try {
          sb.write_string(@fs.read_file_to_string(css_path))
          sb.write_char('\n')
          println("Collected: " + name + "/" + name + ".css")
        } catch { _ => () }
      }
    }
  }
  sb.to_string()
}
