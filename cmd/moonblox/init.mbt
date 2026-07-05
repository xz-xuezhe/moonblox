///|
/// MoonBlox scaffold — `moonblox init <dir>`
pub fn scaffold(
  dir : String,
  theme? : String = "blog",
  components? : Array[String] = [],
) -> Unit {
  let comps = if components.length() == 0 {
    all_component_names()
  } else {
    components
  }
  do_scaffold(dir, theme, comps) catch {
    err => println("Error: \{err}")
  }
}

///|
fn mkdir(path : String) -> Unit raise {
  println("  mkdir \{path}")
  if @fs.path_exists(path) {
    if @fs.is_dir(path) {
      return // already exists as a directory — idempotent
    }
    raise @fs.IOError("Path exists and is not a directory: \{path}")
  }
  @fs.create_dir(path)
}

///|
fn write(dir : String, name : String, content : String) -> Unit raise {
  let path = "\{dir}/\{name}"
  println("  write \{path}")
  @fs.write_string_to_file(path, content) // propagates error to caller (do_scaffold)
}

///|

///|
/// Return today's date as "YYYY-MM-DD" using Howard Hinnant's civil_from_days algorithm.
fn today() -> String {
  let ms = @env.now()
  let days : Int = (ms / 86400000UL).to_int()
  let z = days + 719468
  let era = z / 146097
  let doe = z - era * 146097
  let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365
  let y = yoe + era * 400
  let doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
  let mp = (5 * doy + 2) / 153
  let d = doy - (153 * mp + 2) / 5 + 1
  let m = mp + (if mp < 10 { 3 } else { -9 })
  let y = if m <= 2 { y + 1 } else { y }
  let month = m.to_string().pad_start(2, '0')
  let day = d.to_string().pad_start(2, '0')
  "\{y}-\{month}-\{day}"
}

///|
fn do_scaffold(
  dir : String,
  theme : String,
  components : Array[String],
) -> Unit raise {
  let docs_config =
    #|{
    #|  "input": "docs",
    #|  "output": "dist",
    #|  "components": "./components",
    #|  "theme": "docs"
    #|}
  let config_json = if theme == "docs" {
    docs_config
  } else {
    default_config_json
  }
  let content_dir = if theme == "docs" { "docs" } else { "posts" }

  mkdir(dir)
  mkdir("\{dir}/\{COMPONENTS_DIR}")
  mkdir("\{dir}/\{content_dir}")
  mkdir("\{dir}/\{THEME_DIR}")

  write(dir, "moonblox.json", config_json)
  let date = today()
  let post = sample_post_md.replace(old="__DATE__", new=date)
  write(dir, "\{content_dir}/hello.md", post)
  write(dir, "\{THEME_DIR}/base.css", base_css)

  for i = 0; i < components.length(); i = i + 1 {
    let name = components[i]
    match name {
      "badge" =>
        scaffold_component(dir, "badge", badge_mbt, badge_css, badge_moon_pkg)
      "counter" =>
        scaffold_component(
          dir, "counter", counter_mbt, counter_css, counter_moon_pkg,
        )
      "callout" =>
        scaffold_component(
          dir, "callout", callout_mbt, callout_css, callout_moon_pkg,
        )
      "card" =>
        scaffold_component(dir, "card", card_mbt, card_css, card_moon_pkg)
      "grid" =>
        scaffold_component(dir, "grid", grid_mbt, grid_css, grid_moon_pkg)
      "metric" =>
        scaffold_component(
          dir, "metric", metric_mbt, metric_css, metric_moon_pkg,
        )
      "chart" =>
        scaffold_component(dir, "chart", chart_mbt, chart_css, chart_moon_pkg)
      "graph" =>
        scaffold_component(dir, "graph", graph_mbt, graph_css, graph_moon_pkg)
      "sidebar" =>
        scaffold_component(
          dir, "sidebar", sidebar_mbt, sidebar_css, sidebar_moon_pkg,
        )
      "breadcrumbs" =>
        scaffold_component(
          dir, "breadcrumbs", breadcrumbs_mbt, breadcrumbs_css, breadcrumbs_moon_pkg,
        )
      "prev_next" =>
        scaffold_component(
          dir, "prev_next", prev_next_mbt, prev_next_css, prev_next_moon_pkg,
        )
      _ => println("  (skip unknown component: \{name})")
    }
  }

  println("Created MoonBlox site at \{dir}/")
  if theme == "docs" {
    println("  cd \{dir}/docs && moonblox build")
  } else {
    println("  cd \{dir}/posts && moonblox build")
  }
}

///|
fn scaffold_component(
  dir : String,
  name : String,
  mbt : String,
  css : String,
  moon_pkg : String,
) -> Unit raise {
  let comp_dir = "\{dir}/\{COMPONENTS_DIR}/\{name}"
  mkdir(comp_dir)
  write(comp_dir, "moon.pkg", moon_pkg)
  write(comp_dir, "\{name}.mbt", mbt)
  write(comp_dir, "\{name}.css", css)
}
