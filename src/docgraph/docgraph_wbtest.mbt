///|
fn has_code(report : GraphReport, code : String) -> Bool {
  report.diagnostics.any(fn(item) { item.code == code })
}

///|
test "normalize repository paths" {
  assert_eq(normalize_path(".\\docs\\..\\README.md"), "README.md")
  assert_eq(normalize_path("docs//guide.md"), "docs/guide.md")
  assert_eq(dirname("docs/reference/api.md"), "docs/reference")
}

///|
test "healthy workspace builds a reachable graph" {
  let workspace = Workspace::new(
    [
      SourceFile::new(
        "README.md", "# Project\n\n[Install](docs/guide.md#install)\n\n![Logo](assets/logo.png)",
      ),
      SourceFile::new(
        "docs/guide.md", "# Guide\n\n## Install\n\nSee [MoonBit](https://moonbitlang.com).",
      ),
    ],
    assets=["assets/logo.png"],
    entries=["README.md"],
  )
  let report = analyze(workspace)
  assert_eq(report.diagnostics.length(), 0)
  assert_eq(report.stats.documents, 2)
  assert_eq(report.stats.reachable_documents, 2)
  assert_eq(report.stats.internal_links, 1)
  assert_eq(report.stats.external_links, 1)
  assert_eq(report.stats.asset_links, 1)
  assert_eq(report.edges.length(), 2)
}

///|
test "missing documents anchors and assets are diagnosed" {
  let workspace = Workspace::new([
    SourceFile::new(
      "README.md", "# Project\n\n[Missing](docs/missing.md)\n\n[Anchor](#unknown)\n\n![Missing](img/no.png)",
    ),
  ])
  let report = analyze(workspace)
  assert_true(has_code(report, "CMG001"))
  assert_true(has_code(report, "CMG002"))
  assert_true(has_code(report, "CMG005"))
  assert_eq(report.stats.errors, 3)
}

///|
test "path case mismatch keeps graph connectivity" {
  let workspace = Workspace::new(
    [
      SourceFile::new("README.md", "# Home\n\n[Guide](Docs/Guide.md)"),
      SourceFile::new("docs/guide.md", "# Guide"),
    ],
    entries=["README.md"],
  )
  let report = analyze(workspace)
  assert_true(has_code(report, "CMG003"))
  assert_eq(report.stats.reachable_documents, 2)
}

///|
test "orphan documents and unused assets are warnings" {
  let workspace = Workspace::new(
    [
      SourceFile::new("README.md", "# Home"),
      SourceFile::new("docs/orphan.md", "# Orphan"),
    ],
    assets=["assets/unused.png"],
    entries=["README.md"],
  )
  let report = analyze(workspace)
  assert_true(has_code(report, "CMG004"))
  assert_true(has_code(report, "CMG006"))
  assert_eq(report.stats.warnings, 2)
}

///|
test "unsafe targets and root escape are rejected" {
  let workspace = Workspace::new([
    SourceFile::new(
      "README.md", "# Home\n\n[Unsafe](javascript:alert)\n\n[Escape](../../secret.md)",
    ),
  ])
  let report = analyze(workspace)
  assert_true(has_code(report, "CMG008"))
  assert_true(has_code(report, "CMG010"))
}

///|
test "duplicate anchors receive stable suffixes" {
  let workspace = Workspace::new([
    SourceFile::new("README.md", "# Home\n\n## Install\n\n## Install"),
  ])
  let report = analyze(workspace)
  assert_true(has_code(report, "CMG007"))
  assert_eq(report.documents[0].headings[1].anchor, "install")
  assert_eq(report.documents[0].headings[2].anchor, "install-1")
}

