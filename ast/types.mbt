// MoonMark AST type definitions

// Component argument values
///|
pub(all) enum Value {
  Str(String)
  Number(Double)
  Bool(Bool)
  Array(Array[Value])
  Record(Map[String, Value])
  Funcall(String, Map[String, Value])
}

// Inline nodes: either standard mdast or our custom component

///|
pub(all) enum Inline {
  Markdown(@markdown.Inline)
  Component(String, Map[String, Value])
}

// Block-level nodes

///|
pub(all) enum Block {
  Paragraph(BlockParagraph)
  Heading(BlockHeading)
  CodeBlock(BlockCode)
  ContainerComponent(BlockContainer)
  BlockQuote(Array[Block])
  List(BlockList)
  ThematicBreak
}

///|
pub(all) struct BlockParagraph {
  children : Array[Inline]
}

///|
pub(all) struct BlockHeading {
  level : Int
  children : Array[Inline]
}

///|
pub(all) struct BlockCode {
  info : String?
  content : String
}

///|
pub(all) struct BlockContainer {
  name : String
  args : Map[String, Value]
  children : Array[Block]
}

///|
pub(all) struct BlockList {
  tight : Bool
  items : Array[ListItem]
}

///|
pub(all) struct ListItem {
  children : Array[Block]
}

///|
pub(all) struct Document {
  children : Array[Block]
}
