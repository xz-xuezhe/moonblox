/// MoonMark scaffold CLI — `moonmark init <dir>`

fn main raise {
  let args = @env.args()
  guard args.length() >= 2 else {
    println("Usage: moonmark init <directory>")
    return
  }
  let cmd = args[1]
  guard cmd == "init" else {
    println("Unknown command: \{cmd}")
    println("Usage: moonmark init <directory>")
    return
  }
  guard args.length() >= 3 else {
    println("Usage: moonmark init <directory>")
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

  write_moon_mod(dir)
  write_main(dir)
  write_config(dir)

  let templates = "../../lib/templates"
  let css = @fs.read_file_to_string("\{templates}/theme/style.css")
  @fs.write_string_to_file("\{dir}/theme/style.css", css)
  let page = @fs.read_file_to_string("\{templates}/theme/page.html")
  @fs.write_string_to_file("\{dir}/theme/page.html", page)

  copy_template(dir, templates, "badge")
  copy_template(dir, templates, "callout")

  write_sample(dir)

  println("Created MoonMark site at \{dir}/")
  println("  cd \{dir} && moon run main")
}

fn write_moon_mod(dir : String) -> Unit raise {
  let sb = StringBuilder::new()
  sb.write_string("name = \"user/moonmark-site\"\n")
  sb.write_string("version = \"0.1.0\"\n\n")
  sb.write_string("import {\n  \"xz-xuezhe/moonmark\",\n}\n")
  @fs.write_string_to_file("\{dir}/moon.mod", sb.to_string())
}

fn write_main(dir : String) -> Unit raise {
  let sb = StringBuilder::new()
  sb.write_string("fn main raise {\n")
  sb.write_string("  @moonmark.build(config_path=\"moonmark.json\")\n")
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
  @fs.write_string_to_file("\{dir}/moonmark.json", sb.to_string())
}

fn copy_template(dir : String, templates : String, name : String) -> Unit raise {
  let src = "\{templates}/components/\{name}.mbt"
  let dst = "\{dir}/components/\{name}.mbt"
  let content = @fs.read_file_to_string(src)
  @fs.write_string_to_file(dst, content)
}

fn write_sample(dir : String) -> Unit raise {
  let sb = StringBuilder::new()
  sb.write_string("# Hello MoonMark\n\n")
  sb.write_string("Welcome to your MoonMark site! ")
  sb.write_string("This is a @badge(text: \"new\", tone: \"info\") feature.\n\n")
  sb.write_string(":::callout(type: \"note\", title: \"Tip\")\n")
  sb.write_string("Add more `.md` files to `posts/` and components to `components/`.\n")
  sb.write_string(":::\n")
  @fs.write_string_to_file("\{dir}/posts/index.md", sb.to_string())
}
