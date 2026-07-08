// Serialize MoonBlox AST types into MoonBit source code expressions.
// Used at build time to pre-parse markdown and generate code that
// constructs the AST directly, skipping runtime parsing.

///|
/// Escape a string for embedding in a MoonBit string literal.
/// Handles \\, \", \n, \t, \r.
pub fn escape_string(s : String) -> String {
  let sb = StringBuilder::new()
  for i = 0; i < s.length(); i = i + 1 {
    let c = s.get_char(i).unwrap_or(' ')
    if c == '\\' {
      sb.write_string("\\\\")
    } else if c == '"' {
      sb.write_string("\\\"")
    } else if c == '\n' {
      sb.write_string("\\n")
    } else if c == '\t' {
      sb.write_string("\\t")
    } else if c == '\r' {
      sb.write_string("\\r")
    } else {
      sb.write_char(c)
    }
  }
  sb.to_string()
}

///|
/// Generate indentation string of 2*n spaces.
pub fn indent_str(n : Int) -> String {
  let sb = StringBuilder::new()
  for i = 0; i < n; i = i + 1 {
    sb.write_string("  ")
  }
  sb.to_string()
}

///|
/// Serialize a double value as a MoonBit double literal.
/// Ensures whole numbers get `.0` suffix.
pub fn double_to_string(n : Double) -> String {
  let s = n.to_string()
  if s.contains(".") || s.contains("e") || s.contains("E") {
    s
  } else {
    s + ".0"
  }
}

///|
/// Sort an array of strings (insertion sort for deterministic output).
fn sort_strings(arr : Array[String]) -> Array[String] {
  let n = arr.length()
  if n <= 1 {
    return arr
  }
  for i = 1; i < n; i = i + 1 {
    let key = arr[i]
    let mut j = i - 1
    while j >= 0 && arr[j] > key {
      arr[j + 1] = arr[j]
      j = j - 1
    }
    arr[j + 1] = key
  }
  arr
}

///|
/// Serialize a Value to a MoonBit expression.
pub fn serialize_value(v : @ast.Value, indent : Int) -> String {
  match v {
    @ast.Value::Str(s) => "@ast.Value::Str(\"" + escape_string(s) + "\")"
    @ast.Value::Number(n) => "@ast.Value::Number(" + double_to_string(n) + ")"
    @ast.Value::Bool(b) =>
      if b {
        "@ast.Value::Bool(true)"
      } else {
        "@ast.Value::Bool(false)"
      }
    @ast.Value::Var(name) => "@ast.Value::Var(\"" + escape_string(name) + "\")"
    @ast.Value::Array(arr) => serialize_value_array(arr, indent)
    @ast.Value::Record(m) => serialize_value_record(m, indent)
    @ast.Value::Funcall(name, args) =>
      "@ast.Value::Funcall(\"" +
      escape_string(name) +
      "\", " +
      serialize_value_map_inline(args) +
      ")"
  }
}

///|
fn serialize_value_array(arr : Array[@ast.Value], indent : Int) -> String {
  if arr.length() == 0 {
    return "@ast.Value::Array([])"
  }
  let sb = StringBuilder::new()
  sb.write_string("@ast.Value::Array([\n")
  for i = 0; i < arr.length(); i = i + 1 {
    sb.write_string(indent_str(indent + 1))
    sb.write_string(serialize_value(arr[i], indent + 1))
    sb.write_string(",\n")
  }
  sb.write_string(indent_str(indent))
  sb.write_string("])")
  sb.to_string()
}

