// Blog theme for MoonBlox.
// Implements the classic blog content model: flat posts directory,
// date-based reverse-chronological sorting, slug URLs, article listing page.

///|
struct BlogTheme {}

///|
/// Create a new BlogTheme instance.
pub fn new_blog() -> BlogTheme {
  BlogTheme::{  }
}

///|
impl Theme for BlogTheme with fn content_root(self) -> String {
  "posts"
}

///|
impl Theme for BlogTheme with fn discover_pages(self, content_dir : String) -> Array[
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
        let mut content = raw
        let meta : Map[String, String] = Map([])
        if raw.has_prefix("---") {
          let rest : StringView = raw[3:]
          match rest.find("---") {
            Some(i) => {
              let fm = rest[0:i].to_owned()
              content = rest[i + 3:].trim_start().to_owned()
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
                      let val_final = if val_clean.has_prefix("[") &&
                        val_clean.has_suffix("]") {
                        val_clean[1:val_clean.length() - 1].to_owned()
                      } else {
                        val_clean
                      }
                      meta.set(key, val_final)
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
impl Theme for BlogTheme with fn sort_pages(self, pages : Array[PageEntry]) -> Array[
  PageEntry,
] {
  pages.sort_by(fn(a : PageEntry, b : PageEntry) -> Int {
    let da = date_to_sortable(a.metadata.get("date").unwrap_or(""))
    let db = date_to_sortable(b.metadata.get("date").unwrap_or(""))
    if da > db {
      -1
    } else if da < db {
      1
    } else {
      0
    }
  })
  pages
}

///|
impl Theme for BlogTheme with fn url_for(
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
impl Theme for BlogTheme with fn listing_page_title(self) -> String {
  "Articles"
}

///|
impl Theme for BlogTheme with fn generate_listing_markdown(
  self,
  pages : Array[PageEntry],
) -> String {
  let sb = StringBuilder::new()
  sb.write_string("---\ntitle: Articles\n---\n\n")
  for i = 0; i < pages.length(); i = i + 1 {
    let page = pages[i]
    let date_str = page.metadata.get("date").unwrap_or("")
    let title = page.metadata.get("title").unwrap_or(page.slug)
    if date_str != "" {
      sb.write_string(
        "- **[" + title + "](./" + page.slug + "/)** — " + date_str + "\n",
      )
    } else {
      sb.write_string("- **[" + title + "](./" + page.slug + "/)**\n")
    }
  }
  sb.to_string()
}

///|
impl Theme for BlogTheme with fn page_shell_template(self) -> String {
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
    #|  <div id="app"></div>
    #|  <script src="__SLUG__.js" type="module"></script>
    #|</body>
    #|</html>
    #|
  )
}

///|
impl Theme for BlogTheme with fn base_css(self) -> String {
  (
    #|body {
    #|  font-family: system-ui, sans-serif;
    #|  max-width: 800px;
    #|  margin: 0 auto;
    #|  padding: 2rem;
    #|  line-height: 1.6;
    #|}
    #|
    #|pre {
    #|  background: #f5f5f5;
    #|  padding: 1rem;
    #|  border-radius: 4px;
    #|  overflow-x: auto;
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
impl Theme for BlogTheme with fn component_dirs(self) -> Array[String] {
  ["badge", "counter", "callout", "card", "grid", "metric", "chart", "graph"]
}

///|
impl Theme for BlogTheme with fn build_meta_tags(self, page : PageEntry) -> String {
  let sb = StringBuilder::new()
  let date = page.metadata.get("date").unwrap_or("")
  if date != "" {
    sb.write_string("  <meta name=\"date\" content=\"\{date}\">\n")
  }
  let tags = page.metadata.get("tags").unwrap_or("")
  if tags != "" {
    sb.write_string("  <meta name=\"keywords\" content=\"\{tags}\">\n")
  }
  sb.to_string()
}
