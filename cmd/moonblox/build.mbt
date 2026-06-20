// Dependency versions — keep in sync with root moon.mod

///|
const RABBITA_VERSION : String = "0.12.4"

///|
const MARKDOWN_VERSION : String = "0.6.2"

///|
const ENGINE_VERSION : String = "0.1.0"

///|
const BUILD_DIR_NAME : String = "_moonblox"

///|
const COMPONENTS_DIR : String = "components"

///|
const THEME_DIR : String = "theme"

///|
const PAGES_DIR : String = "pages"

///|
const POSTS_DIR : String = "posts"

///|
const DIST_DIR : String = "dist"

///|
const BUILD_OUT_DIR : String = "_build"

///|
const BUILD_ARTIFACT_PATH : String = "_build/js/release/build"

///|
const PACKAGE_NAME : String = "moonblox-build"

///|
const REGISTRY_FILE : String = "_registry.mbt"

///|
const PROPS_SUFFIX : String = "_props.mbt"

///|
const INDEX_HTML : String = "index.html"

///|
const STYLE_CSS : String = "style.css"

///|
const MAIN_MBT : String = "main.mbt"

///|
const MOONCAKES_DIR : String = ".mooncakes"

///|
const ENGINE_PACKAGE : String = "xz-xuezhe/moonblox"

///|
const ENGINE_AST_PACKAGE : String = "xz-xuezhe/moonblox/ast"

///|
const ENGINE_CONVERT_PACKAGE : String = "xz-xuezhe/moonblox/convert"

///|
const ENGINE_RENDER_PACKAGE : String = "xz-xuezhe/moonblox/render"

///|
const RABBITA_PACKAGE : String = "moonbit-community/rabbita"

///|
const MARKDOWN_PACKAGE : String = "mizchi/markdown"

///|
const MOUNT_ID : String = "app"