///|
fn serialize_value_record(m : Map[String, @ast.Value], indent : Int) -> String {
  let keys = sort_strings(m.keys().to_array())
  if keys.length() == 0 {
    return "@ast.Value::Record(Map([]))"
  }
  let sb = StringBuilder::new()
  sb.write_string("@ast.Value::Record(Map([\n")
  for i = 0; i < keys.length(); i = i + 1 {
    let k = keys[i]
    sb.write_string(indent_str(indent + 1))
    sb.write_string("(\"")
    sb.write_string(escape_string(k))
    sb.write_string("\", ")
    sb.write_string(serialize_value(m[k], indent + 1))
    sb.write_string(")")
    sb.write_string(",\n")
  }
  sb.write_string(indent_str(indent))
  sb.write_string("]))")
  sb.to_string()
}

///|
/// Serialize a Map[String, Value] to a compact inline expression.
/// Used for Funcall args where inline is preferred.
fn serialize_value_map_inline(m : Map[String, @ast.Value]) -> String {
  let keys = sort_strings(m.keys().to_array())
  if keys.length() == 0 {
    return "Map([])"
  }
  let sb = StringBuilder::new()
  sb.write_string("Map([")
  for i = 0; i < keys.length(); i = i + 1 {
    let k = keys[i]
    sb.write_string("(\"")
    sb.write_string(escape_string(k))
    sb.write_string("\", ")
    sb.write_string(serialize_value_simple(m[k]))
    sb.write_string(")")
    if i < keys.length() - 1 {
      sb.write_string(", ")
    }
  }
  sb.write_string("])")
  sb.to_string()
}

///|
/// Serialize a Value in compact form (no newlines). Used for inline map values.
fn serialize_value_simple(v : @ast.Value) -> String {
  match v {
    @ast.Value::Str(s) => "@ast.Value::Str(\"" + escape_string(s) + "\")"
    @ast.Value::Number(n) => "@ast.Value::Number(" + double_to_string(n) + ")"
    @ast.Value::Bool(b) =>
      if b {
        "@ast.Value::Bool(true)"
      } else {
        "@ast.Value::Bool(false)"
      }
    @ast.Value::Var(name) => "@ast.Value::Var(\"" + escape_string(name) + "\")"
    @ast.Value::Array(arr) =>
      if arr.length() == 0 {
        "@ast.Value::Array([])"
      } else {
        let sb = StringBuilder::new()
        sb.write_string("@ast.Value::Array([")
        for i = 0; i < arr.length(); i = i + 1 {
          sb.write_string(serialize_value_simple(arr[i]))
          if i < arr.length() - 1 {
            sb.write_string(", ")
          }
        }
        sb.write_string("])")
        sb.to_string()
      }
    @ast.Value::Record(m) => serialize_record_simple(m)
    @ast.Value::Funcall(name, args) =>
      "@ast.Value::Funcall(\"" +
      escape_string(name) +
      "\", " +
      serialize_value_map_inline(args) +
      ")"
  }
}

///|
fn serialize_record_simple(m : Map[String, @ast.Value]) -> String {
  let keys = sort_strings(m.keys().to_array())
  if keys.length() == 0 {
    return "@ast.Value::Record(Map([]))"
  }
  let sb = StringBuilder::new()
  sb.write_string("@ast.Value::Record(Map([")
  for i = 0; i < keys.length(); i = i + 1 {
    let k = keys[i]
    sb.write_string("(\"")
    sb.write_string(escape_string(k))
    sb.write_string("\", ")
    sb.write_string(serialize_value_simple(m[k]))
    sb.write_string(")")
    if i < keys.length() - 1 {
      sb.write_string(", ")
    }
  }
  sb.write_string("]))")
  sb.to_string()
}

///|
/// Serialize a Map[String, Value] to a MoonBit expression.
pub fn serialize_value_map(
  m : Map[String, @ast.Value],
  _indent : Int,
) -> String {
  serialize_value_map_inline(m)
}

