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
const BUILD_ARTIFACT_PATH_DEBUG : String = "_build/js/debug/build"

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
struct SiteConfig {
  input : String
  output : String
  components : String
}

///|
fn default_config() -> SiteConfig {
  { input: POSTS_DIR, output: DIST_DIR, components: COMPONENTS_DIR }
}

///|
fn read_config(dir : String) -> SiteConfig {
  let config_path = "\{dir}/moonblox.json"
  guard @fs.path_exists(config_path) else { return default_config() }
  let content = @fs.read_file_to_string(config_path) catch {
    _ => return default_config()
  }
  let raw = @json.parse(content) catch { _ => return default_config() }
  match raw {
    Object(obj) => {
      let get_str = fn(key : String, default : String) -> String {
        match obj.get(key) {
          Some(String(s)) => s
          _ => default
        }
      }
      let comps = get_str("components", COMPONENTS_DIR)
      let comps = if comps.has_prefix("./") {
        comps[2:].to_owned()
      } else {
        comps
      }
      {
        input: get_str("input", POSTS_DIR),
        output: get_str("output", DIST_DIR),
        components: comps,
      }
    }
    _ => default_config()
  }
}

// --- Incremental Build Support ---

///|
/// Content hash for change detection (sum of char values + length).
fn hash_content(content : String) -> Int {
  let mut sum = 0
  for i = 0; i < content.length(); i = i + 1 {
    match content.get_char(i) {
      Some(c) => sum = sum + c.to_int()
      None => ()
    }
  }
  sum + content.length()
}

///|
struct BuildCache {
  post_mtimes : Map[String, Int]
  component_mtimes : Map[String, Int]
  theme_mtime : Int
  config_mtime : Int
}

///|
fn BuildCache::new() -> BuildCache {
  {
    post_mtimes: Map([]),
    component_mtimes: Map([]),
    theme_mtime: 0,
    config_mtime: 0,
  }
}

///|
enum ChangeType {
  NoChanges
  PostsChanged(Array[String])
  ComponentsChanged(Array[String])
  ThemeChanged
  ConfigChanged
  FullRebuild
}

///|
/// Compare current file state with cache and return what changed.
fn detect_changes(
  dir : String,
  cache : Ref[BuildCache],
  config : SiteConfig,
) -> ChangeType {
  let old = cache.val

  // Check config
  let config_path = "\{dir}/moonblox.json"
  let config_h = if @fs.path_exists(config_path) {
    hash_content(@fs.read_file_to_string(config_path) catch { _ => "" })
  } else {
    0
  }

  // Check theme
  let theme_path = "\{dir}/\{THEME_DIR}/base.css"
  let theme_h = if @fs.path_exists(theme_path) {
    hash_content(@fs.read_file_to_string(theme_path) catch { _ => "" })
  } else {
    0
  }

  // Check components
  let comp_dir = "\{dir}/\{config.components}"
  let comp_hashes : Map[String, Int] = Map([])
  let changed_comps : Array[String] = []
  if @fs.path_exists(comp_dir) {
    let subdirs = @fs.read_dir(comp_dir) catch {
      _ => return ChangeType::FullRebuild
    }
    for i = 0; i < subdirs.length(); i = i + 1 {
      let name = subdirs[i]
      let mbt_path = "\{comp_dir}/\{name}/\{name}.mbt"
      let css_path = "\{comp_dir}/\{name}/\{name}.css"
      let pkg_path = "\{comp_dir}/\{name}/moon.pkg"
      let mut h = 0
      if @fs.path_exists(mbt_path) {
        h = h +
          hash_content(@fs.read_file_to_string(mbt_path) catch { _ => "" })
      }
      if @fs.path_exists(css_path) {
        h = h +
          hash_content(@fs.read_file_to_string(css_path) catch { _ => "" })
      }
      if @fs.path_exists(pkg_path) {
        h = h +
          hash_content(@fs.read_file_to_string(pkg_path) catch { _ => "" })
      }
      comp_hashes.set(name, h)
      match old.component_mtimes.get(name) {
        Some(old_h) => if h != old_h { changed_comps.push(name) }
        None => changed_comps.push(name)
      }
    }
  }

  // Check posts
  let posts_dir = "\{dir}/\{config.input}"
  let post_hashes : Map[String, Int] = Map([])
  let changed_posts : Array[String] = []
  if @fs.path_exists(posts_dir) {
    let files = @fs.read_dir(posts_dir) catch {
      _ => return ChangeType::FullRebuild
    }
    for i = 0; i < files.length(); i = i + 1 {
      let fname = files[i]
      if fname.has_suffix(".md") {
        let path = "\{posts_dir}/\{fname}"
        let content = @fs.read_file_to_string(path) catch { _ => "" }
        let h = if content != "" { hash_content(content) } else { 0 }
        post_hashes.set(path, h)
        match old.post_mtimes.get(path) {
          Some(old_h) =>
            if h != old_h {
              changed_posts.push(slug_from_filename(fname))
            }
          None => changed_posts.push(slug_from_filename(fname))
        }
      }
    }
  }

  // Update cache atomically
  cache.val = {
    post_mtimes: post_hashes,
    component_mtimes: comp_hashes,
    theme_mtime: theme_h,
    config_mtime: config_h,
  }

  // Determine change type (priority: config > theme > components+posts > components > posts)
  if old.config_mtime != config_h {
    return ChangeType::ConfigChanged
  }
  if old.theme_mtime != theme_h {
    return ChangeType::ThemeChanged
  }
  if changed_comps.length() > 0 && changed_posts.length() > 0 {
    return ChangeType::FullRebuild
  }
  if changed_comps.length() > 0 {
    return ChangeType::ComponentsChanged(changed_comps)
  }
  if changed_posts.length() > 0 {
    return ChangeType::PostsChanged(changed_posts)
  }

  ChangeType::NoChanges
}

///|
/// Collect post metadata from all markdown files in the posts directory.
fn collect_post_meta(
  posts_dir : String,
  _config : SiteConfig,
) -> Array[PostMeta] {
  let posts : Array[PostMeta] = []
  if @fs.path_exists(posts_dir) {
    let files = @fs.read_dir(posts_dir) catch { _ => return posts }
    for i = 0; i < files.length(); i = i + 1 {
      let name = files[i]
      if name.has_suffix(".md") {
        let content = @fs.read_file_to_string("\{posts_dir}/\{name}") catch {
          _ => continue
        }
        let slug = slug_from_filename(name)
        let doc = @convert.parse_markdown(content)
        let meta = doc.meta
        posts.push(PostMeta::{
          slug,
          title: match meta.get("title") {
            Some(t) => t
            None => slug
          },
          date: match meta.get("date") {
            Some(d) => d
            None => ""
          },
          tags: match meta.get("tags") {
            Some(t) => t
            None => ""
          },
        })
      }
    }
  }
  posts
}

