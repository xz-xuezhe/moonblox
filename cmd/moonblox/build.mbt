///|
/// moonblox build — generate temp project in _moonblox/, compile, assemble dist/
pub async fn build(dir : String) -> Unit {
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
    try! @fs.create_dir("\{build_dir}/pages")
  } catch {
    e => {
      println("Error: failed to create _moonblox/: \{e}")
      return
    }
  }

  // Generate moon.mod.json
  generate_moon_mod(build_dir, engine_version)

  // Copy user content
  copy_components(dir, build_dir)
  copy_theme(dir, build_dir)

  // Generate root moon.pkg (shared, no is-main)
  generate_root_moon_pkg(build_dir)

  // Scan components, generate shared _registry.mbt at root
  scan_components("\{build_dir}/components", build_dir)

  // Per-page generation: collect front matter for list page
  let posts : Array[PostMeta] = []
  let posts_dir = "\{dir}/posts"
  try {
    if @fs.path_exists(posts_dir) {
      let files = @fs.read_dir(posts_dir)
      for i = 0; i < files.length(); i = i + 1 {
        let name = files[i]
        if name.has_suffix(".md") {
          let content = @fs.read_file_to_string("\{posts_dir}/\{name}")
          let slug = slug_from_filename(name)
          let page_dir = "\{build_dir}/pages/\{slug}"
          try! @fs.create_dir(page_dir)
          generate_page_moon_pkg(build_dir, slug)
          @fs.write_string_to_file(
            "\{page_dir}/main.mbt",
            generate_main_mbt(content),
          )
          println("Generated: pages/\{slug}/")
          let meta = extract_frontmatter(content)
          posts.push(PostMeta::{
            slug,
            title: get_meta(meta, "title", slug),
            date: get_meta(meta, "date", ""),
            tags: get_meta(meta, "tags", ""),
          })
        }
      }
    }
  } catch {
    _ => ()
  }

  // Collect CSS: base.css + component .css files
  let css = collect_css(build_dir)

  // Run moon build
  println("Building JS...")
  let result = @process.run(
    "moon",
    ["build", "--target", "js", "--release"],
    cwd=build_dir,
  )
  guard result == 0 else {
    println("Error: moon build failed with exit code \{result}")
    return
  }

  // Assemble dist/
  let dist_dir = "\{dir}/dist"
  if @fs.path_exists(dist_dir) {
    remove_dir_all(dist_dir)
  }
  try! @fs.create_dir(dist_dir)

  // Copy per-page JS and generate HTML shells
  let js_dir = "\{build_dir}/_build/js/release/build"
  for i = 0; i < posts.length(); i = i + 1 {
    let slug = posts[i].slug
    let page_dist = "\{dist_dir}/\{slug}"
    try! @fs.create_dir(page_dist)
    // Copy JS
    try {
      let js_src = "\{js_dir}/pages/\{slug}/\{slug}.js"
      if @fs.path_exists(js_src) {
        @fs.write_string_to_file(
          "\{page_dist}/\{slug}.js",
          @fs.read_file_to_string(js_src),
        )
        println("Copied: \{slug}.js -> dist/\{slug}/")
      }
    } catch {
      _ => ()
    }
    // Write page HTML shell
    let html = "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n  <meta charset=\"UTF-8\">\n  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n  <title>\{posts[i].title}</title>\n  <link rel=\"stylesheet\" href=\"../style.css\">\n</head>\n<body>\n  <div id=\"app\"></div>\n  <script src=\"\{slug}.js\" type=\"module\"></script>\n</body>\n</html>\n"
    @fs.write_string_to_file("\{page_dist}/index.html", html) catch {
      _ => ()
    }
  }

  // Sort posts by date descending for list page
  posts.sort_by(fn(a, b) {
    if a.date > b.date {
      -1
    } else if a.date < b.date {
      1
    } else {
      0
    }
  })

  // Generate list page (static HTML)
  generate_list_html(posts, dist_dir)

  if css != "" {
    @fs.write_string_to_file("\{dist_dir}/style.css", css) catch {
      _ => ()
    }
  }

  println("Built: \{dist_dir}/")
}

