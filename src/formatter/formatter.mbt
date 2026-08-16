///|
/// Format a parsed document as canonical Markdown.
pub fn format(document : @ast.Document) -> String {
  @renderer.render_markdown(document)
}