///|
/// Perform an incremental rebuild based on detected changes.
async fn incremental_rebuild(
  dir : String,
  build_dir : String,
  config : SiteConfig,
  changes : ChangeType,
  dev_mode? : Bool = false,
) -> Bool {
  match changes {
    NoChanges => {
      println("No changes detected.")
      true
    }
    PostsChanged(slugs) => {
      let posts_dir = "\{dir}/\{config.input}"
      let comp_callbacks = build_callback_map(build_dir)
      let all_generated_comps : Array[String] = []

      for i = 0; i < slugs.length(); i = i + 1 {
        let slug = slugs[i]
        let fname = slug + ".md"
        let content = @fs.read_file_to_string("\{posts_dir}/\{fname}") catch {
          _ => {
            println("Warning: cannot read '\{fname}', skipping")
            continue
          }
        }
        let (processed_content, generated_comps) = process_structured_blocks(
          content, build_dir, comp_callbacks,
        )
        for comp_name in generated_comps {
          let mut already_have = false
          for k = 0; k < all_generated_comps.length(); k = k + 1 {
            if all_generated_comps[k] == comp_name {
              already_have = true
              break
            }
          }
          if !already_have {
            all_generated_comps.push(comp_name)
          }
        }
        let page_dir = "\{build_dir}/\{PAGES_DIR}/\{slug}"
        try {
          ensure_dir(page_dir)
          generate_page_moon_pkg(build_dir, slug)
          @fs.write_string_to_file(
            "\{page_dir}/\{MAIN_MBT}",
            generate_main_mbt(processed_content),
          )
          println("Updated: pages/\{slug}/")
        } catch {
          e => {
            println("Warning: failed to regenerate '\{slug}': \{e}")
            continue
          }
        }
      }

      // Regenerate list page
      let posts = collect_post_meta(posts_dir, config)
      posts.sort_by(fn(a, b) {
        let da = date_to_sortable(a.date)
        let db = date_to_sortable(b.date)
        if da > db {
          -1
        } else if da < db {
          1
        } else {
          0
        }
      })
      let list_page_dir = "\{build_dir}/\{PAGES_DIR}/_listing"
      try {
        ensure_dir(list_page_dir)
        generate_page_moon_pkg(build_dir, "_listing")
        @fs.write_string_to_file(
          "\{list_page_dir}/\{MAIN_MBT}",
          generate_main_mbt(generate_list_page(posts)),
        )
        println("Updated: pages/_listing/")
      } catch {
        e => println("Warning: failed to regenerate list page: \{e}")
      }

      // Add composite cell entries to registry
      if all_generated_comps.length() > 0 {
        let reg_path = "\{build_dir}/\{REGISTRY_FILE}"
        add_structured_cells_to_registry(reg_path, all_generated_comps) catch {
          e => println("Warning: failed to update registry: \{e}")
        }
      }

      // Run moon check first — catches type errors early
      let check_result = @process.run(
        "moon",
        ["check", "--target", "js"],
        cwd=build_dir,
      )
      guard check_result == 0 else {
        println("Error: moon check failed. Fix type errors before building.")
        return false
      }

      // Run moon build
      let moon_args = if dev_mode {
        ["build", "--target", "js"]
      } else {
        ["build", "--target", "js", "--release"]
      }
      println("Building JS (incremental)...")
      let result = @process.run("moon", moon_args, cwd=build_dir)
      guard result == 0 else {
        println("Error: moon build failed with exit code \{result}")
        return false
      }
      true
    }
    ComponentsChanged(names) => {
      let src_comp_dir = "\{dir}/\{config.components}"
      let dst_comp_dir = "\{build_dir}/\{COMPONENTS_DIR}"
      for i = 0; i < names.length(); i = i + 1 {
        let name = names[i]
        let src_dir = "\{src_comp_dir}/\{name}"
        let dst_dir = "\{dst_comp_dir}/\{name}"
        if @fs.path_exists(src_dir) && @fs.is_dir(src_dir) {
          try {
            if !@fs.path_exists(dst_dir) {
              @fs.create_dir(dst_dir)
            }
            for f in @fs.read_dir(src_dir) {
              let src_file = "\{src_dir}/\{f}"
              if !@fs.is_dir(src_file) {
                @fs.write_string_to_file(
                  "\{dst_dir}/\{f}",
                  @fs.read_file_to_string(src_file),
                )
              }
            }
            println("Copied: components/\{name}/")
          } catch {
            @fs.IOError(msg) =>
              println("Warning: failed to copy component '\{name}': \{msg}")
          }
        }
      }
      // Re-scan all components (regenerates registry + props)
      scan_components(dst_comp_dir, build_dir) catch {
        e => {
          println("Error: failed to scan components: \{e}")
          return false
        }
      }
      // Run moon check first — catches type errors early
      let check_result = @process.run(
        "moon",
        ["check", "--target", "js"],
        cwd=build_dir,
      )
      guard check_result == 0 else {
        println("Error: moon check failed. Fix type errors before building.")
        return false
      }

      // Run moon build
      let moon_args = if dev_mode {
        ["build", "--target", "js"]
      } else {
        ["build", "--target", "js", "--release"]
      }
      println("Building JS (incremental)...")
      let result = @process.run("moon", moon_args, cwd=build_dir)
      guard result == 0 else {
        println("Error: moon build failed with exit code \{result}")
        return false
      }
      true
    }
    ThemeChanged | ConfigChanged | FullRebuild => build(dir, dev_mode~)
  }
}

// --- Structured Block Processing ---

///|
struct StructuredBlockInfo {
  name : String
  model_raw : String
  body_md : String
  start_pos : Int
  end_pos : Int
}

///|
/// Find the matching `}` for a `{` at position `start`, skipping over strings.
fn find_matching_brace_in_text(text : String, start : Int) -> Int? {
  let len = text.length()
  guard start < len else { return None }
  guard text.get_char(start) is Some('{') else { return None }
  let mut depth = 1
  let mut i = start + 1
  while i < len && depth > 0 {
    // Use if instead of match to avoid mutation-in-pattern issues
    let c = text.get_char(i)
    if c is Some('"') {
      // Skip past string content
      i = i + 1
      while i < len {
        if text.get_char(i) is Some('"') {
          break
        }
        if text.get_char(i) is Some('\\') {
          i = i + 1
        }
        i = i + 1
      }
      i = i + 1
    } else {
      if c is Some('{') {
        depth = depth + 1
      }
      if c is Some('}') {
        depth = depth - 1
      }
      i = i + 1
    }
  }
  if depth == 0 {
    Some(i - 1)
  } else {
    None
  }
}

///|
/// Check if `::` at position `pos` is the only non-whitespace content on its line.
fn is_close_marker_on_own_line(md : String, pos : Int) -> Bool {
  let len = md.length()
  // Check before pos: only whitespace back to \n or start
  if pos > 0 {
    let mut found_newline = false
    for j = pos - 1; j >= 0; j = j - 1 {
      match md.get_char(j) {
        Some('\n') => {
          found_newline = true
          break
        }
        Some(' ') | Some('\t') => continue
        _ => return false
      }
    }
    if !found_newline {
      return false
    }
  }
  // Check after pos + 2: only whitespace to \n or end
  let after = pos + 2
  if after < len {
    for j = after; j < len; j = j + 1 {
      match md.get_char(j) {
        Some('\n') => return true
        Some(' ') | Some('\t') => continue
        _ => return false
      }
    }
  }
  true
}

///|
/// Scan for "::" in text starting from position `from`.
/// Returns the absolute position of the first match.
fn scan_for_colons(text : String, from : Int) -> Int? {
  let len = text.length()
  let mut i = from
  while i < len {
    if i + 1 < len {
      let a = text.get_char(i)
      let b = text.get_char(i + 1)
      if a is Some(':') && b is Some(':') {
        return Some(i)
      }
    }
    i = i + 1
  }
  None
}