///|
/// moonblox build — generate temp project in _moonblox/, compile, assemble dist/
pub async fn build(dir : String) -> Bool {
  guard @fs.path_exists(dir) else {
    println("Error: directory not found: \{dir}")
    return false
  }

  let build_dir = "\{dir}/\{BUILD_DIR_NAME}"

  // Clean and recreate _moonblox/
  try {
    if @fs.path_exists(build_dir) {
      remove_dir_all(build_dir)
    }
    try! @fs.create_dir(build_dir)
    try! @fs.create_dir("\{build_dir}/\{COMPONENTS_DIR}")
    try! @fs.create_dir("\{build_dir}/\{THEME_DIR}")
    try! @fs.create_dir("\{build_dir}/\{PAGES_DIR}")
  } catch {
    e => {
      println("Error: failed to create _moonblox/: \{e}")
      return false
    }
  }

  // Generate moon.mod.json
  generate_moon_mod(build_dir)

  // Copy user content
  copy_components(dir, build_dir)
  copy_theme(dir, build_dir)

  // Generate root moon.pkg (shared, no is-main)
  generate_root_moon_pkg(build_dir)

  // Scan components, generate shared _registry.mbt at root
  scan_components("\{build_dir}/\{COMPONENTS_DIR}", build_dir)

  // Per-page generation: collect front matter for list page
  let posts : Array[PostMeta] = []
  let posts_dir = "\{dir}/\{POSTS_DIR}"
  if @fs.path_exists(posts_dir) {
    let files = @fs.read_dir(posts_dir)
    for i = 0; i < files.length(); i = i + 1 {
      let name = files[i]
      if name.has_suffix(".md") {
        try {
          let content = @fs.read_file_to_string("\{posts_dir}/\{name}")
          let slug = slug_from_filename(name)
          let page_dir = "\{build_dir}/\{PAGES_DIR}/\{slug}"
          try! @fs.create_dir(page_dir)
          generate_page_moon_pkg(build_dir, slug)
          @fs.write_string_to_file(
            "\{page_dir}/\{MAIN_MBT}",
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
        } catch {
          @fs.IOError(msg) => println("Warning: skipping '\{name}': \{msg}")
          _ => println("Warning: skipping '\{name}': unexpected error")
        }
      }
    }
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
    return false
  }

  // Assemble dist/
  let dist_dir = "\{dir}/\{DIST_DIR}"
  if @fs.path_exists(dist_dir) {
    remove_dir_all(dist_dir)
  }
  try! @fs.create_dir(dist_dir)

  // Copy per-page JS and generate HTML shells
  let js_dir = "\{build_dir}/\{BUILD_ARTIFACT_PATH}"
  for i = 0; i < posts.length(); i = i + 1 {
    let slug = posts[i].slug
    let page_dist = "\{dist_dir}/\{slug}"
    try! @fs.create_dir(page_dist)
    // Copy JS
    let js_src = "\{js_dir}/\{PAGES_DIR}/\{slug}/\{slug}.js"
    if @fs.path_exists(js_src) {
      @fs.write_string_to_file(
        "\{page_dist}/\{slug}.js",
        @fs.read_file_to_string(js_src),
      )
      println("Copied: \{slug}.js -> dist/\{slug}/")
    }
    // Write page HTML shell
    let html = fill_template(page_shell, posts[i].title, slug)
    @fs.write_string_to_file("\{page_dist}/\{INDEX_HTML}", html)
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
    @fs.write_string_to_file("\{dist_dir}/\{STYLE_CSS}", css) catch {
      @fs.IOError(msg) => println("Warning: failed to write style.css: \{msg}")
    }
  }

  println("Built: \{dist_dir}/")
  true
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
fn generate_moon_mod(build_dir : String) -> Unit raise {
  let engine_dep = match @env.get_env_var("MOONBLOX_PATH") {
    Some(path) => {
      let resolved = if path.has_prefix("/") {
        path
      } else {
        match @env.get_env_var("PWD") {
          Some(cwd) => "\{cwd}/\{path}"
          None => path
        }
      }
      "\"" + ENGINE_PACKAGE + "\": { \"path\": \"" + resolved + "\" }"
    }
    None => "\"" + ENGINE_PACKAGE + "\": \"" + ENGINE_VERSION + "\""
  }
  let content = "{\n" +
    "  \"name\": \"" +
    PACKAGE_NAME +
    "\",\n" +
    "  \"preferred-target\": \"js\",\n" +
    "  \"deps\": {\n" +
    "    " +
    engine_dep +
    ",\n" +
    "    \"" +
    RABBITA_PACKAGE +
    "\": \"" +
    RABBITA_VERSION +
    "\",\n" +
    "    \"" +
    MARKDOWN_PACKAGE +
    "\": \"" +
    MARKDOWN_VERSION +
    "\"\n" +
    "  }\n" +
    "}\n"
  @fs.write_string_to_file("\{build_dir}/moon.mod.json", content)
}

///|
/// Generate root moon.pkg — shared package (no is-main), hosts _registry.mbt
fn generate_root_moon_pkg(build_dir : String) -> Unit raise {
  let comp_dir = "\{build_dir}/\{COMPONENTS_DIR}"
  let parts : Array[String] = []
  parts.push("import {\n")
  parts.push("  \"" + ENGINE_AST_PACKAGE + "\",\n")
  parts.push("  \"" + RABBITA_PACKAGE + "\",\n")

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
  parts.push("  \"" + PACKAGE_NAME + "\" @root,\n")
  parts.push("  \"" + ENGINE_CONVERT_PACKAGE + "\",\n")
  parts.push("  \"" + ENGINE_RENDER_PACKAGE + "\",\n")
  parts.push("  \"" + RABBITA_PACKAGE + "\",\n")
  parts.push("}\n\n")
  parts.push("supported_targets = \"js\"\n")
  parts.push("options(\n  \"is-main\": true,\n)\n")
  @fs.write_string_to_file(
    "\{build_dir}/\{PAGES_DIR}/\{slug}/moon.pkg",
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
  let src = "\{src_root}/\{COMPONENTS_DIR}"
  guard @fs.path_exists(src) else { return }
  for name in @fs.read_dir(src) {
    let src_dir = "\{src}/\{name}"
    if @fs.is_dir(src_dir) {
      let dst_dir = "\{build_dir}/components/\{name}"
      try! @fs.create_dir(dst_dir)
      for f in @fs.read_dir(src_dir) {
        if f != BUILD_OUT_DIR && f != MOONCAKES_DIR {
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
  let src = "\{src_root}/\{THEME_DIR}"
  guard @fs.path_exists(src) else { return }
  for f in @fs.read_dir(src) {
    let src_file = "\{src}/\{f}"
    if !@fs.is_dir(src_file) {
      @fs.write_string_to_file(
        "\{build_dir}/\{THEME_DIR}/\{f}",
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
          generate_props(mbt_path, out_dir, comp_name)
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
      "  m.set(\"\{c}\", fn(args) { @\{c}.\{c}_cell(\{c}_props(args)) })\n",
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
      "  m.set(\"\{c}\", fn(args, children) { @\{c}.\{c}_cell(\{c}_props(args), children) })\n",
    )
  }
  sb.write_string("  m\n}\n")
  @fs.write_string_to_file("\{out_dir}/\{REGISTRY_FILE}", sb.to_string())
  println(
    "Generated: _registry.mbt (\{inline_s.length()} inline, \{container_s.length()} container)",
  )
}

///|
/// Collect CSS: theme/base.css + component .css files
fn collect_css(build_dir : String) -> String raise {
  let sb = StringBuilder::new()
  if @fs.path_exists("\{build_dir}/\{THEME_DIR}/base.css") {
    try {
      sb.write_string(
        @fs.read_file_to_string("\{build_dir}/\{THEME_DIR}/base.css"),
      )
      sb.write_char('\n')
    } catch {
      @fs.IOError(msg) =>
        println("Warning: failed to read theme/base.css: \{msg}")
    }
  }
  let comp_dir = "\{build_dir}/\{COMPONENTS_DIR}"
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
          @fs.IOError(msg) =>
            println("Warning: failed to read \{name}.css: \{msg}")
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
  out_dir : String,
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
          write_props_file(out_dir, comp_name, params_str)
        }
      }
    }
  }
}

///|
fn write_props_file(
  out_dir : String,
  comp_name : String,
  params_str : String,
) -> Unit raise {
  let pkg_prefix = "@" + comp_name + "."
  let props_name = capitalize(comp_name) + "Props"
  let sb = StringBuilder::new()
  sb.write_string("// Auto-generated by scanner — DO NOT EDIT\n\n")
  sb.write_string(
    "pub fn " +
    comp_name +
    "_props(args : Map[String, @ast.Value]) -> " +
    pkg_prefix +
    props_name +
    " {\n",
  )
  sb.write_string("  " + pkg_prefix + props_name + "::new(\n")

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
    out_dir + "/" + comp_name + PROPS_SUFFIX,
    sb.to_string(),
  )
  println("Generated: " + comp_name + PROPS_SUFFIX)
}

///|
fn capitalize(s : String) -> String {
  if s.length() == 0 {
    ""
  } else {
    match s.get_char(0) {
      Some(c) if c >= 'a' && c <= 'z' => {
        let upper = Int::unsafe_to_char(c.to_int() - 32)
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
  @fs.write_string_to_file("\{dist_dir}/\{INDEX_HTML}", sb.to_string())
  println("Generated: list page (\{posts.length()} articles)")
}

// --- Template helpers ---

///|
/// Simple placeholder replacement: __TITLE__ and __SLUG__
fn fill_template(template : String, title : String, slug : String) -> String {
  template
  .replace_all(old="__TITLE__", new=title)
  .replace_all(old="__SLUG__", new=slug)
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
    $|  @rabbita.new(cell).mount("\{MOUNT_ID}")
    $|}
  s
}