///|
/// Remove a directory and all its contents recursively
fn remove_dir_all(dir : String) -> Unit raise {
  guard @fs.path_exists(dir) else { return }
  for f in @fs.read_dir(dir) {
    let path = "\{dir}/\{f}"
    if @fs.is_dir(path) {
      remove_dir_all(path)
    } else {
      @fs.remove_file(path) catch {
        _ => ()
      }
    }
  }
  try! @fs.remove_dir(dir)
}

///|
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
    "    " +
    engine_dep +
    ",\n" +
    "    \"moonbit-community/rabbita\": \"0.12.4\",\n" +
    "    \"mizchi/markdown\": \"0.6.2\"\n" +
    "  }\n" +
    "}\n"
  @fs.write_string_to_file("\{build_dir}/moon.mod.json", content)
}

///|
/// Generate root moon.pkg — shared package (no is-main), hosts _registry.mbt
fn generate_root_moon_pkg(build_dir : String) -> Unit raise {
  let comp_dir = "\{build_dir}/components"
  let parts : Array[String] = []
  parts.push("import {\n")
  parts.push("  \"xz-xuezhe/moonblox/ast\",\n")
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
  @fs.write_string_to_file("\{build_dir}/moon.pkg", join_strings(parts))
}

///|
/// Generate per-page moon.pkg — is-main, imports root + engine packages
fn generate_page_moon_pkg(build_dir : String, slug : String) -> Unit raise {
  let parts : Array[String] = []
  parts.push("import {\n")
  parts.push("  \"moonblox-build\" as @root,\n")
  parts.push("  \"xz-xuezhe/moonblox/convert\",\n")
  parts.push("  \"xz-xuezhe/moonblox/render\",\n")
  parts.push("  \"moonbit-community/rabbita\",\n")
  parts.push("}\n\n")
  parts.push("supported_targets = \"js\"\n")
  parts.push("options(\n  \"is-main\": true,\n)\n")
  @fs.write_string_to_file(
    "\{build_dir}/pages/\{slug}/moon.pkg",
    join_strings(parts),
  )
}

///|
fn join_strings(ss : Array[String]) -> String {
  let sb = StringBuilder::new()
  for i = 0; i < ss.length(); i = i + 1 {
    sb.write_string(ss[i])
  }
  sb.to_string()
}

///|
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
            @fs.write_string_to_file(
              "\{dst_dir}/\{f}",
              @fs.read_file_to_string(src_file),
            )
          }
        }
      }
      println("Copied: components/\{name}/")
    }
  }
}

///|
/// Copy user's theme/ into _moonblox/theme/
fn copy_theme(src_root : String, build_dir : String) -> Unit raise {
  let src = "\{src_root}/theme"
  guard @fs.path_exists(src) else { return }
  for f in @fs.read_dir(src) {
    let src_file = "\{src}/\{f}"
    if !@fs.is_dir(src_file) {
      @fs.write_string_to_file(
        "\{build_dir}/theme/\{f}",
        @fs.read_file_to_string(src_file),
      )
    }
  }
}

///|
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
        let has_cell = content.contains("_cell(")
        if has_cell {
          if content.contains("children : Array[@rabbita.Html]") {
            container_s.push(comp_name)
          } else {
            inline_s.push(comp_name)
          }
          generate_props(mbt_path, comp_dir, comp_name)
        }
      }
    }
  }
  inline_s.sort()
  container_s.sort()

  let sb = StringBuilder::new()
  sb.write_string(
    (
      #|// Auto-generated by scanner — DO NOT EDIT
      #|
      #|pub fn inline_cells() -> Map[String, (Map[String, @ast.Value]) -> @rabbita.Cell] {
      #|  let m : Map[String, (Map[String, @ast.Value]) -> @rabbita.Cell] = Map([])
      #|
    ),
  )
  for i = 0; i < inline_s.length(); i = i + 1 {
    let c = inline_s[i]
    sb.write_string(
      "  m.set(\"\{c}\", fn(args) { @\{c}.\{c}_cell(@\{c}.\{c}_props(args)) })\n",
    )
  }
  sb.write_string("  m\n}\n\n")
  sb.write_string(
    (
      #|pub fn container_cells() -> Map[String, (Map[String, @ast.Value], Array[@rabbita.Html]) -> @rabbita.Cell] {
      #|  let m : Map[String, (Map[String, @ast.Value], Array[@rabbita.Html]) -> @rabbita.Cell] = Map([])
      #|
    ),
  )
  for i = 0; i < container_s.length(); i = i + 1 {
    let c = container_s[i]
    sb.write_string(
      "  m.set(\"\{c}\", fn(args, children) { @\{c}.\{c}_cell(@\{c}.\{c}_props(args), children) })\n",
    )
  }
  sb.write_string("  m\n}\n")
  @fs.write_string_to_file("\{out_dir}/_registry.mbt", sb.to_string())
  println(
    "Generated: _registry.mbt (\{inline_s.length()} inline, \{container_s.length()} container)",
  )
}