///|
/// Serialize a Map[String, String] to a MoonBit expression.
pub fn serialize_string_map(m : Map[String, String], _indent : Int) -> String {
  let keys = sort_strings(m.keys().to_array())
  if keys.length() == 0 {
    return "Map([])"
  }
  let sb = StringBuilder::new()
  sb.write_string("Map([")
  for i = 0; i < keys.length(); i = i + 1 {
    let k = keys[i]
    sb.write_string("(\"")
    sb.write_string(escape_string(k))
    sb.write_string("\", \"")
    sb.write_string(escape_string(m[k]))
    sb.write_string("\")")
    if i < keys.length() - 1 {
      sb.write_string(", ")
    }
  }
  sb.write_string("])")
  sb.to_string()
}

///|
/// Serialize a Span
pub fn serialize_span(span : @markdown.Span) -> String {
  "@markdown.Span::{ from: " +
  span.from.to_string() +
  ", to: " +
  span.to.to_string() +
  " }"
}

///|
/// Serialize a TableAlign
pub fn serialize_align(align : @markdown.TableAlign) -> String {
  match align {
    @markdown.TableAlign::Left => "@markdown.TableAlign::Left"
    @markdown.TableAlign::Center => "@markdown.TableAlign::Center"
    @markdown.TableAlign::Right => "@markdown.TableAlign::Right"
    @markdown.TableAlign::None => "@markdown.TableAlign::None"
  }
}

///|
/// Serialize an EmphasisMarker
pub fn serialize_emphasis(m : @markdown.EmphasisMarker) -> String {
  match m {
    @markdown.EmphasisMarker::Asterisk => "@markdown.EmphasisMarker::Asterisk"
    @markdown.EmphasisMarker::Underscore =>
      "@markdown.EmphasisMarker::Underscore"
  }
}

///|
/// Serialize a HardBreakStyle
pub fn serialize_hardbreak(s : @markdown.HardBreakStyle) -> String {
  match s {
    @markdown.HardBreakStyle::TwoSpaces => "@markdown.HardBreakStyle::TwoSpaces"
    @markdown.HardBreakStyle::Backslash => "@markdown.HardBreakStyle::Backslash"
  }
}

///|
/// Serialize @markdown.Inline with given indent.
fn serialize_md_inline(inline : @markdown.Inline, _indent : Int) -> String {
  match inline {
    @markdown.Inline::Text(content~, span~) =>
      "@markdown.Inline::Text(content=\"" +
      escape_string(content) +
      "\", span=" +
      serialize_span(span) +
      ")"
    @markdown.Inline::SoftBreak(span~) =>
      "@markdown.Inline::SoftBreak(span=" + serialize_span(span) + ")"
    @markdown.Inline::HardBreak(style~, span~) =>
      "@markdown.Inline::HardBreak(style=" +
      serialize_hardbreak(style) +
      ", span=" +
      serialize_span(span) +
      ")"
    @markdown.Inline::Emphasis(marker~, children~, span~) =>
      "@markdown.Inline::Emphasis(marker=" +
      serialize_emphasis(marker) +
      ", children=" +
      serialize_md_inlines_simple(children) +
      ", span=" +
      serialize_span(span) +
      ")"
    @markdown.Inline::Strong(marker~, children~, span~) =>
      "@markdown.Inline::Strong(marker=" +
      serialize_emphasis(marker) +
      ", children=" +
      serialize_md_inlines_simple(children) +
      ", span=" +
      serialize_span(span) +
      ")"
    @markdown.Inline::Strikethrough(children~, span~) =>
      "@markdown.Inline::Strikethrough(children=" +
      serialize_md_inlines_simple(children) +
      ", span=" +
      serialize_span(span) +
      ")"
    @markdown.Inline::Code(content~, backtick_count~, span~) =>
      "@markdown.Inline::Code(content=\"" +
      escape_string(content) +
      "\", backtick_count=" +
      backtick_count.to_string() +
      ", span=" +
      serialize_span(span) +
      ")"
    @markdown.Inline::WikiLink(target~, label~, fragment~, span~) =>
      "@markdown.Inline::WikiLink(target=\"" +
      escape_string(target) +
      "\", label=\"" +
      escape_string(label) +
      "\", fragment=\"" +
      escape_string(fragment) +
      "\", span=" +
      serialize_span(span) +
      ")"
    @markdown.Inline::Link(children~, url~, title~, span~) =>
      "@markdown.Inline::Link(children=" +
      serialize_md_inlines_simple(children) +
      ", url=\"" +
      escape_string(url) +
      "\", title=\"" +
      escape_string(title) +
      "\", span=" +
      serialize_span(span) +
      ")"
    @markdown.Inline::RefLink(children~, label~, span~) =>
      "@markdown.Inline::RefLink(children=" +
      serialize_md_inlines_simple(children) +
      ", label=\"" +
      escape_string(label) +
      "\", span=" +
      serialize_span(span) +
      ")"
    @markdown.Inline::Autolink(url~, is_email~, span~) =>
      "@markdown.Inline::Autolink(url=\"" +
      escape_string(url) +
      "\", is_email=" +
      (if is_email { "true" } else { "false" }) +
      ", span=" +
      serialize_span(span) +
      ")"
    @markdown.Inline::Image(alt~, url~, title~, span~) =>
      "@markdown.Inline::Image(alt=\"" +
      escape_string(alt) +
      "\", url=\"" +
      escape_string(url) +
      "\", title=\"" +
      escape_string(title) +
      "\", span=" +
      serialize_span(span) +
      ")"
    @markdown.Inline::RefImage(alt~, label~, span~) =>
      "@markdown.Inline::RefImage(alt=\"" +
      escape_string(alt) +
      "\", label=\"" +
      escape_string(label) +
      "\", span=" +
      serialize_span(span) +
      ")"
    @markdown.Inline::HtmlInline(html~, span~) =>
      "@markdown.Inline::HtmlInline(html=\"" +
      escape_string(html) +
      "\", span=" +
      serialize_span(span) +
      ")"
    @markdown.Inline::FootnoteReference(label~, span~) =>
      "@markdown.Inline::FootnoteReference(label=\"" +
      escape_string(label) +
      "\", span=" +
      serialize_span(span) +
      ")"
  }
}

