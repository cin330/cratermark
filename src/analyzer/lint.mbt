///|
pub(all) enum Severity {
  Warning
  Error
} derive(Eq, Debug)

///|
pub(all) struct LintRule {
  code : String
  name : String
  severity : Severity
} derive(Eq, Debug)

///|
pub(all) struct LintIssue {
  code : String
  severity : Severity
  message : String
  position : @ast.Position
} derive(Eq, Debug)

///|
pub fn lint_rules() -> Array[LintRule] {
  [
    { code: "MD001", name: "heading-level-jump", severity: Warning },
    { code: "MD002", name: "duplicate-heading", severity: Warning },
    { code: "MD003", name: "image-alt-text", severity: Warning },
    { code: "MD004", name: "empty-link", severity: Warning },
    { code: "MD005", name: "valid-internal-anchor", severity: Error },
  ]
}

///|
fn issue(
  code : String,
  severity : Severity,
  message : String,
  position : @ast.Position,
) -> LintIssue {
  { code, severity, message, position }
}

///|
fn collect_anchors(blocks : Array[@ast.Block], anchors : Array[String]) -> Unit {
  for block in blocks {
    match block {
      @ast.Heading(_, children, _) =>
        anchors.push(@ast.slugify(@ast.inline_plain_text(children)))
      @ast.BlockQuote(children, _) => collect_anchors(children, anchors)
      @ast.List(_, _, items, _) =>
        for item in items {
          collect_anchors(item.children, anchors)
        }
      _ => ()
    }
  }
}

///|
fn lint_inlines(
  nodes : Array[@ast.Inline],
  anchors : Array[String],
  issues : Array[LintIssue],
) -> Unit {
  for node in nodes {
    match node {
      @ast.Strong(children, _) | @ast.Emphasis(children, _) =>
        lint_inlines(children, anchors, issues)
      @ast.Link(children, url, position) => {
        if url.trim().is_empty() {
          issues.push(
            issue("MD004", Warning, "Link destination is empty.", position),
          )
        } else if url.has_prefix("#") {
          let anchor = url[1:].to_owned()
          if !anchors.contains(anchor) {
            issues.push(
              issue(
                "MD005",
                Error,
                "Internal anchor '#\{anchor}' does not match any heading.",
                position,
              ),
            )
          }
        }
        lint_inlines(children, anchors, issues)
      }
      @ast.Image(alt, _, position) =>
        if alt.trim().is_empty() {
          issues.push(
            issue(
              "MD003",
              Warning,
              "Image is missing alternative text.",
              position,
            ),
          )
        }
      _ => ()
    }
  }
}

///|
fn lint_nested_blocks(
  blocks : Array[@ast.Block],
  anchors : Array[String],
  issues : Array[LintIssue],
) -> Unit {
  for block in blocks {
    match block {
      @ast.Heading(_, children, _) | @ast.Paragraph(children, _) =>
        lint_inlines(children, anchors, issues)
      @ast.BlockQuote(children, _) =>
        lint_nested_blocks(children, anchors, issues)
      @ast.List(_, _, items, _) =>
        for item in items {
          lint_nested_blocks(item.children, anchors, issues)
        }
      _ => ()
    }
  }
}

///|
/// Run CraterMark's v0.1 lint rule registry.
pub fn lint(document : @ast.Document) -> Array[LintIssue] {
  let issues : Array[LintIssue] = []
  let anchors : Array[String] = []
  collect_anchors(document.children, anchors)
  let seen_titles : Array[String] = []
  let mut previous_level = 0
  for block in document.children {
    match block {
      @ast.Heading(level, children, position) => {
        if previous_level > 0 && level > previous_level + 1 {
          issues.push(
            issue(
              "MD001",
              Warning,
              "Heading level jumps from H\{previous_level} to H\{level}.",
              position,
            ),
          )
        }
        previous_level = level
        let title = @ast.inline_plain_text(children)
          .trim()
          .to_owned()
          .to_lower()
        if seen_titles.contains(title) {
          issues.push(
            issue("MD002", Warning, "Duplicate heading '\{title}'.", position),
          )
        } else {
          seen_titles.push(title)
        }
      }
      _ => ()
    }
  }
  lint_nested_blocks(document.children, anchors, issues)
  issues
}

///|
pub fn severity_name(severity : Severity) -> String {
  match severity {
    Warning => "warning"
    Error => "error"
  }
}

///|
pub fn render_lint(path : String, issues : Array[LintIssue]) -> String {
  let out = StringBuilder()
  if issues.length() == 0 {
    out.write_string("\{path}: no problems found\n")
    return out.to_string()
  }
  out.write_string("\{path}\n\n")
  for item in issues {
    out.write_string("\{severity_name(item.severity)} \{item.code}\n")
    out.write_string("\{item.message}\n")
    out.write_string(
      " --> \{path}:\{item.position.start_line}:\{item.position.start_column}\n\n",
    )
  }
  out.write_string("\{issues.length()} problem")
  if issues.length() != 1 {
    out.write_string("s")
  }
  out.write_string(" found\n")
  out.to_string()
}