///|
/// Scan markdown text for structured blocks: ::name { ... } body ::.
fn extract_structured_blocks(md : String) -> Array[StructuredBlockInfo] {
  let result : Array[StructuredBlockInfo] = []
  let len = md.length()
  let mut search = 0
  while search < len {
    match scan_for_colons(md, search) {
      None => break
      Some(pos) => {
        // Must not be ::: (container block)
        if pos + 2 < len && md.get_char(pos + 2) is Some(':') {
          search = pos + 3
          continue
        }
        // Must be at line start (pos == 0 or preceded by \n)
        if pos > 0 {
          match md.get_char(pos - 1) {
            Some('\n') => ()
            _ => {
              search = pos + 2
              continue
            }
          }
        }
        // Read name after ::
        let name_start = pos + 2
        let mut name_end = name_start
        while name_end < len {
          let c = md.get_char(name_end)
          let valid = match c {
            Some(c) if c != ' ' && c != '\t' && c != '\n' && c != '{' => true
            _ => false
          }
          if valid {
            name_end = name_end + 1
          } else {
            break
          }
        }
        let name = md[name_start:name_end].to_owned()
        if name == "" {
          search = pos + 2
          continue
        }
        // Skip whitespace to find {
        let mut brace_pos = name_end
        while brace_pos < len {
          match md.get_char(brace_pos) {
            Some(' ') | Some('\t') | Some('\n') => brace_pos = brace_pos + 1
            Some('{') => break
            _ => {
              search = pos + 2
              continue
            }
          }
        }
        if brace_pos >= len {
          search = pos + 2
          continue
        }
        // Find matching }
        match find_matching_brace_in_text(md, brace_pos) {
          None => {
            search = pos + 2
            continue
          }
          Some(close_brace) => {
            let model_raw = md[brace_pos + 1:close_brace].trim().to_owned()
            let body_start = close_brace + 1
            // Find closing :: on its own line
            let mut close_found : Int? = None
            let mut scan_pos = body_start
            while scan_pos < len {
              match scan_for_colons(md, scan_pos) {
                Some(found) => {
                  if found + 2 < len && md.get_char(found + 2) is Some(':') {
                    scan_pos = found + 3
                    continue
                  }
                  if is_close_marker_on_own_line(md, found) {
                    close_found = Some(found)
                    break
                  }
                  scan_pos = found + 2
                }
                None => break
              }
            }
            match close_found {
              Some(close_marker) => {
                let body_md = md[body_start:close_marker].trim().to_owned()
                let end_pos = close_marker + 2
                result.push(StructuredBlockInfo::{
                  name,
                  model_raw,
                  body_md,
                  start_pos: pos,
                  end_pos,
                })
                search = end_pos
              }
              None => {
                search = pos + 2
                continue
              }
            }
          }
        }
      }
    }
  }
  result
}

///|
/// Check if a char is a valid name character (for component names).
fn is_name_char(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') ||
  (c >= 'A' && c <= 'Z') ||
  (c >= '0' && c <= '9') ||
  c == '_' ||
  c == '-'
}

///|
/// Parse model string like `count = 0, name = "guest"` into var tuples.
/// Returns Array[(var_name, type, initial_value)].
fn parse_model_to_vars(model_raw : String) -> Array[(String, String, String)] {
  let result : Array[(String, String, String)] = []
  if model_raw == "" {
    return result
  }
  // Split by top-level commas (respecting nesting)
  let parts : Array[String] = []
  let mut seg_start = 0
  let mut depth_round = 0
  let mut depth_curly = 0
  let mut depth_bracket = 0
  let mut in_string = false
  let mut i = 0
  while i < model_raw.length() {
    let c = model_raw.get_char(i)
    if in_string {
      if c is Some('"') {
        in_string = false
      }
      if c is Some('\\') {
        i = i + 1
      }
    } else {
      if c is Some('"') {
        in_string = true
      }
      if c is Some('(') {
        depth_round = depth_round + 1
      }
      if c is Some(')') {
        depth_round = depth_round - 1
      }
      if c is Some('{') {
        depth_curly = depth_curly + 1
      }
      if c is Some('}') {
        depth_curly = depth_curly - 1
      }
      if c is Some('[') {
        depth_bracket = depth_bracket + 1
      }
      if c is Some(']') {
        depth_bracket = depth_bracket - 1
      }
      if c is Some(',') &&
        depth_round == 0 &&
        depth_curly == 0 &&
        depth_bracket == 0 {
        parts.push(model_raw[seg_start:i].trim().to_owned())
        seg_start = i + 1
      }
    }
    i = i + 1
  }
  if seg_start < model_raw.length() {
    parts.push(model_raw[seg_start:].trim().to_owned())
  }
  for i = 0; i < parts.length(); i = i + 1 {
    let part = parts[i]
    if part == "" {
      continue
    }
    match part.find("=") {
      Some(eq_pos) => {
        let var_name = part[0:eq_pos].trim().to_owned()
        let raw_val = part[eq_pos + 1:].trim().to_owned()
        if var_name == "" {
          continue
        }
        // Infer type
        let (type_name, init_val) = infer_type_and_value(raw_val)
        result.push((var_name, type_name, init_val))
      }
      None =>
        // No = sign — treat as String with empty default
        result.push((part, "String", "\"\""))
    }
  }
  result
}

///|
/// Infer the MoonBit type and initial value string from a raw token.
fn infer_type_and_value(raw : String) -> (String, String) {
  let trimmed = raw.trim().to_owned()
  // Quoted string — escape inner content for safe embedding
  if trimmed.has_prefix("\"") && trimmed.has_suffix("\"") {
    let inner = trimmed[1:trimmed.length() - 1].to_owned()
    ("String", "\"" + escape_mb_string(inner) + "\"")
  } else if trimmed == "true" || trimmed == "false" {
    ("Bool", trimmed)
  } else if is_numeric(trimmed) {
    if trimmed.contains(".") {
      ("Double", trimmed)
    } else {
      ("Double", trimmed + ".0")
    }
  } else if trimmed == "" {
    ("String", "\"\"")
  } else {
    // Treat as identifier/var reference — stored as-is with escaped quotes
    ("String", "\"" + escape_mb_string(trimmed) + "\"")
  }
}

///|
fn is_numeric(s : String) -> Bool {
  if s.length() == 0 {
    return false
  }
  let mut has_digit = false
  for i = 0; i < s.length(); i = i + 1 {
    match s.get_char(i) {
      Some('-') if i == 0 => ()
      Some('.') => ()
      Some(c) if c >= '0' && c <= '9' => has_digit = true
      _ => return false
    }
  }
  has_digit
}

