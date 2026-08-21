///|
/// Black-box tests exercise the package exactly the way another MoonBit
/// project would use it: only the public API, no access to internals.
fn workspace_of(
  documents : Array[(String, String)],
  assets? : Array[String] = [],
  entries? : Array[String] = [],
) -> @docgraph.Workspace {
  @docgraph.Workspace::new(
    documents.map(fn(item) { @docgraph.SourceFile::new(item.0, item.1) }),
    assets~,
    entries~,
  )
}

///|
fn codes_of(report : @docgraph.GraphReport) -> Array[String] {
  report.diagnostics.map(fn(item) { item.code })
}

///|
fn targets_of(report : @docgraph.GraphReport, source : String) -> Array[String] {
  report.links
  .filter(fn(link) { link.source == source })
  .map(fn(link) { link.target_path })
}

///|
test "shortcut reference links resolve against their definition" {
  let report = @docgraph.analyze(
    workspace_of(
      [
        (
          "README.md", "# Home\n\nRead the [install guide] before starting.\n\n[install guide]: docs/install.md\n",
        ),
        ("docs/install.md", "# Install"),
      ],
      entries=["README.md"],
    ),
  )
  assert_eq(codes_of(report), [])
  assert_eq(targets_of(report, "README.md"), ["docs/install.md"])
  assert_eq(report.stats.reachable_documents, 2)
}

///|
test "shortcut brackets without a definition stay plain text" {
  let report = @docgraph.analyze(
    workspace_of(
      [("README.md", "# Home\n\nA task list:\n\n- [ ] pending\n- [x] done\n")],
      entries=["README.md"],
    ),
  )
  assert_eq(codes_of(report), [])
  assert_eq(report.links.length(), 0)
}

///|
test "shortcut reference images are asset links" {
  let report = @docgraph.analyze(
    workspace_of(
      [("README.md", "# Home\n\n![logo]\n\n[logo]: assets/logo.svg\n")],
      assets=["assets/logo.svg"],
      entries=["README.md"],
    ),
  )
  assert_eq(codes_of(report), [])
  assert_eq(report.stats.asset_links, 1)
}

///|
test "collapsed and full reference links keep working" {
  let report = @docgraph.analyze(
    workspace_of(
      [
        (
          "README.md", "# Home\n\n[Guide][] and [the guide][guide].\n\n[guide]: docs/guide.md\n",
        ),
        ("docs/guide.md", "# Guide"),
      ],
      entries=["README.md"],
    ),
  )
  assert_eq(codes_of(report), [])
  assert_eq(targets_of(report, "README.md"), ["docs/guide.md", "docs/guide.md"])
}

///|
test "undefined full reference is reported once" {
  let report = @docgraph.analyze(
    workspace_of([("README.md", "# Home\n\n[Guide][missing]\n")]),
  )
  assert_eq(codes_of(report), ["CMG009"])
  assert_eq(report.diagnostics[0].line, 3)
}

///|
test "raw HTML anchors may span several lines" {
  let report = @docgraph.analyze(
    workspace_of(
      [
        (
          "README.md", "# Home\n\n<a\n  class=\"cta\"\n  href=\"docs/guide.md\">\n  Read the guide\n</a>\n",
        ),
        ("docs/guide.md", "# Guide"),
      ],
      entries=["README.md"],
    ),
  )
  assert_eq(codes_of(report), [])
  assert_eq(targets_of(report, "README.md"), ["docs/guide.md"])
  assert_eq(report.links[0].label, "Read the guide")
  assert_eq(report.links[0].line, 3)
}

///|
test "raw HTML images may span several lines" {
  let report = @docgraph.analyze(
    workspace_of(
      [
        (
          "README.md", "# Home\n\n<img\n  src=\"assets/missing.svg\"\n  alt=\"Diagram\" />\n",
        ),
      ],
      entries=["README.md"],
    ),
  )
  assert_eq(codes_of(report), ["CMG005"])
  assert_eq(report.diagnostics[0].line, 3)
}

///|
test "links inside HTML comments and code fences are ignored" {
  let report = @docgraph.analyze(
    workspace_of(
      [
        (
          "README.md", "# Home\n\n<!--\n<a href=\"docs/gone.md\">old</a>\n-->\n\n```html\n<a href=\"docs/also-gone.md\">sample</a>\n```\n",
        ),
      ],
      entries=["README.md"],
    ),
  )
  assert_eq(codes_of(report), [])
  assert_eq(report.links.length(), 0)
}

///|
test "change impact walks reverse references" {
  let report = @docgraph.analyze(
    workspace_of(
      [
        ("README.md", "# Home\n\n[Guide](docs/guide.md)"),
        ("docs/guide.md", "# Guide\n\n[API](reference/api.md)"),
        ("docs/reference/api.md", "# API"),
      ],
      entries=["README.md"],
    ),
  )
  let impact = @docgraph.affected(report, "docs/reference/api.md")
  assert_eq(impact.changed, "docs/reference/api.md")
  assert_eq(impact.direct, ["docs/guide.md"])
  assert_eq(impact.transitive, ["README.md"])
}

///|
test "every renderer produces output for the same report" {
  let report = @docgraph.analyze(
    workspace_of([("README.md", "# Home\n\n[Missing](docs/missing.md)")], entries=[
      "README.md",
    ]),
  )
  assert_true(@docgraph.render_text(report).contains("CMG001"))
  assert_true(@docgraph.render_markdown_report(report).contains("CMG001"))
  assert_true(@docgraph.render_json_report(report).contains("\"CMG001\""))
  assert_true(@docgraph.render_sarif(report).contains("\"CMG001\""))
  assert_true(@docgraph.render_mermaid(report).contains("graph"))
  assert_true(@docgraph.render_dot(report).contains("digraph"))
  assert_true(@docgraph.render_stats(report.stats).contains("Documents"))
}

///|
test "path helpers classify targets" {
  assert_eq(@docgraph.normalize_path("./docs/../README.md"), "README.md")
  assert_eq(@docgraph.dirname("docs/reference/api.md"), "docs/reference")
  assert_true(@docgraph.is_markdown_path("docs/guide.MD"))
  assert_true(@docgraph.is_document_asset("assets/logo.svg"))
  assert_true(@docgraph.is_external_target("https://moonbitlang.com"))
  assert_true(@docgraph.is_unsafe_target("javascript:alert(1)"))
  assert_eq(@docgraph.severity_name(@docgraph.Severity::Error), "error")
}
