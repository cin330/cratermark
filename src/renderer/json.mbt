///|
fn json_string(value : String) -> String {
  value.to_json().stringify()
}

///|
fn render_position(position : @ast.Position) -> String {
  "{\"start\":{\"line\":\{position.start_line},\"column\":\{position.start_column}},\"end\":{\"line\":\{position.end_line},\"column\":\{position.end_column}}}"
}

///|
fn render_json_inlines(nodes : Array[@ast.Inline]) -> String {
  let out = StringBuilder()
  out.write_string("[")
  for index, node in nodes {
    if index > 0 {
      out.write_string(",")
    }
    match node {
      @ast.Text(value, pos) =>
        out.write_string(
          "{\"type\":\"text\",\"value\":\{json_string(value)},\"position\":\{render_position(pos)}}",
        )
      @ast.Strong(children, pos) =>
        out.write_string(
          "{\"type\":\"strong\",\"children\":\{render_json_inlines(children)},\"position\":\{render_position(pos)}}",
        )
      @ast.Emphasis(children, pos) =>
        out.write_string(
          "{\"type\":\"emphasis\",\"children\":\{render_json_inlines(children)},\"position\":\{render_position(pos)}}",
        )
      @ast.InlineCode(value, pos) =>
        out.write_string(
          "{\"type\":\"inline_code\",\"value\":\{json_string(value)},\"position\":\{render_position(pos)}}",
        )
      @ast.Link(children, url, pos) =>
        out.write_string(
          "{\"type\":\"link\",\"url\":\{json_string(url)},\"children\":\{render_json_inlines(children)},\"position\":\{render_position(pos)}}",
        )
      @ast.Image(alt, url, pos) =>
        out.write_string(
          "{\"type\":\"image\",\"alt\":\{json_string(alt)},\"url\":\{json_string(url)},\"position\":\{render_position(pos)}}",
        )
    }
  }
  out.write_string("]")
  out.to_string()
}

///|
fn render_json_blocks(blocks : Array[@ast.Block]) -> String {
  let out = StringBuilder()
  out.write_string("[")
  for index, block in blocks {
    if index > 0 {
      out.write_string(",")
    }
    match block {
      @ast.Heading(level, children, pos) =>
        out.write_string(
          "{\"type\":\"heading\",\"level\":\{level},\"children\":\{render_json_inlines(children)},\"position\":\{render_position(pos)}}",
        )
      @ast.Paragraph(children, pos) =>
        out.write_string(
          "{\"type\":\"paragraph\",\"children\":\{render_json_inlines(children)},\"position\":\{render_position(pos)}}",
        )
      @ast.CodeBlock(language, code, pos) =>
        out.write_string(
          "{\"type\":\"code_block\",\"language\":\{json_string(language)},\"value\":\{json_string(code)},\"position\":\{render_position(pos)}}",
        )
      @ast.BlockQuote(children, pos) =>
        out.write_string(
          "{\"type\":\"block_quote\",\"children\":\{render_json_blocks(children)},\"position\":\{render_position(pos)}}",
        )
      @ast.List(ordered, start, items, pos) => {
        out.write_string(
          "{\"type\":\"list\",\"ordered\":\{ordered},\"start\":\{start},\"children\":[",
        )
        for item_index, item in items {
          if item_index > 0 {
            out.write_string(",")
          }
          out.write_string(
            "{\"type\":\"list_item\",\"children\":\{render_json_blocks(item.children)},\"position\":\{render_position(item.position)}}",
          )
        }
        out.write_string("],\"position\":\{render_position(pos)}}")
      }
      @ast.HorizontalRule(pos) =>
        out.write_string(
          "{\"type\":\"horizontal_rule\",\"position\":\{render_position(pos)}}",
        )
    }
  }
  out.write_string("]")
  out.to_string()
}

///|
/// Render the AST to a stable, machine-readable JSON representation.
pub fn render_json(document : @ast.Document, pretty? : Bool = true) -> String {
  let compact = "{\"type\":\"document\",\"children\":\{render_json_blocks(document.children)}}"
  if pretty {
    let value = @json.parse(compact) catch { _ => return compact }
    value.stringify(indent=2)
  } else {
    compact
  }
}
