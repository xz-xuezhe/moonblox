// Docs theme for MoonBlox.
// Implements the documentation site content model: hierarchical directory structure,
// manual ordering via "order" front matter field, path-based URLs, sidebar navigation.

///|
struct DocsTheme {}

///|
/// Create a new DocsTheme instance.
pub fn new_docs() -> DocsTheme {
  DocsTheme::{  }
}

///|
impl Theme for DocsTheme with fn content_root(self) -> String {
  "docs"
}

///|
impl Theme for DocsTheme with fn discover_pages(self, content_dir : String) -> Array[
  PageEntry,
] {
  let entries : Array[PageEntry] = []
  if @fs.path_exists(content_dir) {
    let files = @fs.read_dir(content_dir) catch { _ => return entries }
    for i = 0; i < files.length(); i = i + 1 {
      let name = files[i]
      if name.has_suffix(".md") {
        let path = "\{content_dir}/\{name}"
        let raw = @fs.read_file_to_string(path) catch { _ => continue }
        let content = raw
        let meta : Map[String, String] = Map([])
        if raw.has_prefix("---") {
          let rest : StringView = raw[3:]
          match rest.find("---") {
            Some(i) => {
              let fm = rest[0:i].to_owned()
              for line_view in fm.split("\n") {
                let line = line_view.to_owned()
                let trimmed = line.trim().to_owned()
                if trimmed != "" && trimmed.contains(":") {
                  match trimmed.find(":") {
                    Some(colon_pos) => {
                      let key = trimmed[0:colon_pos].trim().to_owned()
                      let val_raw = trimmed[colon_pos + 1:].trim().to_owned()
                      let val_clean = if val_raw.has_prefix("\"") &&
                        val_raw.has_suffix("\"") {
                        val_raw[1:val_raw.length() - 1].to_owned()
                      } else if val_raw.has_prefix("'") &&
                        val_raw.has_suffix("'") {
                        val_raw[1:val_raw.length() - 1].to_owned()
                      } else {
                        val_raw
                      }
                      meta.set(key, val_clean)
                    }
                    None => ()
                  }
                }
              }
            }
            None => ()
          }
        }
        let slug = slug_from_filename(name)
        entries.push(PageEntry::{
          slug,
          source_path: name,
          metadata: meta,
          content,
        })
      }
    }
  }
  entries
}

///|
impl Theme for DocsTheme with fn sort_pages(self, pages : Array[PageEntry]) -> Array[
  PageEntry,
] {
  pages.sort_by(fn(a : PageEntry, b : PageEntry) -> Int {
    let order_a = parse_order(a.metadata.get("order").unwrap_or("999"))
    let order_b = parse_order(b.metadata.get("order").unwrap_or("999"))
    if order_a < order_b {
      -1
    } else if order_a > order_b {
      1
    } else {
      let title_a = a.metadata.get("title").unwrap_or(a.slug)
      let title_b = b.metadata.get("title").unwrap_or(b.slug)
      title_a.compare(title_b)
    }
  })
  pages
}

///|
fn parse_order(s : String) -> Double {
  @string.parse_double(s) catch {
    _ => 999.0
  }
}

///|
impl Theme for DocsTheme with fn url_for(
  self,
  page : PageEntry,
  _all_pages : Array[PageEntry],
) -> String {
  if page.slug == "index" {
    "/"
  } else {
    "/\{page.slug}/"
  }
}

///|
impl Theme for DocsTheme with fn listing_page_title(self) -> String {
  "Documentation"
}

///|
impl Theme for DocsTheme with fn generate_listing_markdown(
  self,
  pages : Array[PageEntry],
) -> String {
  let sb = StringBuilder::new()
  sb.write_string("---\ntitle: Documentation\n---\n\n")
  sb.write_string("Welcome to the documentation.\n\n")
  for i = 0; i < pages.length(); i = i + 1 {
    let page = pages[i]
    let title = page.metadata.get("title").unwrap_or(page.slug)
    sb.write_string("[" + title + "](./" + page.slug + "/)\n\n")
  }
  sb.to_string()
}

///|
impl Theme for DocsTheme with fn page_shell_template(self) -> String {
  (
    #|<!DOCTYPE html>
    #|<html lang="en">
    #|<head>
    #|  <meta charset="UTF-8">
    #|  <meta name="viewport" content="width=device-width, initial-scale=1.0">
    #|  <meta name="generator" content="MoonBlox">
    #|  <title>__TITLE__</title>
    #|  __META_TAGS__
    #|  <link rel="stylesheet" href="../style.css">
    #|</head>
    #|<body>
    #|  <div class="docs-layout">
    #|    <aside class="docs-sidebar">
    #|      <nav id="sidebar-nav"></nav>
    #|    </aside>
    #|    <main class="docs-content">
    #|      <div id="app"></div>
    #|    </main>
    #|  </div>
    #|  <script src="__SLUG__.js" type="module"></script>
    #|</body>
    #|</html>
    #|
  )
}

///|
impl Theme for DocsTheme with fn base_css(self) -> String {
  (
    #|* {
    #|  margin: 0;
    #|  padding: 0;
    #|  box-sizing: border-box;
    #|}
    #|
    #|body {
    #|  font-family: system-ui, sans-serif;
    #|  line-height: 1.6;
    #|}
    #|
    #|.docs-layout {
    #|  display: flex;
    #|  min-height: 100vh;
    #|}
    #|
    #|.docs-sidebar {
    #|  width: 260px;
    #|  flex-shrink: 0;
    #|  border-right: 1px solid #e2e8f0;
    #|  padding: 1.5rem;
    #|  overflow-y: auto;
    #|  position: sticky;
    #|  top: 0;
    #|  height: 100vh;
    #|}
    #|
    #|.docs-content {
    #|  flex: 1;
    #|  max-width: 800px;
    #|  padding: 2rem 3rem;
    #|}
    #|
    #|.docs-content h1 {
    #|  font-size: 2rem;
    #|  margin-bottom: 1rem;
    #|}
    #|
    #|.docs-content h2 {
    #|  font-size: 1.5rem;
    #|  margin-top: 2rem;
    #|  margin-bottom: 0.75rem;
    #|}
    #|
    #|.docs-content h3 {
    #|  font-size: 1.25rem;
    #|  margin-top: 1.5rem;
    #|  margin-bottom: 0.5rem;
    #|}
    #|
    #|pre {
    #|  background: #f5f5f5;
    #|  padding: 1rem;
    #|  border-radius: 4px;
    #|  overflow-x: auto;
    #|  margin: 1rem 0;
    #|}
    #|
    #|code {
    #|  background: #f0f0f0;
    #|  padding: 0.2em 0.4em;
    #|  border-radius: 3px;
    #|  font-size: 0.9em;
    #|}
    #|
    #|pre code {
    #|  background: none;
    #|  padding: 0;
    #|}
    #|
  )
}

///|
impl Theme for DocsTheme with fn component_dirs(self) -> Array[String] {
  [
    "badge", "callout", "card", "grid", "metric", "sidebar", "breadcrumbs", "prev_next",
  ]
}

///|
impl Theme for DocsTheme with fn build_meta_tags(self, page : PageEntry) -> String {
  let sb = StringBuilder::new()
  let description = page.metadata.get("description").unwrap_or("")
  if description != "" {
    sb.write_string(
      "  <meta name=\"description\" content=\"\{description}\">\n",
    )
  }
  sb.to_string()
}
