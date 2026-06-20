///|
/// MoonBlox scaffold — `moonblox init <dir>`
pub fn scaffold(dir : String) -> Unit {
  do_scaffold(dir) catch {
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
fn do_scaffold(dir : String) -> Unit raise {
  mkdir(dir)
  mkdir("\{dir}/\{COMPONENTS_DIR}")
  mkdir("\{dir}/\{POSTS_DIR}")
  mkdir("\{dir}/\{THEME_DIR}")

  write(dir, "moonblox.json", default_config_json)
  write(dir, "\{POSTS_DIR}/index.md", sample_post_md)
  write(dir, "\{THEME_DIR}/base.css", base_css)

  scaffold_component(dir, "badge", badge_mbt, badge_css, badge_moon_pkg)
  scaffold_component(dir, "counter", counter_mbt, counter_css, counter_moon_pkg)
  scaffold_component(dir, "callout", callout_mbt, callout_css, callout_moon_pkg)

  println("Created MoonBlox site at \{dir}/")
  println("  cd \{dir} && moonblox build")
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
