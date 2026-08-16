///|
pub(all) struct TocEntry {
  level : Int
  title : String
  anchor : String
  position : @ast.Position
} derive(Eq, Debug)

///|
fn collect_toc(blocks : Array[@ast.Block], entries : Array[TocEntry]) -> Unit {
  for block in blocks {
    match block {
      @ast.Heading(level, children, position) => {
        let title = @ast.inline_plain_text(children)
        entries.push({ level, title, anchor: @ast.slugify(title), position })
      }
      @ast.BlockQuote(children, _) => collect_toc(children, entries)
      @ast.List(_, _, items, _) =>
        for item in items {
          collect_toc(item.children, entries)
        }
      _ => ()
    }
  }
}

///|
pub fn table_of_contents(document : @ast.Document) -> Array[TocEntry] {
  let entries : Array[TocEntry] = []
  collect_toc(document.children, entries)
  entries
}

///|
pub fn render_toc(document : @ast.Document) -> String {
  let out = StringBuilder()
  for entry in table_of_contents(document) {
    out.write_string("  ".repeat(entry.level - 1))
    out.write_string("- [")
    out.write_string(entry.title)
    out.write_string("](#")
    out.write_string(entry.anchor)
    out.write_string(")\n")
  }
  out.to_string()
}