///|
/// Parse component call references in the structured block body markdown.
/// Returns Array[(comp_name, Array[(arg_key, arg_value_or_model_ref)])]
/// where arg_value_or_model_ref is the MoonBit expression string to use in generated code:
///   - `model.var` for bare identifiers matching model vars
///   - The literal value as-is for everything else
fn parse_body_component_refs(
  body_md : String,
  model_vars : Map[String, Bool],
) -> Array[(String, Array[(String, String)])] {
  let result : Array[(String, Array[(String, String)])] = []
  let len = body_md.length()
  let mut i = 0
  while i < len {
    // Find @ followed by name char
    let mut at_pos : Int? = None
    let mut scan = i
    while scan < len {
      if body_md.get_char(scan) is Some('@') &&
        scan + 1 < len &&
        is_name_char(body_md.get_char(scan + 1).unwrap_or(' ')) {
        at_pos = Some(scan)
        break
      }
      scan = scan + 1
    }
    match at_pos {
      None => break
      Some(at_pos) => {
        let after_at = at_pos + 1
        if after_at >= len {
          break
        }
        let mut name_end = after_at
        while name_end < len {
          match body_md.get_char(name_end) {
            Some(c) if is_name_char(c) => name_end = name_end + 1
            _ => break
          }
        }
        let comp_name = body_md[after_at:name_end].to_owned()
        // Skip whitespace to find (
        let mut paren_pos = name_end
        while paren_pos < len {
          match body_md.get_char(paren_pos) {
            Some(' ') | Some('\t') => paren_pos = paren_pos + 1
            Some('(') => break
            _ => {
              i = name_end
              break
            }
          }
        }
        // Check we found (
        let found_paren = paren_pos < len &&
          body_md.get_char(paren_pos) is Some('(')
        if !found_paren {
          i = name_end
          continue
        }
        // Find matching )
        match find_matching_paren(body_md, paren_pos) {
          None => {
            i = paren_pos + 1
            continue
          }
          Some(close_paren) => {
            let args_str = body_md[paren_pos + 1:close_paren].to_owned()
            let args = parse_component_args(args_str, model_vars)
            result.push((comp_name, args))
            i = close_paren + 1
          }
        }
      }
    }
  }
  result
}

///|
/// Parse component args string like `value=count, tone="info"` into key → expr pairs.
/// Values that are bare identifiers matching model vars get mapped to `model.<var>`.
fn parse_component_args(
  args_str : String,
  model_vars : Map[String, Bool],
) -> Array[(String, String)] {
  let result : Array[(String, String)] = []
  if args_str.trim() == "" {
    return result
  }
  let parts : Array[String] = []
  let mut seg_start = 0
  let mut in_string = false
  let mut depth_round = 0
  let mut i = 0
  while i < args_str.length() {
    let c = args_str.get_char(i)
    if in_string {
      if c is Some('"') {
        in_string = false
      }
      if c is Some('\\') {
        i = i + 1
      }
    } else {
      if c is Some('"') {
        in_string = true
      }
      if c is Some('(') {
        depth_round = depth_round + 1
      }
      if c is Some(')') {
        depth_round = depth_round - 1
      }
      if c is Some(',') && depth_round == 0 {
        parts.push(args_str[seg_start:i].trim().to_owned())
        seg_start = i + 1
      }
    }
    i = i + 1
  }
  if seg_start < args_str.length() {
    parts.push(args_str[seg_start:].trim().to_owned())
  }
  for i = 0; i < parts.length(); i = i + 1 {
    let part = parts[i]
    if part == "" {
      continue
    }
    match part.find("=") {
      Some(eq_pos) => {
        let key = part[0:eq_pos].trim().to_owned()
        let raw_val = part[eq_pos + 1:].trim().to_owned()
        if key == "" {
          continue
        }
        // Check if raw_val is a bare identifier matching a model var
        if model_vars.get(raw_val) is Some(_) {
          result.push((key, "model." + raw_val))
        } else {
          result.push((key, raw_val))
        }
      }
      None =>
        // Positional arg (no key)
        result.push(("_", part))
    }
  }
  result
}

///|
/// Check if a component source file has any callback parameters.
fn component_has_callback(comp_name : String, build_dir : String) -> Bool {
  let comp_mbt = "\{build_dir}/\{COMPONENTS_DIR}/\{comp_name}/\{comp_name}.mbt"
  guard @fs.path_exists(comp_mbt) else { return false }
  let content = @fs.read_file_to_string(comp_mbt) catch { _ => return false }
  content.contains("-> Unit")
}

///|
/// Build a map of component name → has_callback from scanning component sources.
fn build_callback_map(build_dir : String) -> Map[String, Bool] raise {
  let map : Map[String, Bool] = Map([])
  let comp_dir = "\{build_dir}/\{COMPONENTS_DIR}"
  guard @fs.path_exists(comp_dir) else { return map }
  let names = @fs.read_dir(comp_dir)
  for i = 0; i < names.length(); i = i + 1 {
    let name = names[i]
    if @fs.path_exists("\{comp_dir}/\{name}/moon.pkg") {
      if component_has_callback(name, build_dir) {
        map.set(name, true)
      }
    }
  }
  map
}

///|
/// Check if an args array contains a key "on_change".
fn args_has_onchange(args : Array[(String, String)]) -> Bool {
  for i = 0; i < args.length(); i = i + 1 {
    let (k, _) = args[i]
    if k == "on_change" {
      return true
    }
  }
  false
}