///|
/// Serialize @markdown.Inline array in compact form (no newlines).
fn serialize_md_inlines_simple(inlines : Array[@markdown.Inline]) -> String {
  if inlines.length() == 0 {
    return "[]"
  }
  let sb = StringBuilder::new()
  sb.write_string("[")
  for i = 0; i < inlines.length(); i = i + 1 {
    sb.write_string(serialize_md_inline(inlines[i], 0))
    if i < inlines.length() - 1 {
      sb.write_string(", ")
    }
  }
  sb.write_string("]")
  sb.to_string()
}

///|
/// Serialize an array of @markdown.Inline with given indent.
pub fn serialize_md_inlines(
  inlines : Array[@markdown.Inline],
  _indent : Int,
) -> String {
  serialize_md_inlines_simple(inlines)
}

///|
/// Serialize @ast.Inline with given indent.
pub fn serialize_inline(inline : @ast.Inline, indent : Int) -> String {
  match inline {
    @ast.Inline::Markdown(md) =>
      "@ast.Inline::Markdown(" + serialize_md_inline(md, indent) + ")"
    @ast.Inline::Component(name, args) =>
      "@ast.Inline::Component(\"" +
      escape_string(name) +
      "\", " +
      serialize_value_map_inline(args) +
      ")"
  }
}

///|
/// Serialize an array of @ast.Inline with given indent.
pub fn serialize_inlines(inlines : Array[@ast.Inline], indent : Int) -> String {
  if inlines.length() == 0 {
    return "[]"
  }
  let sb = StringBuilder::new()
  sb.write_string("[\n")
  for i = 0; i < inlines.length(); i = i + 1 {
    sb.write_string(indent_str(indent + 1))
    sb.write_string(serialize_inline(inlines[i], indent + 1))
    sb.write_string(",\n")
  }
  sb.write_string(indent_str(indent))
  sb.write_string("]")
  sb.to_string()
}

