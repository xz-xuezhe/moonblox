/// MoonBlox scaffold — `moonblox init <dir>`

pub fn scaffold(dir : String) -> Unit {
  try do_scaffold(dir) catch {
    err => println("Error: \{err}")
  }
}

fn mkdir(path : String) -> Unit raise {
  println("  mkdir \{path}")
  try! @fs.create_dir(path)
}

fn write(dir : String, name : String, content : String) -> Unit raise {
  let path = "\{dir}/\{name}"
  println("  write \{path}")
  try! @fs.write_string_to_file(path, content)
}

fn do_scaffold(dir : String) -> Unit raise {
  mkdir(dir)
  mkdir("\{dir}/components")
  mkdir("\{dir}/posts")
  mkdir("\{dir}/theme")

  write(dir, "moonblox.json", "{\n  \"input\": \"posts\",\n  \"output\": \"dist\",\n  \"components\": \"./components\"\n}\n")
  write(dir, "posts/index.md", sample_content())
  write(dir, "theme/base.css", base_css)

  scaffold_component(dir, "badge", badge_mbt, badge_css)
  scaffold_component(dir, "counter", counter_mbt, counter_css)
  scaffold_component(dir, "callout", callout_mbt, callout_css)

  println("Created MoonBlox site at \{dir}/")
  println("  cd \{dir} && moonblox build")
}

fn scaffold_component(dir : String, name : String, mbt : String, css : String) -> Unit raise {
  let comp_dir = "\{dir}/components/\{name}"
  mkdir(comp_dir)
  write(comp_dir, "moon.pkg", component_moon_pkg())
  write(comp_dir, "\{name}.mbt", mbt)
  write(comp_dir, "\{name}.css", css)
}

fn component_moon_pkg() -> String {
  let s =
    #|import {
    #|  "xz-xuezhe/moonblox/ast",
    #|  "moonbit-community/rabbita",
    #|  "moonbit-community/rabbita/html",
    #|  "moonbit-community/rabbita/cmd",
    #|}
    #|
    #|supported_targets = "js+native"
  s
}

fn sample_content() -> String {
  let s =
    #|# Hello MoonBlox
    #|
    #|Welcome to your MoonBlox site! This is a @badge(text: "new", tone: "info") feature.
    #|
    #|Try the counter: @counter(initial: 0)
    #|
    #|:::callout(type: "note", title: "Tip")
    #|Add more `.md` files to `posts/` and components to `components/`.
    #|:::
  s
}