///|
/// Generate MoonBit source code for a composite cell.
/// Arguments:
///   comp_name: component name (e.g., "dashboard")
///   vars: Array of (var_name, type, initial_value) tuples from the model
///   body_md: raw body markdown text containing @component calls
///   comp_callbacks: Map of component_name → Bool (whether it has a callback param)
///   build_dir: build directory for reading component source files
fn generate_composite_cell(
  comp_name : String,
  vars : Array[(String, String, String)],
  body_md : String,
  comp_callbacks : Map[String, Bool],
) -> String {
  let caps_name = capitalize(comp_name)
  let msg_name = caps_name + "Msg"

  // Build model_vars for reference detection
  let model_vars : Map[String, Bool] = Map([])
  for vi = 0; vi < vars.length(); vi = vi + 1 {
    let (varname, _, _) = vars[vi]
    model_vars.set(varname, true)
  }

  // Parse component references from body
  let comp_refs = parse_body_component_refs(body_md, model_vars)

  if vars.length() == 0 {
    // No model variables — generate a static cell (no state to manage)
    let sb = StringBuilder::new()
    sb.write_string(
      "// Auto-generated composite cell for structured block \"" +
      comp_name +
      "\"\n\n",
    )
    sb.write_string("pub fn " + comp_name + "_cell() -> @rabbita.Cell {\n")
    sb.write_string("  @rabbita.static_cell(\n")
    if comp_refs.length() == 0 {
      sb.write_string("    @html.div([]),\n")
    } else {
      sb.write_string("    @html.div([\n")
      for ci = 0; ci < comp_refs.length(); ci = ci + 1 {
        let (comp_name_ref, args) = comp_refs[ci]
        sb.write_string("      @" + comp_name_ref + "." + comp_name_ref + "(\n")
        for ai = 0; ai < args.length(); ai = ai + 1 {
          let (key, expr) = args[ai]
          sb.write_string("        " + key + "=" + expr + ",\n")
        }
        sb.write_string("      ),\n")
      }
      sb.write_string("    ]),\n")
    }
    sb.write_string("  )\n")
    sb.write_string("}\n")
    return sb.to_string()
  }

  let sb = StringBuilder::new()
  sb.write_string(
    "// Auto-generated composite cell for structured block \"" +
    comp_name +
    "\"\n\n",
  )

  let model_name = caps_name + "Model"

  // Model struct
  sb.write_string("struct " + model_name + " {\n")
  for vi = 0; vi < vars.length(); vi = vi + 1 {
    let (varname, typ, _) = vars[vi]
    sb.write_string("  " + varname + " : " + typ + "\n")
  }
  sb.write_string("}\n\n")

  // Enum for messages
  sb.write_string("enum " + msg_name + " {\n")
  for vi = 0; vi < vars.length(); vi = vi + 1 {
    let (varname, typ, _) = vars[vi]
    sb.write_string("  Set" + capitalize(varname) + "(" + typ + ")\n")
  }
  sb.write_string("}\n\n")

  // Main cell function
  sb.write_string("pub fn " + comp_name + "_cell() -> @rabbita.Cell {\n")
  sb.write_string("  @rabbita.simple_cell(\n")

  // Model: use named struct
  sb.write_string("    model=" + model_name + "::{\n")
  for j = 0; j < vars.length(); j = j + 1 {
    let (varname, _, init_val) = vars[j]
    sb.write_string("      " + varname + ": " + init_val + ",\n")
  }
  sb.write_string("    },\n")

  // Update function
  sb.write_string("    update=fn(msg, model) {\n")
  sb.write_string("      match msg {\n")
  for vi = 0; vi < vars.length(); vi = vi + 1 {
    let (varname, _, _) = vars[vi]
    let setter = "Set" + capitalize(varname)
    sb.write_string(
      "        " + msg_name + "::" + setter + "(v) => " + model_name + "::{\n",
    )
    // Emit all fields, updating the matched one
    for k = 0; k < vars.length(); k = k + 1 {
      let (fv, _, _) = vars[k]
      if fv == varname {
        sb.write_string("          " + fv + ": v,\n")
      } else {
        sb.write_string("          " + fv + ": model." + fv + ",\n")
      }
    }
    sb.write_string("        }\n")
  }
  sb.write_string("      }\n")
  sb.write_string("    },\n")

  // View function
  sb.write_string("    view=fn(emit, model) {\n")
  if comp_refs.length() == 0 {
    sb.write_string("      let children : Array[@rabbita.Html] = []\n")
    sb.write_string("      @html.div(children)\n")
  } else {
    sb.write_string("      let children : Array[@rabbita.Html] = [\n")

    // Render each component reference
    for ci = 0; ci < comp_refs.length(); ci = ci + 1 {
      let (comp_name_ref, args) = comp_refs[ci]
      sb.write_string("        @" + comp_name_ref + "." + comp_name_ref + "(\n")
      for ai = 0; ai < args.length(); ai = ai + 1 {
        let (key, expr) = args[ai]
        sb.write_string("          " + key + "=" + expr + ",\n")
      }
      // Auto-wire callback if the component has one and no explicit on_change was already passed
      let has_onchange = args_has_onchange(args)
      if !has_onchange {
        match comp_callbacks.get(comp_name_ref) {
          Some(true) => {
            // Find a model var that was passed to this component
            // to auto-generate the callback wiring
            let mut wired = false
            for ai = 0; ai < args.length(); ai = ai + 1 {
              let (key, expr) = args[ai]
              ignore(key)
              if expr.has_prefix("model.") {
                let varname = expr[6:].to_owned()
                let msg_var = get_set_msg_for_var(vars, varname)
                match msg_var {
                  Some(msg_name) => {
                    sb.write_string(
                      "          on_change=fn(v) { let _ = emit(" +
                      msg_name +
                      "(v)) },\n",
                    )
                    wired = true
                    break
                  }
                  None => ()
                }
              }
            }
            ignore(wired)
          }
          _ => ()
        }
      }
      sb.write_string("        ),\n")
    }

    sb.write_string("      ]\n")
    sb.write_string("      @html.div(children)\n")
  }
  sb.write_string("    },\n")
  sb.write_string("  )\n")
  sb.write_string("}\n")
  sb.to_string()
}

///|
/// Given the vars array and a var name, find the matching SetXxx message name.
fn get_set_msg_for_var(
  vars : Array[(String, String, String)],
  target : String,
) -> String? {
  for vi = 0; vi < vars.length(); vi = vi + 1 {
    let (varname, _, _) = vars[vi]
    if varname == target {
      return Some("Set" + capitalize(varname))
    }
  }
  None
}

///|
/// Process all structured blocks in markdown content:
///   1. Extract structured blocks
///   2. Generate composite cell .mbt files in _moonblox/
///   3. Replace blocks with @name() in markdown
/// Returns (processed_md, Array[generated_comp_names])
fn process_structured_blocks(
  md : String,
  build_dir : String,
  comp_callbacks : Map[String, Bool],
) -> (String, Array[String]) {
  let blocks = extract_structured_blocks(md)
  if blocks.length() == 0 {
    return (md, [])
  }
  let generated : Array[String] = []
  // Process from end to start to preserve positions
  for i = blocks.length() - 1; i >= 0; i = i - 1 {
    let block = blocks[i]
    let vars = parse_model_to_vars(block.model_raw)
    let source = generate_composite_cell(
      block.name,
      vars,
      block.body_md,
      comp_callbacks,
    )
    let out_path = "\{build_dir}/\{block.name}_structured.mbt"
    @fs.write_string_to_file(out_path, source) catch {
      _ => {
        println(
          "Warning: failed to write structured block cell '" + block.name + "'",
        )
        continue
      }
    }
    println("Generated: \{block.name}_structured.mbt")
    generated.push(block.name)
  }
  // Build the processed markdown (forward pass for simplicity)
  // Since we processed in reverse, rebuild the md by reading original and replacing
  let md_result = build_processed_md(md, blocks)
  (md_result, generated)
}

///|
/// Replace structured blocks in the original markdown with @name() calls.
fn build_processed_md(
  md : String,
  blocks : Array[StructuredBlockInfo],
) -> String {
  if blocks.length() == 0 {
    return md
  }
  let sb = StringBuilder::new()
  let mut last_end = 0
  for i = 0; i < blocks.length(); i = i + 1 {
    let b = blocks[i]
    // Copy text before the block
    sb.write_string(md[last_end:b.start_pos].to_owned())
    // Replace with @name()
    sb.write_string("@" + b.name + "()")
    last_end = b.end_pos
  }
  // Copy remaining text after last block
  if last_end < md.length() {
    sb.write_string(md[last_end:md.length()].to_owned())
  }
  sb.to_string()
}

///|
/// Add composite cell entries to the auto-generated registry.
/// Finds the inline_cells function's return statement and inserts entries before it.
fn add_structured_cells_to_registry(
  reg_path : String,
  comp_names : Array[String],
) -> Unit raise {
  let content = @fs.read_file_to_string(reg_path)
  let marker = "\n  m\n"
  match content.find(marker) {
    None => return
    Some(pos) => {
      // pos points to the '\n' before "  m\n"
      let sb = StringBuilder::new()
      sb.write_string(content[0:pos].to_owned())
      for i = 0; i < comp_names.length(); i = i + 1 {
        let cname = comp_names[i]
        sb.write_string(
          "\n  m.set(\"" + cname + "\", fn(args) { " + cname + "_cell() })",
        )
      }
      sb.write_string(marker)
      sb.write_string(content[pos + marker.length():].to_owned())
      @fs.write_string_to_file(reg_path, sb.to_string())
      println(
        "Registry: added " +
        comp_names.length().to_string() +
        " structured cell(s)",
      )
    }
  }
}

///|
/// Strip non-digit characters from a date string for numeric comparison.
/// E.g., "2024-01-15" -> "20240115", "Jan 2024" -> "2024"
fn date_to_sortable(d : String) -> String {
  let result = StringBuilder::new()
  for i = 0; i < d.length(); i = i + 1 {
    match d.get_char(i) {
      Some(c) if c >= '0' && c <= '9' => result.write_char(c)
      _ => ()
    }
  }
  result.to_string()
}

