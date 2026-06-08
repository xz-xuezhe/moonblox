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

  write(dir, "moon.mod.json", moon_mod_content())
  write(dir, "moon.pkg", moon_pkg_content())
  write(dir, "index.html", index_html)
  write(dir, "style.css", css_template)
  write(dir, "moonblox.json", config_content())
  write(dir, "posts/index.md", sample_content())

  // Components in sub-package
  write(dir, "components/moon.pkg", components_moon_pkg())
  write(dir, "components/badge.mbt", badge_template)
  write(dir, "components/callout.mbt", callout_template)
  write(dir, "components/counter.mbt", counter_template)

  println("Created MoonBlox site at \{dir}/")
  println("  cd \{dir} && moonblox build")
  println("  moon build --target js --release")
}

fn moon_mod_content() -> String {
  let sb = StringBuilder::new()
  sb.write_string("{\n")
  sb.write_string("  \"name\": \"user/moonblox-site\",\n")
  sb.write_string("  \"version\": \"0.1.0\",\n")
  sb.write_string("  \"preferred-target\": \"js\",\n")
  sb.write_string("  \"deps\": {\n")
  sb.write_string("    \"xz-xuezhe/moonblox\": {\n")
  sb.write_string("      \"path\": \"/Users/xuezhe/Fun/MoonMark\"\n")
  sb.write_string("    },\n")
  sb.write_string("    \"moonbit-community/rabbita\": \"0.12.4\",\n")
  sb.write_string("    \"mizchi/markdown\": \"0.6.2\"\n")
  sb.write_string("  }\n")
  sb.write_string("}\n")
  sb.to_string()
}

fn moon_pkg_content() -> String {
  let sb = StringBuilder::new()
  sb.write_string("import {\n")
  sb.write_string("  \"xz-xuezhe/moonblox/ast\",\n")
  sb.write_string("  \"xz-xuezhe/moonblox/convert\",\n")
  sb.write_string("  \"xz-xuezhe/moonblox/render\",\n")
  sb.write_string("  \"moonbit-community/rabbita\",\n")
  sb.write_string("  \"user/moonblox-site/components\",\n")
  sb.write_string("}\n\n")
  sb.write_string("supported_targets = \"js\"\n")
  sb.write_string("options(\n  \"is-main\": true,\n)\n")
  sb.to_string()
}

fn components_moon_pkg() -> String {
  let sb = StringBuilder::new()
  sb.write_string("import {\n")
  sb.write_string("  \"xz-xuezhe/moonblox/ast\",\n")
  sb.write_string("  \"moonbit-community/rabbita\",\n")
  sb.write_string("  \"moonbit-community/rabbita/html\",\n")
  sb.write_string("  \"moonbit-community/rabbita/cmd\",\n")
  sb.write_string("}\n\n")
  sb.write_string("supported_targets = \"js+native\"\n")
  sb.to_string()
}

fn config_content() -> String {
  "{\n  \"input\": \"posts\",\n  \"output\": \"dist\",\n  \"components\": \"./components\"\n}\n"
}

fn sample_content() -> String {
  let sb = StringBuilder::new()
  sb.write_string("# Hello MoonBlox\n\n")
  sb.write_string("Welcome to your MoonBlox site! ")
  sb.write_string("This is a @badge(text: \"new\", tone: \"info\") feature.\n\n")
  sb.write_string("Try the counter: @counter(initial: 0)\n\n")
  sb.write_string(":::callout(type: \"note\", title: \"Tip\")\n")
  sb.write_string("Add more `.md` files to `posts/` and components to `components/`.\n")
  sb.write_string(":::\n")
  sb.to_string()
}
