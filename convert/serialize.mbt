// Serialize inline AST back to Markdown text.
// Used by container block detection to reconstruct ::: header/closer.

///|
fn inline_to_markdown(inlines : Array[@ast.Inline]) -> String {
  let sb = StringBuilder::new()
  for i = 0; i < inlines.length(); i = i + 1 {
    match inlines[i] {
      @ast.Inline::Markdown(md) => sb.write_string(inline_to_md(md))
      @ast.Inline::Component(name, args) => {
        sb.write_char('@')
        sb.write_string(name)
        sb.write_string(args_to_md(args))
      }
    }
  }
  sb.to_string()
}

///|
pub fn inline_to_md(inline : @markdown.Inline) -> String {
  match inline {
    @markdown.Inline::Text(content~, ..) => content
    @markdown.Inline::Code(content~, ..) => {
      let s = StringBuilder::new()
      s.write_char('`')
      s.write_string(content)
      s.write_char('`')
      s.to_string()
    }
    @markdown.Inline::Emphasis(children~, ..) => {
      let s = StringBuilder::new()
      s.write_char('*')
      for i = 0; i < children.length(); i = i + 1 {
        s.write_string(inline_to_md(children[i]))
      }
      s.write_char('*')
      s.to_string()
    }
    @markdown.Inline::Strong(children~, ..) => {
      let s = StringBuilder::new()
      s.write_string("**")
      for i = 0; i < children.length(); i = i + 1 {
        s.write_string(inline_to_md(children[i]))
      }
      s.write_string("**")
      s.to_string()
    }
    @markdown.Inline::Strikethrough(children~, ..) => {
      let s = StringBuilder::new()
      s.write_string("~~")
      for i = 0; i < children.length(); i = i + 1 {
        s.write_string(inline_to_md(children[i]))
      }
      s.write_string("~~")
      s.to_string()
    }
    @markdown.Inline::Link(children~, url~, ..) => {
      let s = StringBuilder::new()
      s.write_char('[')
      for i = 0; i < children.length(); i = i + 1 {
        s.write_string(inline_to_md(children[i]))
      }
      s.write_string("](")
      s.write_string(url)
      s.write_char(')')
      s.to_string()
    }
    @markdown.Inline::Image(alt~, url~, ..) => {
      let s = StringBuilder::new()
      s.write_string("![")
      s.write_string(alt)
      s.write_string("](")
      s.write_string(url)
      s.write_char(')')
      s.to_string()
    }
    @markdown.Inline::SoftBreak(..) | @markdown.Inline::HardBreak(..) => "\n"
    @markdown.Inline::Autolink(url~, ..) => url
    @markdown.Inline::HtmlInline(html~, ..) => html
    @markdown.Inline::WikiLink(target~, ..) => target
    @markdown.Inline::RefLink(children~, ..) => {
      let s = StringBuilder::new()
      for i = 0; i < children.length(); i = i + 1 {
        s.write_string(inline_to_md(children[i]))
      }
      s.to_string()
    }
    @markdown.Inline::RefImage(..) => ""
    @markdown.Inline::FootnoteReference(..) => ""
  }
}

///|
fn args_to_md(args : Map[String, @ast.Value]) -> String {
  let sb = StringBuilder::new()
  sb.write_char('(')
  let keys = args.keys().to_array()
  for i = 0; i < keys.length(); i = i + 1 {
    if i > 0 {
      sb.write_string(", ")
    }
    let k = keys[i]
    sb.write_string(k)
    sb.write_string(": ")
    match args[k] {
      @ast.Value::Str(s) => {
        sb.write_char('"')
        sb.write_string(s)
        sb.write_char('"')
      }
      @ast.Value::Number(n) => sb.write_string(n.to_string())
      @ast.Value::Bool(b) =>
        if b {
          sb.write_string("true")
        } else {
          sb.write_string("false")
        }
      @ast.Value::Funcall(name, fn_args) => {
        sb.write_string(name)
        sb.write_string(args_to_md(fn_args))
      }
      _ => sb.write_string("...")
    }
  }
  sb.write_char(')')
  sb.to_string()
}

///|
fn split_lines(s : String) -> Array[String] {
  let result : Array[String] = []
  let len = s.length()
  let mut start = 0
  for i = 0; i < len; i = i + 1 {
    match s.get_char(i) {
      Some('\n') => {
        result.push(s[start:i].to_owned())
        start = i + 1
      }
      _ => ()
    }
  }
  if start <= len {
    result.push(s[start:len].to_owned())
  }
  result
}

///|
fn join_lines(lines : Array[String]) -> String {
  let sb = StringBuilder::new()
  for i = 0; i < lines.length(); i = i + 1 {
    if i > 0 {
      sb.write_char('\n')
    }
    sb.write_string(lines[i])
  }
  sb.to_string()
}
