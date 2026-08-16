///|
fn render_markdown_inlines(nodes : Array[@ast.Inline]) -> String {
  let out = StringBuilder()
  for node in nodes {
    match node {
      @ast.Text(value, _) => out.write_string(value)
      @ast.Strong(children, _) => {
        out.write_string("**")
        out.write_string(render_markdown_inlines(children))
        out.write_string("**")
      }
      @ast.Emphasis(children, _) => {
        out.write_string("*")
        out.write_string(render_markdown_inlines(children))
        out.write_string("*")
      }
      @ast.InlineCode(value, _) => {
        out.write_string("`")
        out.write_string(value)
        out.write_string("`")
      }
      @ast.Link(children, url, _) => {
        out.write_string("[")
        out.write_string(render_markdown_inlines(children))
        out.write_string("](")
        out.write_string(url)
        out.write_string(")")
      }
      @ast.Image(alt, url, _) => {
        out.write_string("![")
        out.write_string(alt)
        out.write_string("](")
        out.write_string(url)
        out.write_string(")")
      }
    }
  }
  out.to_string()
}

///|
fn prefix_lines(value : String, prefix : String) -> String {
  let out = StringBuilder()
  for index, line in value.trim_end().to_owned().split("\n") {
    if index > 0 {
      out.write_string("\n")
    }
    out.write_string(prefix)
    out.write_string(line.to_owned())
  }
  out.to_string()
}

///|
fn render_markdown_blocks(blocks : Array[@ast.Block]) -> String {
  let parts : Array[String] = []
  for block in blocks {
    let out = StringBuilder()
    match block {
      @ast.Heading(level, children, _) => {
        out.write_string("#".repeat(level))
        out.write_string(" ")
        out.write_string(render_markdown_inlines(children))
      }
      @ast.Paragraph(children, _) =>
        out.write_string(render_markdown_inlines(children))
      @ast.CodeBlock(language, code, _) => {
        out.write_string("```")
        out.write_string(language)
        out.write_string("\n")
        out.write_string(code)
        if !code.has_suffix("\n") {
          out.write_string("\n")
        }
        out.write_string("```")
      }
      @ast.BlockQuote(children, _) =>
        out.write_string(prefix_lines(render_markdown_blocks(children), "> "))
      @ast.List(ordered, start, items, _) =>
        for index, item in items {
          if index > 0 {
            out.write_string("\n")
          }
          let marker = if ordered { "\{start + index}. " } else { "- " }
          let rendered = render_markdown_blocks(item.children).trim().to_owned()
          out.write_string(prefix_lines(rendered, marker))
        }
      @ast.HorizontalRule(_) => out.write_string("---")
    }
    parts.push(out.to_string())
  }
  let result = StringBuilder()
  for index, part in parts {
    if index > 0 {
      result.write_string("\n\n")
    }
    result.write_string(part)
  }
  result.to_string()
}

///|
/// Render canonical Markdown. The output always ends in a single newline.
pub fn render_markdown(document : @ast.Document) -> String {
  render_markdown_blocks(document.children).trim_end().to_owned() + "\n"
}
