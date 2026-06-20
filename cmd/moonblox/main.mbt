///|
const DEFAULT_PORT : Int = 3000

///|
/// MoonBlox CLI — `moonblox <command> [args]`
async fn main {
  let args = @env.args()
  let cmd : Ref[String] = Ref("")
  let cmd_arg : Ref[String] = Ref("")
  let port : Ref[String] = Ref(DEFAULT_PORT.to_string())

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

  @ArgParser.parse(
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
  ) catch {
    _ => ()
  }

  match cmd.val {
    "init" => scaffold(cmd_arg.val)
    "build" => {
      let _ = build(cmd_arg.val)
    }
    "serve" => {
      let p = @string.parse_int(port.val) catch { _ => DEFAULT_PORT }
      let _ = serve(cmd_arg.val, p)
    }
    "" => println(usage)
    _ => {
      println("Unknown command: \{cmd.val}\n")
      println(usage)
    }
  }
}
