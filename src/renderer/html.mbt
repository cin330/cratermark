///|
fn escape_html(value : String) -> String {
  value
  .replace_all(old="&", new="&amp;")
  .replace_all(old="<", new="&lt;")
  .replace_all(old=">", new="&gt;")
  .replace_all(old="\"", new="&quot;")
  .replace_all(old="'", new="&#39;")
}

///|
fn safe_url(value : String) -> String {
  let lowered = value.trim().to_owned().to_lower()
  if lowered.has_prefix("javascript:") ||
    lowered.has_prefix("vbscript:") ||
    lowered.has_prefix("data:text/html") {
    "#"
  } else {
    value
  }
}

///|
fn render_html_inlines(nodes : Array[@ast.Inline]) -> String {
  let out = StringBuilder()
  for node in nodes {
    match node {
      @ast.Text(value, _) => out.write_string(escape_html(value))
      @ast.Strong(children, _) => {
        out.write_string("<strong>")
        out.write_string(render_html_inlines(children))
        out.write_string("</strong>")
      }
      @ast.Emphasis(children, _) => {
        out.write_string("<em>")
        out.write_string(render_html_inlines(children))
        out.write_string("</em>")
      }
      @ast.InlineCode(value, _) => {
        out.write_string("<code>")
        out.write_string(escape_html(value))
        out.write_string("</code>")
      }
      @ast.Link(children, url, _) => {
        out.write_string("<a href=\"")
        out.write_string(escape_html(safe_url(url)))
        out.write_string("\">")
        out.write_string(render_html_inlines(children))
        out.write_string("</a>")
      }
      @ast.Image(alt, url, _) => {
        out.write_string("<img src=\"")
        out.write_string(escape_html(safe_url(url)))
        out.write_string("\" alt=\"")
        out.write_string(escape_html(alt))
        out.write_string("\" />")
      }
    }
  }
  out.to_string()
}

///|
fn render_html_blocks(blocks : Array[@ast.Block]) -> String {
  let out = StringBuilder()
  for block in blocks {
    match block {
      @ast.Heading(level, children, _) => {
        let text = @ast.inline_plain_text(children)
        out.write_string("<h\{level} id=\"")
        out.write_string(escape_html(@ast.slugify(text)))
        out.write_string("\">")
        out.write_string(render_html_inlines(children))
        out.write_string("</h\{level}>\n")
      }
      @ast.Paragraph(children, _) => {
        out.write_string("<p>")
        out.write_string(render_html_inlines(children))
        out.write_string("</p>\n")
      }
      @ast.CodeBlock(language, code, _) => {
        out.write_string("<pre><code")
        if language != "" {
          out.write_string(" class=\"language-")
          out.write_string(escape_html(language))
          out.write_string("\"")
        }
        out.write_string(">")
        out.write_string(escape_html(code))
        out.write_string("</code></pre>\n")
      }
      @ast.BlockQuote(children, _) => {
        out.write_string("<blockquote>\n")
        out.write_string(render_html_blocks(children))
        out.write_string("</blockquote>\n")
      }
      @ast.List(ordered, start, items, _) => {
        if ordered {
          if start == 1 {
            out.write_string("<ol>\n")
          } else {
            out.write_string("<ol start=\"\{start}\">\n")
          }
        } else {
          out.write_string("<ul>\n")
        }
        for item in items {
          out.write_string("<li>")
          out.write_string(render_html_blocks(item.children).trim().to_owned())
          out.write_string("</li>\n")
        }
        out.write_string(if ordered { "</ol>\n" } else { "</ul>\n" })
      }
      @ast.HorizontalRule(_) => out.write_string("<hr />\n")
    }
  }
  out.to_string()
}

///|
/// Render a document as an HTML fragment.
pub fn render_html(document : @ast.Document) -> String {
  render_html_blocks(document.children)
}
