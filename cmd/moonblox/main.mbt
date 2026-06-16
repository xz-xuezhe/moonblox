///|
/// MoonBlox CLI — `moonblox <command> [args]`
async fn main {
  let args = @env.args()
  let cmd : Ref[String] = Ref("")
  let cmd_arg : Ref[String] = Ref("")
  let port : Ref[String] = Ref("3000")

  let usage =
    #| MoonBlox — Markdown-first programmable site generator
    #|
    #| Usage: moonblox <command> [args]
    #|
    #| Commands:
    #|   init  <dir>    Scaffold a new MoonBlox project
    #|   build <dir>    Build a static site to dist/
    #|   serve <dir>    Start dev server with live reload
    #|

  let options = [
    ("--port", "-p", @ArgParser.Set_string(port), "server port (default: 3000)"),
  ]

  let _ = try? @ArgParser.parse(
    options,
    fn(arg) {
      // Skip program name (args[0])
      if arg == args[0] {
        ()
      } else if cmd.val == "" {
        cmd.val = arg
      } else if cmd_arg.val == "" {
        cmd_arg.val = arg
      }
    },
    usage,
    args,
  )

  match cmd.val {
    "init" => scaffold(cmd_arg.val)
    "build" => {
      let _ = build(cmd_arg.val)
    }
    "serve" => {
      let p = @string.parse_int(port.val) catch { _ => 3000 }
      let _ = serve(cmd_arg.val, p)
    }
    "" => println(usage)
    _ => {
      println("Unknown command: \{cmd.val}\n")
      println(usage)
    }
  }
}