///|
/// moonblox build — generate temp project in _moonblox/, compile, assemble output
pub async fn build(dir : String, dev_mode? : Bool = false) -> Bool {
  guard @fs.path_exists(dir) else {
    println("Error: directory not found: \{dir}")
    return false
  }

  let config = read_config(dir)
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
  copy_components(dir, build_dir, config.components)
  copy_theme(dir, build_dir)

  // Generate root moon.pkg (shared, no is-main)
  generate_root_moon_pkg(build_dir)

  // Scan components, generate shared _registry.mbt at root
  scan_components("\{build_dir}/\{COMPONENTS_DIR}", build_dir)

  // Build callback map for structured block processing
  let comp_callbacks = build_callback_map(build_dir)
  let all_generated_comps : Array[String] = []

  // Per-page generation: collect front matter for list page
  let posts : Array[PostMeta] = []
  let posts_dir = "\{dir}/\{config.input}"
  if @fs.path_exists(posts_dir) {
    let files = @fs.read_dir(posts_dir)
    for i = 0; i < files.length(); i = i + 1 {
      let name = files[i]
      if name.has_suffix(".md") {
        try {
          let content = @fs.read_file_to_string("\{posts_dir}/\{name}")
          let slug = slug_from_filename(name)
          // Process structured blocks before markdown → AST pipeline
          let (processed_content, generated_comps) = process_structured_blocks(
            content, build_dir, comp_callbacks,
          )
          for comp_name in generated_comps {
            let mut already_have = false
            for k = 0; k < all_generated_comps.length(); k = k + 1 {
              if all_generated_comps[k] == comp_name {
                already_have = true
                break
              }
            }
            if !already_have {
              all_generated_comps.push(comp_name)
            }
          }
          let page_dir = "\{build_dir}/\{PAGES_DIR}/\{slug}"
          try! ensure_dir(page_dir)
          generate_page_moon_pkg(build_dir, slug)
          @fs.write_string_to_file(
            "\{page_dir}/\{MAIN_MBT}",
            generate_main_mbt(processed_content),
          )
          println("Generated: pages/\{slug}/")
          let doc = @convert.parse_markdown(content)
          let meta = doc.meta
          posts.push(PostMeta::{
            slug,
            title: match meta.get("title") {
              Some(t) => t
              None => slug
            },
            date: match meta.get("date") {
              Some(d) => d
              None => ""
            },
            tags: match meta.get("tags") {
              Some(t) => t
              None => ""
            },
          })
        } catch {
          @fs.IOError(msg) => println("Warning: skipping '\{name}': \{msg}")
          _ => println("Warning: skipping '\{name}': unexpected error")
        }
      }
    }
  }

  // Sort posts by date descending for list page
  posts.sort_by(fn(a, b) {
    let da = date_to_sortable(a.date)
    let db = date_to_sortable(b.date)
    if da > db {
      -1
    } else if da < db {
      1
    } else {
      0
    }
  })

  // Generate list page through the render pipeline
  let list_slug = "_listing"
  let list_page_dir = "\{build_dir}/\{PAGES_DIR}/\{list_slug}"
  try! ensure_dir(list_page_dir)
  generate_page_moon_pkg(build_dir, list_slug)
  @fs.write_string_to_file(
    "\{list_page_dir}/\{MAIN_MBT}",
    generate_main_mbt(generate_list_page(posts)),
  )
  println("Generated: pages/\{list_slug}/")

  // Add composite cell entries to registry
  if all_generated_comps.length() > 0 {
    let reg_path = "\{build_dir}/\{REGISTRY_FILE}"
    add_structured_cells_to_registry(reg_path, all_generated_comps) catch {
      e => println("Warning: failed to update registry: \{e}")
    }
  }

  // Collect CSS: base.css + component .css files
  let css = collect_css(build_dir)

  // Run moon check first — catches type errors early
  let check_result = @process.run(
    "moon",
    ["check", "--target", "js"],
    cwd=build_dir,
  )
  guard check_result == 0 else {
    println("Error: moon check failed. Fix type errors before building.")
    return false
  }

  // Run moon build
  let moon_args = if dev_mode {
    println("Building JS (debug)...")
    ["build", "--target", "js"]
  } else {
    println("Building JS (release)...")
    ["build", "--target", "js", "--release"]
  }
  let result = @process.run("moon", moon_args, cwd=build_dir)
  guard result == 0 else {
    println("Error: moon build failed with exit code \{result}")
    return false
  }

  // --- Output Assembly ---
  let artifact_path = if dev_mode {
    BUILD_ARTIFACT_PATH_DEBUG
  } else {
    BUILD_ARTIFACT_PATH
  }
  let js_dir = "\{build_dir}/\{artifact_path}"

  if dev_mode {
    // Dev mode: write HTML/CSS directly into build output (skip JS copying, skip dist/)
    let output_dir = js_dir
    let pages_dir = "\{output_dir}/\{PAGES_DIR}"

    // Write per-page HTML shells alongside their JS files
    for i = 0; i < posts.length(); i = i + 1 {
      let slug = posts[i].slug
      let page_dir = "\{pages_dir}/\{slug}"
      try! ensure_dir(page_dir)
      let html = fill_template(
        page_shell,
        posts[i].title,
        slug,
        build_meta_tags(posts[i]),
      ).replace_all(old="../style.css", new="../../style.css")
      @fs.write_string_to_file("\{page_dir}/\{INDEX_HTML}", html)
    }

    // Write list page HTML
    let list_page_dir = "\{pages_dir}/_listing"
    try! ensure_dir(list_page_dir)
    let list_html = fill_template(page_shell, "Articles", "index", "").replace_all(
      old="../style.css",
      new="../../style.css",
    )
    @fs.write_string_to_file("\{list_page_dir}/\{INDEX_HTML}", list_html)

    // Copy _listing.js → index.js for list page (dev mode)
    let list_js_src = "\{js_dir}/\{PAGES_DIR}/_listing/_listing.js"
    if @fs.path_exists(list_js_src) {
      @fs.write_string_to_file(
        "\{output_dir}/index.js",
        @fs.read_file_to_string(list_js_src),
      )
    }

    // Write CSS to build output root
    if css != "" {
      @fs.write_string_to_file("\{output_dir}/\{STYLE_CSS}", css) catch {
        @fs.IOError(msg) =>
          println("Warning: failed to write style.css: \{msg}")
      }
    }

    println("Built (dev): \{output_dir}/")
  } else {
    // Production: assemble dist/
    let dist_dir = "\{dir}/\{config.output}"
    if @fs.path_exists(dist_dir) {
      remove_dir_all(dist_dir)
    }
    try! @fs.create_dir(dist_dir)

    // Copy per-page JS and generate HTML shells
    for i = 0; i < posts.length(); i = i + 1 {
      let slug = posts[i].slug
      let page_dist = "\{dist_dir}/\{slug}"
      try! ensure_dir(page_dist)
      // Copy JS
      let js_src = "\{js_dir}/\{PAGES_DIR}/\{slug}/\{slug}.js"
      if @fs.path_exists(js_src) {
        @fs.write_string_to_file(
          "\{page_dist}/\{slug}.js",
          @fs.read_file_to_string(js_src),
        )
        println("Copied: \{slug}.js -> dist/\{slug}/")
      }
      // Write page HTML shell with metadata
      let html = fill_template(
        page_shell,
        posts[i].title,
        slug,
        build_meta_tags(posts[i]),
      )
      @fs.write_string_to_file("\{page_dist}/\{INDEX_HTML}", html)
    }

    // Handle list page (slug "_listing") — copy JS and write HTML to dist root
    let list_js_src = "\{js_dir}/\{PAGES_DIR}/_listing/_listing.js"
    if @fs.path_exists(list_js_src) {
      @fs.write_string_to_file(
        "\{dist_dir}/index.js",
        @fs.read_file_to_string(list_js_src),
      )
      println("Copied: index.js -> dist/")
    }
    let list_html = fill_template(page_shell, "Articles", "index", "").replace_all(
      old="../style.css",
      new="style.css",
    )
    @fs.write_string_to_file("\{dist_dir}/\{INDEX_HTML}", list_html)

    if css != "" {
      @fs.write_string_to_file("\{dist_dir}/\{STYLE_CSS}", css) catch {
        @fs.IOError(msg) =>
          println("Warning: failed to write style.css: \{msg}")
      }
    }

    println("Built: \{dist_dir}/")
  }
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
/// Create directory if it doesn't already exist (idempotent).
fn ensure_dir(path : String) -> Unit raise {
  if !@fs.path_exists(path) {
    try! @fs.create_dir(path)
  }
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
  parts.push("  \"" + RABBITA_PACKAGE + "/html\",\n")

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
fn copy_components(
  src_root : String,
  build_dir : String,
  comp_dir : String,
) -> Unit raise {
  let src = "\{src_root}/\{comp_dir}"
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
        let fn_marker = "pub fn \{comp_name}("
        match content.find(fn_marker) {
          None => continue
          Some(_) => {
            // Detect container: check for "children : Array[@rabbita.Html]" in the source
            let is_container = content.contains(
              "children : Array[@rabbita.Html]",
            )
            // Detect interactive: check for "-> Unit" in the source (callback parameter)
            let has_callback = content.contains("-> Unit")

            if is_container {
              container_s.push(comp_name)
            } else {
              inline_s.push(comp_name)
            }
            generate_props_v2(
              mbt_path, out_dir, comp_name, has_callback, is_container,
            )
          }
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
      "  m.set(\"\{c}\", fn(args) { \{c}_cell(\{c}_props(args)) })\n",
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
      "  m.set(\"\{c}\", fn(args, children) { \{c}_cell(\{c}_props(args), children) })\n",
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
/// Find the index of the closing ) that matches the ( at position `start`.
fn find_matching_paren(text : String, start : Int) -> Int? {
  let len = text.length()
  if start >= len {
    return None
  }
  match text.get_char(start) {
    Some('(') => {
      let mut depth : Int = 0
      for i = start; i < len; i = i + 1 {
        match text.get_char(i) {
          Some('(') => depth = depth + 1
          Some(')') => {
            depth = depth - 1
            if depth == 0 {
              return Some(i)
            }
          }
          _ => ()
        }
      }
      None
    }
    _ => None
  }
}

///|
/// Parse the parameter portion of a function signature string into individual param strings.
fn parse_params(params_str : String) -> Array[String] {
  // Split by top-level commas (respecting nesting of (), [], {})
  let result : Array[String] = []
  let mut start = 0
  let mut depth_round = 0
  let mut depth_square = 0
  let mut depth_curly = 0
  for i = 0; i < params_str.length(); i = i + 1 {
    match params_str.get_char(i) {
      Some('(') => depth_round = depth_round + 1
      Some(')') => depth_round = depth_round - 1
      Some('[') => depth_square = depth_square + 1
      Some(']') => depth_square = depth_square - 1
      Some('{') => depth_curly = depth_curly + 1
      Some('}') => depth_curly = depth_curly - 1
      Some(c) if c == ',' &&
        depth_round == 0 &&
        depth_square == 0 &&
        depth_curly == 0 => {
        result.push(params_str[start:i].trim().to_owned())
        start = i + 1
      }
      _ => ()
    }
  }
  if start < params_str.length() {
    result.push(params_str[start:].trim().to_owned())
  }
  result
}

///|
/// Extract param name, type string, and default string from a single param declaration.
/// Returns (name, type_base, default_str) where default_str is "" if no default.
fn parse_param_decl(p : String) -> (String, String, String) {
  let trimmed = p.trim().to_owned()
  let eq_pos = trimmed.find("=")
  let (decl, default_str) = match eq_pos {
    Some(idx) => {
      let ds = trimmed[idx + 1:].trim().to_owned()
      (trimmed[0:idx].trim().to_owned(), ds)
    }
    None => (trimmed, "")
  }
  // Find the colon separating name from type
  match decl.find(":") {
    Some(colon) => {
      let name_part = decl[0:colon].trim().to_owned()
      let type_str = decl[colon + 1:].trim().to_owned()
      // Strip ~ and ? from name
      let name = name_part
        .replace_all(old="~", new="")
        .replace_all(old="?", new="")
        .trim()
        .to_owned()
      (name, type_str, default_str)
    }
    None => (decl, "String", default_str)
  }
}

///|
/// Generate _props.mbt from component function signature (v2: uses pub fn <name>(...))
fn generate_props_v2(
  mbt_path : String,
  out_dir : String,
  comp_name : String,
  has_callback : Bool,
  is_container : Bool,
) -> Unit raise {
  let content = @fs.read_file_to_string(mbt_path)
  let marker = "pub fn \{comp_name}("
  match content.find(marker) {
    None => return
    Some(idx) => {
      let paren_start = idx + marker.length() - 1 // position of '('
      match find_matching_paren(content, paren_start) {
        None => return
        Some(paren_end) => {
          let params_str = content[paren_start + 1:paren_end].trim().to_owned()
          write_props_v2(
            out_dir, comp_name, params_str, has_callback, is_container,
          )
        }
      }
    }
  }
}

///|
fn write_props_v2(
  out_dir : String,
  comp_name : String,
  params_str : String,
  has_callback : Bool,
  is_container : Bool,
) -> Unit raise {
  let props_name = capitalize(comp_name) + "Props"
  let sb = StringBuilder::new()
  sb.write_string("// Auto-generated by scanner — DO NOT EDIT\n\n")

  // Parse parameters
  let raw_params = parse_params(params_str)
  let prop_params : Array[(String, String, String)] = []

  for i = 0; i < raw_params.length(); i = i + 1 {
    let p = raw_params[i]
    if p != "" {
      let (name, type_str, default_str) = parse_param_decl(p)
      // Skip callback params (type contains -> Unit)
      if type_str.contains("-> Unit") {
        continue
      }
      // Skip container children param
      if name == "children" && type_str.contains("Array[@rabbita.Html]") {
        continue
      }
      prop_params.push((name, type_str, default_str))
    }
  }

  // Generate Props struct
  sb.write_string("pub(all) struct " + props_name + " {\n")
  for i = 0; i < prop_params.length(); i = i + 1 {
    let (name, type_str, _) = prop_params[i]
    sb.write_string("  " + name + " : " + type_str + "\n")
  }
  sb.write_string("}\n\n")

  // Generate Props::new() constructor
  sb.write_string("pub fn " + props_name + "::new(\n")
  for i = 0; i < prop_params.length(); i = i + 1 {
    let (name, type_str, default_str) = prop_params[i]
    sb.write_string("  " + name + "? : " + type_str)
    if default_str != "" {
      sb.write_string(" = " + default_str)
    }
    if i < prop_params.length() - 1 {
      sb.write_string(",\n")
    } else {
      sb.write_string(",\n")
    }
  }
  sb.write_string(") -> " + props_name + " {\n")
  sb.write_string("  { ")
  for i = 0; i < prop_params.length(); i = i + 1 {
    let (name, _, _) = prop_params[i]
    sb.write_string(name)
    if i < prop_params.length() - 1 {
      sb.write_string(", ")
    }
  }
  sb.write_string(" }\n}\n\n")

  // Generate _props adapter function
  sb.write_string(
    "pub fn " +
    comp_name +
    "_props(args : Map[String, @ast.Value]) -> " +
    props_name +
    " {\n",
  )
  sb.write_string("  " + props_name + "::new(\n")
  for i = 0; i < prop_params.length(); i = i + 1 {
    let (name, type_str, _) = prop_params[i]
    let type_base = if type_str.has_suffix("?") {
      type_str[0:type_str.length() - 1].trim().to_owned()
    } else {
      type_str
    }
    let (pat, body) = match type_base {
      "String" => ("@ast.Value::Str(s)", "s")
      "Double" => ("@ast.Value::Number(n)", "n")
      "Bool" => ("@ast.Value::Bool(b)", "b")
      _ => ("_", "None")
    }
    sb.write_string(
      "    " +
      name +
      "?=args.get(\"" +
      name +
      "\").bind(fn(v) { match v { " +
      pat +
      " => Some(" +
      body +
      "); _ => None } }),\n",
    )
  }
  sb.write_string("  )\n}\n\n")

  // Generate _cell wrapper
  if has_callback {
    // Interactive component — wrap in simple_cell
    let msg_name = capitalize(comp_name) + "Msg"
    sb.write_string("enum " + msg_name + " {\n")
    // Generate a simple SetValue-like message for each Double prop
    let has_value_prop = prop_params.length() > 0
    if has_value_prop {
      for i = 0; i < prop_params.length(); i = i + 1 {
        let (name, type_str, _) = prop_params[i]
        if type_str == "Double" {
          sb.write_string("  Set" + capitalize(name) + "(" + type_str + ")\n")
        }
      }
    }
    sb.write_string("}\n\n")

    sb.write_string(
      "pub fn " +
      comp_name +
      "_cell(props : " +
      props_name +
      ") -> @rabbita.Cell {\n",
    )
    sb.write_string("  @rabbita.simple_cell(\n")
    sb.write_string("    model=props,\n")
    // Build update function: match on each message variant
    sb.write_string("    update=fn(msg, model) {\n")
    sb.write_string("      match msg {\n")
    if has_value_prop {
      for i = 0; i < prop_params.length(); i = i + 1 {
        let (name, type_str, _) = prop_params[i]
        if type_str == "Double" {
          sb.write_string(
            "        Set" + capitalize(name) + "(n) => { " + name + ": n }\n",
          )
        }
      }
    }
    sb.write_string("      }\n")
    sb.write_string("    },\n")
    // Build view function: call component function with callbacks mapped to emit
    sb.write_string("    view=fn(emit, model) {\n")
    sb.write_string("      @" + comp_name + "." + comp_name + "(\n")
    // Pass all props 
    for i = 0; i < prop_params.length(); i = i + 1 {
      let (name, _, _) = prop_params[i]
      sb.write_string("        " + name + "=model." + name + ",\n")
    }
    // Find the first Double prop for callback emit naming
    let mut cb_val = ""
    for j = 0; j < prop_params.length(); j = j + 1 {
      let (n, t, _) = prop_params[j]
      if t == "Double" {
        cb_val = n
        break
      }
    }
    // Pass callback: on_change=fn(v) { let _ = emit(SetValue(v)) }
    if has_callback && cb_val != "" {
      sb.write_string(
        "        on_change=fn(v) { let _ = emit(Set" +
        capitalize(cb_val) +
        "(v)) },\n",
      )
    }
    sb.write_string("      )\n")
    sb.write_string("    },\n")
    sb.write_string("  )\n")
    sb.write_string("}\n")
  } else if is_container {
    // Container component — static cell wrapping component function with children
    sb.write_string("pub fn " + comp_name + "_cell(\n")
    sb.write_string("  props : " + props_name + ",\n")
    sb.write_string("  children : Array[@rabbita.Html],\n")
    sb.write_string(") -> @rabbita.Cell {\n")
    sb.write_string("  @rabbita.static_cell(\n")
    sb.write_string("    @" + comp_name + "." + comp_name + "(\n")
    sb.write_string("      children,\n")
    for i = 0; i < prop_params.length(); i = i + 1 {
      let (name, _, _) = prop_params[i]
      sb.write_string("      " + name + "=props." + name + ",\n")
    }
    sb.write_string("    ),\n")
    sb.write_string("  )\n")
    sb.write_string("}\n")
  } else {
    // Static inline component — static cell wrapping component function
    sb.write_string(
      "pub fn " +
      comp_name +
      "_cell(props : " +
      props_name +
      ") -> @rabbita.Cell {\n",
    )
    sb.write_string("  @rabbita.static_cell(\n")
    sb.write_string("    @" + comp_name + "." + comp_name + "(\n")
    for i = 0; i < prop_params.length(); i = i + 1 {
      let (name, _, _) = prop_params[i]
      sb.write_string("      " + name + "=props." + name + ",\n")
    }
    sb.write_string("    ),\n")
    sb.write_string("  )\n")
    sb.write_string("}\n")
  }

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
/// Generate markdown for the article list page
fn generate_list_page(posts : Array[PostMeta]) -> String {
  let sb = StringBuilder::new()
  sb.write_string("---\ntitle: Articles\n---\n\n")
  for i = 0; i < posts.length(); i = i + 1 {
    let p = posts[i]
    if p.date != "" {
      sb.write_string(
        "- **[" + p.title + "](./" + p.slug + "/)** — " + p.date + "\n",
      )
    } else {
      sb.write_string("- **[" + p.title + "](./" + p.slug + "/)**\n")
    }
  }
  sb.to_string()
}

// --- Template helpers ---

///|
/// Simple placeholder replacement: __TITLE__, __SLUG__, __META_TAGS__
fn fill_template(
  template : String,
  title : String,
  slug : String,
  meta_tags : String,
) -> String {
  template
  .replace_all(old="__TITLE__", new=title)
  .replace_all(old="__SLUG__", new=slug)
  .replace_all(old="__META_TAGS__", new=meta_tags)
}

///|
/// Build <meta> tag string from PostMeta for injection into page <head>
fn build_meta_tags(post : PostMeta) -> String {
  let sb = StringBuilder::new()
  if post.date != "" {
    sb.write_string("  <meta name=\"date\" content=\"\{post.date}\">\n")
  }
  if post.tags != "" {
    sb.write_string("  <meta name=\"keywords\" content=\"\{post.tags}\">\n")
  }
  sb.to_string()
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
/// Escape a string value for embedding as a MoonBit string literal.
fn escape_mb_string(s : String) -> String {
  let sb = StringBuilder::new()
  for i = 0; i < s.length(); i = i + 1 {
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