///|
test "impact analysis follows reverse document links" {
  let workspace = Workspace::new(
    [
      SourceFile::new("README.md", "# Home\n\n[Guide](docs/guide.md)"),
      SourceFile::new("docs/guide.md", "# Guide\n\n[API](reference/api.md)"),
      SourceFile::new("docs/reference/api.md", "# API"),
    ],
    entries=["README.md"],
  )
  let report = analyze(workspace)
  let impact = affected(report, "docs/reference/api.md")
  assert_eq(impact.direct.length(), 1)
  assert_eq(impact.direct[0], "docs/guide.md")
  assert_eq(impact.transitive.length(), 1)
  assert_eq(impact.transitive[0], "README.md")
}

///|
test "machine-readable and graph renderers expose edges" {
  let report = analyze(
    Workspace::new([
      SourceFile::new("README.md", "# Home\n\n[Guide](guide.md)"),
      SourceFile::new("guide.md", "# Guide"),
    ]),
  )
  let json = render_json_report(report)
  let mermaid = render_mermaid(report)
  assert_true(json.contains("\"documents\":2"))
  assert_true(json.contains("\"source\":\"README.md\""))
  assert_true(mermaid.contains("graph TD"))
  assert_true(mermaid.contains("n0 --> n1"))
}

///|
test "reference-style links and images join the workspace graph" {
  let workspace = Workspace::new(
    [
      SourceFile::new(
        "README.md",
        (
          #|# Home
          #|
          #|Read the [installation guide][guide].
          #|
          #|![Project logo][logo]
          #|
          #|[guide]: docs/guide.md#install "Install guide"
          #|[logo]: <assets/logo.svg>
          #|,
        ),
      ),
      SourceFile::new("docs/guide.md", "# Guide\n\n## Install"),
    ],
    assets=["assets/logo.svg"],
    entries=["README.md"],
  )
  let report = analyze(workspace)
  assert_eq(report.diagnostics.length(), 0)
  assert_eq(report.stats.internal_links, 1)
  assert_eq(report.stats.asset_links, 1)
  assert_eq(report.stats.reachable_documents, 2)
}

///|
test "collapsed reference labels are case insensitive" {
  let report = analyze(
    Workspace::new([
      SourceFile::new("README.md", "# Home\n\n[Guide][]\n\n[ guide ]: guide.md"),
      SourceFile::new("guide.md", "# Guide"),
    ]),
  )
  assert_eq(report.diagnostics.length(), 0)
  assert_eq(report.stats.internal_links, 1)
}

///|
test "HTML anchors and images join the workspace graph" {
  let workspace = Workspace::new(
    [
      SourceFile::new(
        "README.md",
        (
          #|# Home
          #|
          #|<a href="docs/guide.md#install">Install guide</a>
          #|<img src='assets/logo.svg' alt='Project logo'>
          #|,
        ),
      ),
      SourceFile::new("docs/guide.md", "# Guide\n\n## Install"),
    ],
    assets=["assets/logo.svg"],
  )
  let report = analyze(workspace)
  assert_eq(report.diagnostics.length(), 0)
  assert_eq(report.stats.internal_links, 1)
  assert_eq(report.stats.asset_links, 1)
  assert_eq(report.edges.length(), 2)
}

///|
test "supplemental syntax inside code fences is ignored" {
  let report = analyze(
    Workspace::new([
      SourceFile::new(
        "README.md",
        (
          #|# Home
          #|
          #|```markdown
          #|[Missing][guide]
          #|<img src="missing.png">
          #|[guide]: missing.md
          #|```
          #|,
        ),
      ),
    ]),
  )
  assert_eq(report.diagnostics.length(), 0)
  assert_eq(report.links.length(), 0)
}

///|
test "supplemental links participate in integrity diagnostics" {
  let report = analyze(
    Workspace::new([
      SourceFile::new(
        "README.md",
        (
          #|# Home
          #|
          #|[Missing guide][guide]
          #|<a href=javascript:alert>Unsafe</a>
          #|<img src="assets/missing.svg" alt="Missing">
          #|
          #|[guide]: docs/missing.md
          #|,
        ),
      ),
    ]),
  )
  assert_true(has_code(report, "CMG001"))
  assert_true(has_code(report, "CMG005"))
  assert_true(has_code(report, "CMG010"))
  assert_eq(report.stats.errors, 3)
}
