///|
fn next_anchor(base : String, anchors : Array[String]) -> (String, Bool) {
  if !anchors.contains(base) {
    anchors.push(base)
    return (base, false)
  }
  let mut suffix = 1
  while anchors.contains(base + "-" + suffix.to_string()) {
    suffix = suffix + 1
  }
  let anchor = base + "-" + suffix.to_string()
  anchors.push(anchor)
  (anchor, true)
}

///|
fn collect_headings(
  blocks : Array[@ast.Block],
  headings : Array[HeadingRef],
  anchors : Array[String],
) -> Unit {
  for block in blocks {
    match block {
      @ast.Heading(_, children, position) => {
        let title = @ast.inline_plain_text(children).trim().to_owned()
        let base = @ast.slugify(title)
        let (anchor, duplicate) = next_anchor(base, anchors)
        headings.push({ title, anchor, line: position.start_line, duplicate })
      }
      @ast.BlockQuote(children, _) =>
        collect_headings(children, headings, anchors)
      @ast.List(_, _, items, _) =>
        for item in items {
          collect_headings(item.children, headings, anchors)
        }
      _ => ()
    }
  }
}

///|
fn collect_inline_links(
  source : String,
  nodes : Array[@ast.Inline],
  links : Array[LinkRef],
) -> Unit {
  for node in nodes {
    match node {
      @ast.Strong(children, _) | @ast.Emphasis(children, _) =>
        collect_inline_links(source, children, links)
      @ast.Link(children, raw_target, position) => {
        let (target_path, fragment, kind, escaped_root) = resolve_target(
          source, raw_target, false,
        )
        links.push({
          source,
          label: @ast.inline_plain_text(children),
          raw_target,
          target_path,
          fragment,
          kind,
          line: position.start_line,
          column: position.start_column,
          escaped_root,
        })
        collect_inline_links(source, children, links)
      }
      @ast.Image(alt, raw_target, position) => {
        let (target_path, fragment, kind, escaped_root) = resolve_target(
          source, raw_target, true,
        )
        links.push({
          source,
          label: alt,
          raw_target,
          target_path,
          fragment,
          kind,
          line: position.start_line,
          column: position.start_column,
          escaped_root,
        })
      }
      _ => ()
    }
  }
}

///|
fn collect_block_links(
  source : String,
  blocks : Array[@ast.Block],
  links : Array[LinkRef],
) -> Unit {
  for block in blocks {
    match block {
      @ast.Heading(_, children, _) | @ast.Paragraph(children, _) =>
        collect_inline_links(source, children, links)
      @ast.BlockQuote(children, _) =>
        collect_block_links(source, children, links)
      @ast.List(_, _, items, _) =>
        for item in items {
          collect_block_links(source, item.children, links)
        }
      _ => ()
    }
  }
}

///|
fn extract_document(
  file : SourceFile,
) -> (DocumentNode, Array[LinkRef], Array[Diagnostic]) {
  let document = @parser.parse(file.content)
  let headings : Array[HeadingRef] = []
  let anchors : Array[String] = []
  let links : Array[LinkRef] = []
  let diagnostics : Array[Diagnostic] = []
  collect_headings(document.children, headings, anchors)
  collect_block_links(file.path, document.children, links)
  collect_supplemental_links(file.path, file.content, links, diagnostics)
  ({ path: file.path, headings }, links, diagnostics)
}
