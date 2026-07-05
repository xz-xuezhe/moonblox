///|
const DEFAULT_PORT : Int = 3000

///|
/// MoonBlox CLI — `moonblox <command> [args]`
async fn main {
  let parser = @clap.Parser::new(
    prog="moonblox",
    description="Markdown-first programmable site generator",
    subcmds={
      "init": @clap.SubCommand::new(
        args={
          "dir": @clap.Arg::positional(defaults=[""], help="Project directory"),
        },
        help="Scaffold a new MoonBlox project",
      ),
      "build": @clap.SubCommand::new(
        args={
          "dir": @clap.Arg::positional(defaults=["."], help="Project directory"),
        },
        help="Build a static site to dist/",
      ),
      "serve": @clap.SubCommand::new(
        args={
          "dir": @clap.Arg::positional(defaults=["."], help="Project directory"),
          "port": @clap.Arg::named(
            short='p',
            defaults=["3000"],
            help="Server port (default: 3000)",
          ),
        },
        help="Start dev server with live reload",
      ),
    },
  )

  let value = @clap.SimpleValue::new(parser.prog)
  let help = parser.parse(value, @env.args()[1:]) catch {
    _ => {
      println("Error parsing arguments")
      return
    }
  }
  match help {
    Some(msg) => {
      println(msg)
      return
    }
    None => ()
  }

  match value.subcmd {
    Some(cmd) =>
      match cmd.name {
        "init" => {
          let dir = if cmd.positional_args.length() > 0 {
            cmd.positional_args[0]
          } else {
            ""
          }
          let default_dir = if dir == "" || dir == "." { "" } else { dir }
          match init_tui(default_dir=default_dir) {
            Some(name) => {
              println("Created MoonBlox site at \{name}/")
              println("  cd \{name} && moonblox serve")
            }
            None => {
              // TUI failed (non-TTY or error) — fall back to direct scaffold if dir provided
              if dir != "" && dir != "." {
                scaffold(dir, theme="blog")
                println("Created MoonBlox site at \{dir}/")
                println("  cd \{dir} && moonblox serve")
              }
            }
          }
        }
        "build" => {
          let dir = if cmd.positional_args.length() > 0 {
            cmd.positional_args[0]
          } else {
            "."
          }
          let _ = build(dir)
        }
        "serve" => {
          let dir = if cmd.positional_args.length() > 0 {
            cmd.positional_args[0]
          } else {
            "."
          }
          let port_str = cmd.get_one("port") catch { _ => "3000" }
          let p = @string.parse_int(port_str) catch { _ => DEFAULT_PORT }
          let _ = serve(dir, p)
        }
        _ => println("Unknown command: \{cmd.name}")
      }
    None => {
      let help_msg = parser.gen_help_message([parser.prog], {})
      println(help_msg)
    }
  }
}