///|
/// Collect CSS: theme/base.css + component .css files
fn collect_css(build_dir : String) -> String raise {
  let sb = StringBuilder::new()
  if @fs.path_exists("\{build_dir}/theme/base.css") {
    try {
      sb.write_string(@fs.read_file_to_string("\{build_dir}/theme/base.css"))
      sb.write_char('\n')
    } catch {
      _ => ()
    }
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
        } catch {
          _ => ()
        }
      }
    }
  }
  sb.to_string()
}

///|
/// Parse Props::new() and generate _props.mbt
fn generate_props(
  mbt_path : String,
  comp_dir : String,
  comp_name : String,
) -> Unit raise {
  let content = @fs.read_file_to_string(mbt_path)
  let marker = "Props::new("
  match content.find(marker) {
    None => return
    Some(idx) => {
      let rest = content[idx + marker.length():].to_owned()
      match rest.find(")") {
        None => return
        Some(end) => {
          let params_str = rest[0:end].trim().to_owned()
          write_props_file(comp_dir, comp_name, params_str)
        }
      }
    }
  }
}

///|
fn write_props_file(
  comp_dir : String,
  comp_name : String,
  params_str : String,
) -> Unit raise {
  let props_name = capitalize(comp_name) + "Props"
  let sb = StringBuilder::new()
  sb.write_string("// Auto-generated by scanner — DO NOT EDIT\n\n")
  sb.write_string(
    "pub fn " +
    comp_name +
    "_props(args : Map[String, @ast.Value]) -> " +
    props_name +
    " {\n",
  )
  sb.write_string("  " + props_name + "::new(\n")

  let params = split_top_level(params_str, ',')
  for i = 0; i < params.length(); i = i + 1 {
    let p = params[i].trim().to_owned()
    if p != "" {
      let (param_name, type_) = match p.find(":") {
        Some(c) => {
          let before = p[0:c].trim().to_owned()
          let name = if before.has_suffix("?") {
            before[0:before.length() - 1].trim().to_owned()
          } else {
            before
          }
          let type_end = match p.find("=") {
            Some(e) => e
            None => p.length()
          }
          let typ = p[c + 1:type_end].trim().to_owned()
          (name, typ)
        }
        None => (p.trim().to_owned(), "String")
      }
      let (pat, body) = match type_ {
        "String" => ("@ast.Value::Str(s)", "s")
        "Double" => ("@ast.Value::Number(n)", "n")
        "Bool" => ("@ast.Value::Bool(b)", "b")
        _ => ("v", "panic()")
      }
      sb.write_string(
        "    " +
        param_name +
        "?=args.get(\"" +
        param_name +
        "\").bind(fn(v) { match v { " +
        pat +
        " => Some(" +
        body +
        "); _ => None } }),\n",
      )
    }
  }
  sb.write_string("  )\n}\n")
  @fs.write_string_to_file(
    comp_dir + "/" + comp_name + "_props.mbt",
    sb.to_string(),
  )
  println("Generated: " + comp_name + "_props.mbt")
}

///|
fn capitalize(s : String) -> String {
  if s.length() == 0 {
    ""
  } else {
    match s.get_char(0) {
      Some(c) if c >= 'a' && c <= 'z' => {
        let upper = Char::from_int(c.to_int() - 32)
        upper.to_string() + s[1:].to_owned()
      }
      _ => s
    }
  }
}

///|
fn split_top_level(s : String, sep : Char) -> Array[String] {
  let result : Array[String] = []
  let mut start = 0
  let mut depth = 0
  for i = 0; i < s.length(); i = i + 1 {
    match s.get_char(i) {
      Some('(') | Some('{') | Some('[') => depth = depth + 1
      Some(')') | Some('}') | Some(']') => depth = depth - 1
      Some(c) if c == sep && depth == 0 => {
        result.push(s[start:i].to_owned())
        start = i + 1
      }
      _ => ()
    }
  }
  if start < s.length() {
    result.push(s[start:].to_owned())
  }
  result
}

