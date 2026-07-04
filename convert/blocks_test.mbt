///|
test "parse_markdown: empty" {
  let doc = parse_markdown("")
  assert_eq(doc.children.length(), 0)
  assert_eq(doc.meta.length(), 0)
}

///|
test "parse_markdown: paragraph" {
  let doc = parse_markdown("Hello world")
  assert_eq(doc.children.length(), 1)
  match doc.children[0] {
    @ast.Block::Paragraph(p) => assert_eq(p.children.length() > 0, true)
    _ => assert_eq("expected Paragraph", "")
  }
}

///|
test "parse_markdown: heading level 1" {
  let doc = parse_markdown("# Hello")
  assert_eq(doc.children.length(), 1)
  match doc.children[0] {
    @ast.Block::Heading(h) => {
      assert_eq(h.level, 1)
      assert_eq(h.children.length(), 1)
    }
    _ => assert_eq("expected Heading", "")
  }
}

///|
test "parse_markdown: heading level 2" {
  let doc = parse_markdown("## World")
  match doc.children[0] {
    @ast.Block::Heading(h) => assert_eq(h.level, 2)
    _ => assert_eq("expected Heading", "")
  }
}

///|
test "parse_markdown: code block" {
  let doc = parse_markdown("```\ncode\n```")
  assert_eq(doc.children.length(), 1)
  match doc.children[0] {
    @ast.Block::CodeBlock(cb) => assert_eq(cb.content, "code\n")
    _ => assert_eq("expected CodeBlock", "")
  }
}

///|
test "parse_markdown: code block with info" {
  let doc = parse_markdown("```python\ncode\n```")
  match doc.children[0] {
    @ast.Block::CodeBlock(cb) => {
      assert_eq(cb.info is Some("python"), true)
      assert_eq(cb.content, "code\n")
    }
    _ => assert_eq("expected CodeBlock", "")
  }
}

///|
test "parse_markdown: thematic break" {
  let doc = parse_markdown("---")
  match doc.children[0] {
    @ast.Block::ThematicBreak => ()
    _ => assert_eq("expected ThematicBreak", "")
  }
}

///|
test "parse_markdown: inline component" {
  let doc = parse_markdown("@btn(text: \"click\")")
  // Inline component in a paragraph
  match doc.children[0] {
    @ast.Block::Paragraph(p) =>
      match p.children[0] {
        @ast.Inline::Component(name, _) => assert_eq(name, "btn")
        _ => assert_eq("expected Component", "")
      }
    _ => assert_eq("expected Paragraph", "")
  }
}

///|
test "parse_markdown: container" {
  let doc = parse_markdown(":::callout(type: \"note\")\nbody\n:::")
  match doc.children[0] {
    @ast.Block::ContainerComponent(cc) => assert_eq(cc.name, "callout")
    _ => assert_eq("expected ContainerComponent", "")
  }
}

///|
test "parse_markdown: frontmatter" {
  let doc = parse_markdown("---\ntitle: Hello\ndate: 2024-01-01\n---\ncontent")
  assert_eq(doc.meta.length(), 2)
  assert_eq(doc.meta["title"], "Hello")
  assert_eq(doc.meta["date"], "2024-01-01")
}

///|
test "parse_markdown: list" {
  let doc = parse_markdown("- item1\n- item2")
  match doc.children[0] {
    @ast.Block::List(lst) => assert_eq(lst.items.length(), 2)
    _ => assert_eq("expected List", "")
  }
}

///|
test "parse_markdown: blockquote" {
  let doc = parse_markdown("> quoted text")
  match doc.children[0] {
    @ast.Block::BlockQuote(_) => ()
    _ => assert_eq("expected BlockQuote", "")
  }
}

///|
test "parse_markdown: structured block with shared state" {
  // ::section { count: 0 } @counter(value=count) ::
  //   → ContainerComponent with shared state variables and body content
  let doc = parse_markdown("::section { count: 0 } @counter(value=count) ::")
  assert_eq(doc.children.length(), 1)
  match doc.children[0] {
    @ast.Block::ContainerComponent(cc) => {
      assert_eq(cc.name, "section")
      match cc.args["count"] {
        @ast.Value::Number(n) => assert_eq(n, 0.0)
        _ => assert_eq("expected Number in count", "")
      }
    }
    _ => assert_eq("expected ContainerComponent", "")
  }
}

///|
test "parse_markdown: structured block multiline" {
  // ::wrapper { value: 5 }
  // @counter(value=value)
  // ::
  let md = "::wrapper { value: 5 }\n@counter(value=value)\n::"
  let doc = parse_markdown(md)
  assert_eq(doc.children.length(), 1)
  match doc.children[0] {
    @ast.Block::ContainerComponent(cc) => {
      assert_eq(cc.name, "wrapper")
      match cc.args["value"] {
        @ast.Value::Number(n) => assert_eq(n, 5.0)
        _ => assert_eq("expected Number in value", "")
      }
    }
    _ => assert_eq("expected ContainerComponent", "")
  }
}
