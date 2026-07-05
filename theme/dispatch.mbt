// Theme dispatch — resolves theme name to concrete type and delegates trait calls.
// Dispatch lives here (same package as the trait, types, and impls) so MoonBit
// can resolve trait method calls correctly.

///|
pub enum ThemeKind {
  Blog(BlogTheme)
  Docs(DocsTheme)
}

///|
/// Resolve a theme name string to a ThemeKind.
pub fn resolve_theme(name : String) -> ThemeKind {
  match name {
    "blog" => ThemeKind::Blog(new_blog())
    "docs" => ThemeKind::Docs(new_docs())
    _ => ThemeKind::Blog(new_blog())
  }
}

///|
pub fn theme_content_root(theme : ThemeKind) -> String {
  match theme {
    Blog(t) => t.content_root()
    Docs(t) => t.content_root()
  }
}

///|
pub fn theme_discover_pages(
  theme : ThemeKind,
  content_dir : String,
) -> Array[PageEntry] {
  match theme {
    Blog(t) => t.discover_pages(content_dir)
    Docs(t) => t.discover_pages(content_dir)
  }
}

///|
pub fn theme_sort_pages(
  theme : ThemeKind,
  pages : Array[PageEntry],
) -> Array[PageEntry] {
  match theme {
    Blog(t) => t.sort_pages(pages)
    Docs(t) => t.sort_pages(pages)
  }
}

///|
pub fn theme_url_for(
  theme : ThemeKind,
  page : PageEntry,
  all_pages : Array[PageEntry],
) -> String {
  match theme {
    Blog(t) => t.url_for(page, all_pages)
    Docs(t) => t.url_for(page, all_pages)
  }
}

///|
pub fn theme_listing_page_title(theme : ThemeKind) -> String {
  match theme {
    Blog(t) => t.listing_page_title()
    Docs(t) => t.listing_page_title()
  }
}

///|
pub fn theme_generate_listing_markdown(
  theme : ThemeKind,
  pages : Array[PageEntry],
) -> String {
  match theme {
    Blog(t) => t.generate_listing_markdown(pages)
    Docs(t) => t.generate_listing_markdown(pages)
  }
}

///|
pub fn theme_generate_nav_html(
  theme : ThemeKind,
  pages : Array[PageEntry],
  current_slug : String,
) -> String {
  match theme {
    Blog(t) => Theme::generate_nav_html(t, pages, current_slug)
    Docs(t) => Theme::generate_nav_html(t, pages, current_slug)
  }
}

///|
pub fn theme_page_shell_template(theme : ThemeKind) -> String {
  match theme {
    Blog(t) => t.page_shell_template()
    Docs(t) => t.page_shell_template()
  }
}

///|
pub fn theme_base_css(theme : ThemeKind) -> String {
  match theme {
    Blog(t) => t.base_css()
    Docs(t) => t.base_css()
  }
}

///|
pub fn theme_component_dirs(theme : ThemeKind) -> Array[String] {
  match theme {
    Blog(t) => t.component_dirs()
    Docs(t) => t.component_dirs()
  }
}

///|
pub fn theme_build_meta_tags(theme : ThemeKind, page : PageEntry) -> String {
  match theme {
    Blog(t) => t.build_meta_tags(page)
    Docs(t) => t.build_meta_tags(page)
  }
}
