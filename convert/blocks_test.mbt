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

///|
test "parse_markdown: table basic" {
  let doc = parse_markdown("| A | B |\n|---|---|\n| 1 | 2 |")
  assert_eq(doc.children.length(), 1)
  match doc.children[0] {
    @ast.Block::Table(t) => {
      assert_eq(t.header.length(), 2)
      assert_eq(t.rows.length(), 1)
      assert_eq(t.rows[0].length(), 2)
    }
    _ => assert_eq("expected Table", "")
  }
}

///|
test "parse_markdown: table with alignment" {
  let doc = parse_markdown(
    "| Left | Center | Right |\n|:---|:---:|---:|\n| a | b | c |",
  )
  assert_eq(doc.children.length(), 1)
  match doc.children[0] {
    @ast.Block::Table(t) => assert_eq(t.alignments.length(), 3)
    _ => assert_eq("expected Table", "")
  }
}

///|
test "parse_markdown: structured block inline" {
  let doc = parse_markdown("::section { count: 0 } @counter(value=count) ::")
  assert_eq(doc.children.length(), 1)
  match doc.children[0] {
    @ast.Block::ContainerComponent(cc) => {
      assert_eq(cc.name, "section")
      // Check that args contains the model variable
      match cc.args.get("count") {
        Some(_) => () // Value was parsed
        None => assert_eq("expected count in args", "")
      }
    }
    _ => assert_eq("expected ContainerComponent", "")
  }
}

///|
test "parse_markdown: structured block multiline supp" {
  let doc = parse_markdown("::wrapper { value: 5 }\n@counter(value=value)\n::")
  assert_eq(doc.children.length(), 1)
  match doc.children[0] {
    @ast.Block::ContainerComponent(cc) => assert_eq(cc.name, "wrapper")
    _ => assert_eq("expected ContainerComponent", "")
  }
}

///|
test "parse_markdown: footnote definition rendered" {
  let doc = parse_markdown("text[^1]\n\n[^1]: footnote content")
  // Footnote definition should be converted to a visible paragraph, not dropped
  assert_eq(doc.children.length() >= 2, true)
}

///|
test "parse_markdown: footnote reference preserved" {
  // The inline footnote reference [^1] should not be dropped
  let doc = parse_markdown("text[^1]")
  assert_eq(doc.children.length(), 1)
}

///|
test "parse_markdown: raw html preserved" {
  let doc = parse_markdown("<div>hello</div>")
  // Raw HTML should be preserved as a paragraph, not dropped
  assert_eq(doc.children.length() >= 1, true)
}

///|
test "parse_markdown: html with attributes" {
  let doc = parse_markdown("<span class=\"foo\">text</span>")
  assert_eq(doc.children.length() >= 1, true)
}
