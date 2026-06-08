/// MoonBlox scaffold CLI — `moonblox init <dir>`

fn main {
  let args = @env.args()
  guard args.length() >= 2 else {
    println("Usage: moonblox init <directory>")
    return
  }
  let cmd = args[1]
  guard cmd == "init" else {
    println("Unknown command: \{cmd}")
    println("Usage: moonblox init <directory>")
    return
  }
  guard args.length() >= 3 else {
    println("Usage: moonblox init <directory>")
    return
  }
  let dir = args[2]
  try scaffold(dir) catch {
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

fn scaffold(dir : String) -> Unit raise {
  mkdir(dir)
  mkdir("\{dir}/components")
  mkdir("\{dir}/posts")
  mkdir("\{dir}/theme")

  write(dir, "moon.mod.json", moon_mod_content())
  write(dir, "moon.pkg", moon_pkg_content())
  write(dir, "index.html", index_html)
  write(dir, "moonblox.json", config_content())
  write(dir, "posts/index.md", sample_content())
  write(dir, "theme/base.css", base_css)

  // Components as directories
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

fn moon_mod_content() -> String {
  let s =
    #|{
    #|  "name": "user/moonblox-site",
    #|  "version": "0.1.0",
    #|  "preferred-target": "js",
    #|  "deps": {
    #|    "xz-xuezhe/moonblox": {
    #|      "path": "/Users/xuezhe/Fun/MoonMark"
    #|    },
    #|    "moonbit-community/rabbita": "0.12.4",
    #|    "mizchi/markdown": "0.6.2"
    #|  }
    #|}
  s
}

fn moon_pkg_content() -> String {
  let s =
    #|import {
    #|  "xz-xuezhe/moonblox/ast",
    #|  "xz-xuezhe/moonblox/convert",
    #|  "xz-xuezhe/moonblox/render",
    #|  "moonbit-community/rabbita",
    #|  "user/moonblox-site/components/badge",
    #|  "user/moonblox-site/components/counter",
    #|  "user/moonblox-site/components/callout",
    #|}

    #|supported_targets = "js"
    #|options(
    #|  "is-main": true,
    #|)
  s
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

fn config_content() -> String {
  let s =
    #|{
    #|  "input": "posts",
    #|  "output": "dist",
    #|  "components": "./components"
    #|}
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
