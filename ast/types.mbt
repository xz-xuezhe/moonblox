// MoonMark AST type definitions

// Component argument values — maps to MoonBit-style DSL values
pub(all) enum Value {
  Str(String)
  Number(Double)
  Bool(Bool)
  Array(Array[Value])
  Record(Map[String, Value])
}

// Inline nodes
pub(all) enum Inline {
  Text(String)
  InlineComponent(String, Map[String, Value])
  Strong(Array[Inline])
  Emphasis(Array[Inline])
  CodeSpan(String)
  Link(String, String?, Array[Inline])
  Image(String, String?, String)
  SoftBreak
  HardBreak
}

// Block-level nodes
pub(all) enum Block {
  Paragraph(BlockParagraph)
  Heading(BlockHeading)
  CodeBlock(BlockCode)
  ContainerComponent(BlockContainer)
  BlockQuote(Array[Block])
  List(BlockList)
  ThematicBreak
}

pub(all) struct BlockParagraph {
  children : Array[Inline]
}

pub(all) struct BlockHeading {
  level : Int
  children : Array[Inline]
}

pub(all) struct BlockCode {
  info : String?
  content : String
}

pub(all) struct BlockContainer {
  name : String
  args : Map[String, Value]
  children : Array[Block]
}

pub(all) struct BlockList {
  tight : Bool
  items : Array[ListItem]
}

pub(all) struct ListItem {
  children : Array[Block]
}

// Root document
pub(all) struct Document {
  children : Array[Block]
}