// --- Multi-page utilities ---

///|
struct PostMeta {
  slug : String
  title : String
  date : String
  tags : String
}

///|
/// Derive URL slug from filename by stripping .md extension
fn slug_from_filename(filename : String) -> String {
  if filename.has_suffix(".md") {
    filename[0:filename.length() - 3].to_owned()
  } else {
    filename
  }
}

///|
/// Extract YAML front matter as Map from raw markdown content
fn extract_frontmatter(content : String) -> Map[String, String] {
  if content.has_prefix("---") {
    let rest = content[3:].to_owned()
    match rest.find("\n---") {
      Some(end) => {
        let yaml = rest[0:end].trim().to_owned()
        let map : Map[String, String] = Map([])
        for line in yaml.split("\n") {
          let line = line.trim().to_owned()
          match line.find(":") {
            Some(colon) if colon > 0 => {
              let key = line[0:colon].trim().to_owned()
              let value = line[colon + 1:].trim().to_owned()
              if key != "" {
                map.set(key, value)
              }
            }
            _ => ()
          }
        }
        map
      }
      None => Map([])
    }
  } else {
    Map([])
  }
}

///|
fn get_meta(
  meta : Map[String, String],
  key : String,
  default : String,
) -> String {
  match meta.get(key) {
    Some(v) => v
    None => default
  }
}

///|
/// Generate static HTML list page from post metadata
fn generate_list_html(posts : Array[PostMeta], dist_dir : String) -> Unit raise {
  let sb = StringBuilder::new()
  sb.write_string("<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n")
  sb.write_string("  <meta charset=\"UTF-8\">\n")
  sb.write_string(
    "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n",
  )
  sb.write_string("  <title>Blog</title>\n")
  sb.write_string("  <link rel=\"stylesheet\" href=\"style.css\">\n")
  sb.write_string("</head>\n<body>\n")
  sb.write_string("  <main class=\"article-list\">\n")
  sb.write_string("    <h1>Blog</h1>\n")

  for i = 0; i < posts.length(); i = i + 1 {
    sb.write_string("    <article class=\"article-card\">\n")
    sb.write_string(
      "      <h2><a href=\"\{posts[i].slug}/\">\{posts[i].title}</a></h2>\n",
    )
    if posts[i].date != "" {
      sb.write_string(
        "      <time class=\"article-date\">\{posts[i].date}</time>\n",
      )
    }
    if posts[i].tags != "" {
      sb.write_string("      <div class=\"article-tags\">")
      for tag in posts[i].tags.split(",") {
        let t = tag.trim().to_owned()
        if t != "" {
          sb.write_string("<span class=\"article-tag\">\{t}</span>")
        }
      }
      sb.write_string("</div>\n")
    }
    sb.write_string("    </article>\n")
  }

  sb.write_string("  </main>\n")
  sb.write_string("</body>\n</html>\n")
  @fs.write_string_to_file("\{dist_dir}/index.html", sb.to_string()) catch {
    _ => ()
  }
  println("Generated: list page (\{posts.length()} articles)")
}

// --- Code generation ---

///|
fn escape_md(s : String) -> String {
  let sb = StringBuilder::new()
  for i = 0; i < s.length(); i = i + 1 {
    match s.get_char(i) {
      Some('\\') => sb.write_string("\\\\")
      Some('"') => sb.write_string("\\\"")
      Some('\n') => sb.write_string("\\n")
      Some(c) => sb.write_char(c)
      None => ()
    }
  }
  sb.to_string()
}

///|
pub fn generate_main_mbt(md_content : String) -> String {
  let escaped = escape_md(md_content)
  let s =
    $|// Generated by moonblox build — DO NOT EDIT
    $|
    $|fn main {
    $|  let md = "\{escaped}"
    $|  let doc = @convert.parse_markdown(md)
    $|  let cell = @render.render_document(doc, inline_cells=@root.inline_cells(), container_cells=@root.container_cells())
    $|  @rabbita.new(cell).mount("app")
    $|}
  s
}
