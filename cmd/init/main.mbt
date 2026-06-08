/// MoonBlox scaffold CLI — `moonblox init <dir>`

fn main raise {
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
  scaffold(dir)
}

fn scaffold(dir : String) -> Unit raise {
  @fs.create_dir(dir)
  @fs.create_dir("\{dir}/theme")
  @fs.create_dir("\{dir}/components")
  @fs.create_dir("\{dir}/posts")
  @fs.create_dir("\{dir}/cmd/interactive")

  write_moon_mod(dir)
  write_main(dir)
  write_config(dir)
  write_interactive(dir)

  let templates = "../../lib/templates"
  let css = @fs.read_file_to_string("\{templates}/theme/style.css")
  @fs.write_string_to_file("\{dir}/theme/style.css", css)
  let page = @fs.read_file_to_string("\{templates}/theme/page.html")
  @fs.write_string_to_file("\{dir}/theme/page.html", page)

  copy_template(dir, templates, "badge")
  copy_template(dir, templates, "callout")
  copy_template(dir, templates, "slider")
  copy_template(dir, templates, "chart")
  copy_template(dir, templates, "metric")

  write_sample(dir)

  println("Created MoonBlox site at \{dir}/")
  println("  cd \{dir} && moon run main")
}

fn write_moon_mod(dir : String) -> Unit raise {
  let sb = StringBuilder::new()
  sb.write_string("name = \"user/moonblox-site\"\n")
  sb.write_string("version = \"0.1.0\"\n\n")
  sb.write_string("import {\n  \"xz-xuezhe/moonblox\",\n}\n\n")
  sb.write_string("options(\n")
  sb.write_string("  \"pre-build\": [\n")
  sb.write_string("    {\n")
  sb.write_string("      \"command\": \"moon -C cmd/interactive build --target js --release\",\n")
  sb.write_string("      \"input\": \"\",\n")
  sb.write_string("      \"output\": \"dist/components/components.js\",\n")
  sb.write_string("    },\n")
  sb.write_string("  ],\n")
  sb.write_string(")\n")
  @fs.write_string_to_file("\{dir}/moon.mod", sb.to_string())
}

fn write_main(dir : String) -> Unit raise {
  let sb = StringBuilder::new()
  sb.write_string("fn main raise {\n")
  sb.write_string("  @moonblox.build(config_path=\"moonblox.json\")\n")
  sb.write_string("}\n")
  @fs.write_string_to_file("\{dir}/main.mbt", sb.to_string())
}

fn write_config(dir : String) -> Unit raise {
  let sb = StringBuilder::new()
  sb.write_string("{\n")
  sb.write_string("  \"input\": \"posts\",\n")
  sb.write_string("  \"output\": \"dist\",\n")
  sb.write_string("  \"theme\": \"theme\",\n")
  sb.write_string("  \"components\": \"components\"\n")
  sb.write_string("}\n")
  @fs.write_string_to_file("\{dir}/moonblox.json", sb.to_string())
}

fn write_interactive(dir : String) -> Unit raise {
  let int_dir = "\{dir}/cmd/interactive"
  let sb = StringBuilder::new()
  sb.write_string("{\"name\":\"interactive\",\"version\":\"0.1.0\",")
  sb.write_string("\"deps\":{\"moonbit-community/rabbita\":\"0.12.4\"},")
  sb.write_string("\"source\":\".\"}")
  @fs.write_string_to_file("\{int_dir}/moon.mod.json", sb.to_string())
  let sb2 = StringBuilder::new()
  sb2.write_string("import {\n")
  sb2.write_string("  \"moonbit-community/rabbita\",\n")
  sb2.write_string("  \"moonbit-community/rabbita/html\",\n")
  sb2.write_string("  \"moonbit-community/rabbita/cmd\",\n")
  sb2.write_string("}\n\n")
  sb2.write_string("supported_targets = \"js\"\n")
  sb2.write_string("options(\n  \"is-main\": true,\n)\n")
  @fs.write_string_to_file("\{int_dir}/moon.pkg", sb2.to_string())
  let sb3 = StringBuilder::new()
  sb3.write_string("fn main {\n")
  sb3.write_string("  let html = @rabbita.static_cell(@html.div([]))\n")
  sb3.write_string("  @rabbita.new(html).mount(\"interactive-root\")\n")
  sb3.write_string("}\n")
  @fs.write_string_to_file("\{int_dir}/main.mbt", sb3.to_string())
}

fn copy_template(dir : String, templates : String, name : String) -> Unit raise {
  let src = "\{templates}/components/\{name}.mbt"
  let dst = "\{dir}/components/\{name}.mbt"
  let content = @fs.read_file_to_string(src)
  @fs.write_string_to_file(dst, content)
}

fn write_sample(dir : String) -> Unit raise {
  let sb = StringBuilder::new()
  sb.write_string("# Hello MoonBlox\n\n")
  sb.write_string("Welcome to your MoonBlox site! ")
  sb.write_string("This is a @badge(text: \"new\", tone: \"info\") feature.\n\n")
  sb.write_string("Try the interactive demo: @slider(param: \"reward\", value: 0.5)\n\n")
  sb.write_string(":::callout(type: \"note\", title: \"Tip\")\n")
  sb.write_string("Add more `.md` files to `posts/` and components to `components/`.\n")
  sb.write_string(":::\n")
  @fs.write_string_to_file("\{dir}/posts/index.md", sb.to_string())
}