///|
/// Serialize a BlockTableCell
pub fn serialize_cell(cell : @ast.BlockTableCell, indent : Int) -> String {
  let sb = StringBuilder::new()
  sb.write_string("@ast.BlockTableCell::{ children: ")
  sb.write_string(serialize_inlines(cell.children, indent))
  sb.write_string(" }")
  sb.to_string()
}

///|
/// Serialize a ListItem
pub fn serialize_list_item(item : @ast.ListItem, indent : Int) -> String {
  let sb = StringBuilder::new()
  sb.write_string("@ast.ListItem::{ children: ")
  sb.write_string(serialize_blocks(item.children, indent))
  sb.write_string(" }")
  sb.to_string()
}

///|
/// Serialize an array of @ast.Block with given indent.
pub fn serialize_blocks(blocks : Array[@ast.Block], indent : Int) -> String {
  if blocks.length() == 0 {
    return "[]"
  }
  let sb = StringBuilder::new()
  sb.write_string("[\n")
  for i = 0; i < blocks.length(); i = i + 1 {
    sb.write_string(indent_str(indent + 1))
    sb.write_string(serialize_block(blocks[i], indent + 1))
    sb.write_string(",\n")
  }
  sb.write_string(indent_str(indent))
  sb.write_string("]")
  sb.to_string()
}

