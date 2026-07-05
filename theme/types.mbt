// MoonBlox theme trait — the contract between build engine and themes.
// A theme controls content model, navigation, URL scheme, page chrome, and styling.

///|
/// A content page discovered by the theme from the content directory.
pub(all) struct PageEntry {
  /// Unique identifier for the page, derived from the source filename
  pub slug : String
  /// Path relative to the content root directory (e.g., "hello.md", "guide/getting-started.md")
  pub source_path : String
  /// Front matter metadata as key-value string pairs
  pub metadata : Map[String, String]
  /// Raw markdown content
  pub content : String
}

///|
/// A node in the navigation tree (sidebar, breadcrumbs, etc.)
pub struct NavNode {
  title : String
  url : String
  children : Array[NavNode]
  order : Double
}

///|
/// A Theme controls the content model, navigation, URL scheme,
/// and visual presentation of a MoonBlox site.
/// 
/// Implement this trait to create a new theme type (blog, docs, landing, etc.).
/// The build engine calls these methods at build time to discover content,
/// generate pages, and assemble the output site.
pub(open) trait Theme {
  /// The name of the content root directory (e.g., "posts", "docs")
  fn content_root(Self) -> String

  /// Discover all pages from the content directory.
  /// Reads .md files, extracts front matter, returns PageEntry array.
  fn discover_pages(Self, content_dir : String) -> Array[PageEntry]

  /// Sort pages according to the theme's ordering discipline.
  /// Blog themes typically sort by date descending; docs themes by explicit order.
  fn sort_pages(Self, pages : Array[PageEntry]) -> Array[PageEntry]

  /// Generate the URL path for a page (e.g., "/posts/my-post/", "/docs/guide/install/")
  fn url_for(Self, page : PageEntry, all_pages : Array[PageEntry]) -> String

  /// Title for the listing/index page (used as HTML title and page heading).
  fn listing_page_title(Self) -> String

  /// Generate markdown content for the listing/index page.
  /// The returned markdown string will be processed and rendered like any other page.
  /// Return an empty string "" if this theme has no listing page.
  fn generate_listing_markdown(Self, pages : Array[PageEntry]) -> String

  /// The HTML page shell template.
  /// Must contain the placeholders: __TITLE__, __META_TAGS__, __SLUG__
  fn page_shell_template(Self) -> String

  /// Base CSS stylesheet for the theme.
  fn base_css(Self) -> String

  /// Names of component directories belonging to this theme.
  /// Each dir should contain moon.pkg, *.mbt, and optional *.css.
  fn component_dirs(Self) -> Array[String]

  /// Generate HTML for sidebar/breadcrumb navigation.
  /// `current_slug` identifies the active page (for highlighting).
  /// Return empty string if the theme has no navigation.
  generate_nav_html(Self, pages : Array[PageEntry], current_slug : String) -> String

  /// Generate HTML meta tags from page metadata (e.g., date, keywords, description).
  fn build_meta_tags(Self, page : PageEntry) -> String
}

///|
/// Escape HTML special characters to prevent XSS in attribute values.
pub fn html_escape(s : String) -> String {
  let sb = StringBuilder::new()
  for i = 0; i < s.length(); i = i + 1 {
    match s.get_char(i) {
      Some('&') => sb.write_string("&amp;")
      Some('"') => sb.write_string("&quot;")
      Some('<') => sb.write_string("&lt;")
      Some('>') => sb.write_string("&gt;")
      Some('\'') => sb.write_string("&#39;")
      Some(c) => sb.write_char(c)
      None => ()
    }
  }
  sb.to_string()
}

///|
/// Extract slug from a markdown filename (strip .md suffix).
pub fn slug_from_filename(filename : String) -> String {
  if filename.has_suffix(".md") {
    filename[0:filename.length() - 3].to_owned()
  } else {
    filename
  }
}
