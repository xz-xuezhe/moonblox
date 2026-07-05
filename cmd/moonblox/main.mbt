///|
const DEFAULT_PORT : Int = 3000

///|
/// MoonBlox CLI — `moonblox-cli <command> [args]`
async fn main {
  let parser = @clap.Parser::new(
    prog="moonblox-cli",
    description="Markdown-first programmable site generator",
    subcmds={
      "init": @clap.SubCommand::new(
        args={
          "dir": @clap.Arg::positional(defaults=[""], help="Project directory"),
          "headless": @clap.Arg::flag(
            short='H',
            help="Skip interactive TUI (CI mode)",
          ),
          "theme": @clap.Arg::named(
            short='t',
            defaults=["blog"],
            help="Project theme: blog or docs",
          ),
          "empty": @clap.Arg::flag(
            short='E',
            help="Skip generating sample content",
          ),
          "quiet": @clap.Arg::flag(
            short='q',
            help="Suppress non-essential output",
          ),
        },
        help="Scaffold a new MoonBlox project (pass --headless for CI)",
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
          let headless = cmd.get_flag("headless") == Some(true)
          let theme = cmd.get_one("theme") catch { _ => "blog" }
          let empty = cmd.get_flag("empty") == Some(true)
          let quiet = cmd.get_flag("quiet") == Some(true)

          if headless {
            if dir == "" || dir == "." {
              println(
                "Error: --headless requires a project directory. Use: moonblox-cli init <dir> --headless",
              )
            } else {
              scaffold(dir, theme~, components=[], empty~, quiet~)
            }
          } else {
            let default_dir = if dir == "" || dir == "." { "" } else { dir }
            match init_tui(default_dir~) {
              Some(name) => {
                println("Created MoonBlox site at \{name}/")
                println("  cd \{name} && moonblox-cli serve")
              }
              None =>
                // TUI failed (non-TTY or error) — fall back to direct scaffold if dir provided
                if dir != "" && dir != "." {
                  scaffold(
                    dir,
                    theme="blog",
                    components=[],
                    empty=false,
                    quiet=false,
                  )
                  println("Created MoonBlox site at \{dir}/")
                  println("  cd \{dir} && moonblox-cli serve")
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