///|
/// Serialize a single Block with given indent.
pub fn serialize_block(block : @ast.Block, indent : Int) -> String {
  match block {
    @ast.Block::Paragraph(p) => {
      let sb = StringBuilder::new()
      sb.write_string("@ast.Block::Paragraph(@ast.BlockParagraph::{\n")
      sb.write_string(indent_str(indent + 1))
      sb.write_string("children: ")
      sb.write_string(serialize_inlines(p.children, indent + 1))
      sb.write_string(",\n")
      sb.write_string(indent_str(indent))
      sb.write_string("})")
      sb.to_string()
    }
    @ast.Block::Heading(h) => {
      let sb = StringBuilder::new()
      sb.write_string("@ast.Block::Heading(@ast.BlockHeading::{\n")
      sb.write_string(indent_str(indent + 1))
      sb.write_string("level: ")
      sb.write_string(h.level.to_string())
      sb.write_string(",\n")
      sb.write_string(indent_str(indent + 1))
      sb.write_string("children: ")
      sb.write_string(serialize_inlines(h.children, indent + 1))
      sb.write_string(",\n")
      sb.write_string(indent_str(indent))
      sb.write_string("})")
      sb.to_string()
    }
    @ast.Block::CodeBlock(c) => {
      let info_str = match c.info {
        Some(info) => "Some(\"" + escape_string(info) + "\")"
        None => "None"
      }
      let sb = StringBuilder::new()
      sb.write_string("@ast.Block::CodeBlock(@ast.BlockCode::{\n")
      sb.write_string(indent_str(indent + 1))
      sb.write_string("info: ")
      sb.write_string(info_str)
      sb.write_string(",\n")
      sb.write_string(indent_str(indent + 1))
      sb.write_string("content: \"")
      sb.write_string(escape_string(c.content))
      sb.write_string("\",\n")
      sb.write_string(indent_str(indent))
      sb.write_string("})")
      sb.to_string()
    }
    @ast.Block::ContainerComponent(cc) => {
      let sb = StringBuilder::new()
      sb.write_string("@ast.Block::ContainerComponent(@ast.BlockContainer::{\n")
      sb.write_string(indent_str(indent + 1))
      sb.write_string("name: \"")
      sb.write_string(escape_string(cc.name))
      sb.write_string("\",\n")
      sb.write_string(indent_str(indent + 1))
      sb.write_string("args: ")
      sb.write_string(serialize_value_map_inline(cc.args))
      sb.write_string(",\n")
      sb.write_string(indent_str(indent + 1))
      sb.write_string("children: ")
      sb.write_string(serialize_blocks(cc.children, indent + 1))
      sb.write_string(",\n")
      sb.write_string(indent_str(indent))
      sb.write_string("})")
      sb.to_string()
    }
    @ast.Block::BlockQuote(blocks) =>
      "@ast.Block::BlockQuote(" + serialize_blocks(blocks, indent) + ")"
    @ast.Block::List(l) => {
      let sb = StringBuilder::new()
      sb.write_string("@ast.Block::List(@ast.BlockList::{\n")
      sb.write_string(indent_str(indent + 1))
      sb.write_string("ordered: ")
      sb.write_string(if l.ordered { "true" } else { "false" })
      sb.write_string(",\n")
      sb.write_string(indent_str(indent + 1))
      sb.write_string("tight: ")
      sb.write_string(if l.tight { "true" } else { "false" })
      sb.write_string(",\n")
      sb.write_string(indent_str(indent + 1))
      sb.write_string("items: [\n")
      for i = 0; i < l.items.length(); i = i + 1 {
        sb.write_string(indent_str(indent + 2))
        sb.write_string(serialize_list_item(l.items[i], indent + 2))
        sb.write_string(",\n")
      }
      sb.write_string(indent_str(indent + 1))
      sb.write_string("],\n")
      sb.write_string(indent_str(indent))
      sb.write_string("})")
      sb.to_string()
    }
    @ast.Block::Table(t) => {
      let sb = StringBuilder::new()
      sb.write_string("@ast.Block::Table(@ast.BlockTable::{\n")
      sb.write_string(indent_str(indent + 1))
      sb.write_string("header: [\n")
      for i = 0; i < t.header.length(); i = i + 1 {
        sb.write_string(indent_str(indent + 2))
        sb.write_string(serialize_cell(t.header[i], indent + 2))
        sb.write_string(",\n")
      }
      sb.write_string(indent_str(indent + 1))
      sb.write_string("],\n")
      sb.write_string(indent_str(indent + 1))
      sb.write_string("alignments: [\n")
      for i = 0; i < t.alignments.length(); i = i + 1 {
        sb.write_string(indent_str(indent + 2))
        sb.write_string(serialize_align(t.alignments[i]))
        sb.write_string(",\n")
      }
      sb.write_string(indent_str(indent + 1))
      sb.write_string("],\n")
      sb.write_string(indent_str(indent + 1))
      sb.write_string("rows: [\n")
      for i = 0; i < t.rows.length(); i = i + 1 {
        let row = t.rows[i]
        sb.write_string(indent_str(indent + 2))
        sb.write_string("[\n")
        for j = 0; j < row.length(); j = j + 1 {
          sb.write_string(indent_str(indent + 3))
          sb.write_string(serialize_cell(row[j], indent + 3))
          sb.write_string(",\n")
        }
        sb.write_string(indent_str(indent + 2))
        sb.write_string("],\n")
      }
      sb.write_string(indent_str(indent + 1))
      sb.write_string("],\n")
      sb.write_string(indent_str(indent))
      sb.write_string("})")
      sb.to_string()
    }
    @ast.Block::ThematicBreak => "@ast.Block::ThematicBreak"
  }
}

///|
/// Serialize a Document to a MoonBit expression string.
/// Returns code like:
///   @ast.Document::{ children: [...], meta: Map([("title", "Hello")]) }
pub fn serialize_document(doc : @ast.Document) -> String {
  let sb = StringBuilder::new()
  sb.write_string("@ast.Document::{\n")
  sb.write_string(indent_str(1))
  sb.write_string("children: ")
  sb.write_string(serialize_blocks(doc.children, 1))
  sb.write_string(",\n")
  sb.write_string(indent_str(1))
  sb.write_string("meta: ")
  sb.write_string(serialize_string_map(doc.meta, 1))
  sb.write_string(",\n")
  sb.write_string("}")
  sb.to_string()
}
