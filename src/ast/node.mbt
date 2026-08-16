///|
/// Inline Markdown nodes. Every node retains its source position so analyzers
/// can report useful diagnostics.
pub(all) enum Inline {
  Text(String, Position)
  Strong(Array[Inline], Position)
  Emphasis(Array[Inline], Position)
  InlineCode(String, Position)
  Link(Array[Inline], String, Position)
  Image(String, String, Position)
} derive(Eq, Debug)

///|
pub(all) struct ListItem {
  children : Array[Block]
  position : Position
} derive(Eq, Debug)

///|
/// Block-level Markdown nodes supported by CraterMark v0.1.
pub(all) enum Block {
  Heading(Int, Array[Inline], Position)
  Paragraph(Array[Inline], Position)
  CodeBlock(String, String, Position)
  BlockQuote(Array[Block], Position)
  List(Bool, Int, Array[ListItem], Position)
  HorizontalRule(Position)
} derive(Eq, Debug)

///|
pub fn Inline::position(self : Inline) -> Position {
  match self {
    Text(_, pos)
    | Strong(_, pos)
    | Emphasis(_, pos)
    | InlineCode(_, pos)
    | Link(_, _, pos)
    | Image(_, _, pos) => pos
  }
}

///|
pub fn Block::position(self : Block) -> Position {
  match self {
    Heading(_, _, pos)
    | Paragraph(_, pos)
    | CodeBlock(_, _, pos)
    | BlockQuote(_, pos)
    | List(_, _, _, pos)
    | HorizontalRule(pos) => pos
  }
}

///|
pub fn inline_plain_text(nodes : Array[Inline]) -> String {
  let out = StringBuilder()
  for node in nodes {
    match node {
      Text(value, _) | InlineCode(value, _) => out.write_string(value)
      Strong(children, _) | Emphasis(children, _) | Link(children, _, _) =>
        out.write_string(inline_plain_text(children))
      Image(alt, _, _) => out.write_string(alt)
    }
  }
  out.to_string()
}
