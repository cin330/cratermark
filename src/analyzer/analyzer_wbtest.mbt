///|
test "generate table of contents" {
  let document = @parser.parse("# CraterMark\n\n## Install\n\n### Windows")
  assert_eq(
    render_toc(document),
    "- [CraterMark](#cratermark)\n  - [Install](#install)\n    - [Windows](#windows)\n",
  )
}

///|
test "calculate document statistics" {
  let document = @parser.parse(
    "# Title\n\nTwo words.\n\n- A\n- B\n\n```moonbit\nlet x = 1\n```\n\n[x](url) ![a](b)",
  )
  let stats = document_stats(document)
  assert_eq(stats.headings, 1)
  assert_eq(stats.lists, 1)
  assert_eq(stats.code_blocks, 1)
  assert_eq(stats.links, 1)
  assert_eq(stats.images, 1)
  assert_eq(stats.code_languages[0].language, "moonbit")
}

///|
test "MD001 heading level jump" {
  let issues = lint(@parser.parse("# A\n\n### B"))
  assert_true(issues.any(fn(issue) { issue.code == "MD001" }))
}

///|
test "MD002 duplicate heading" {
  let issues = lint(@parser.parse("## Install\n\n## Install"))
  assert_true(issues.any(fn(issue) { issue.code == "MD002" }))
}

///|
test "MD003 missing image alt" {
  let issues = lint(@parser.parse("![](logo.png)"))
  assert_true(issues.any(fn(issue) { issue.code == "MD003" }))
}

///|
test "MD004 empty link" {
  let issues = lint(@parser.parse("[Website]()"))
  assert_true(issues.any(fn(issue) { issue.code == "MD004" }))
}

///|
test "MD005 invalid internal anchor" {
  let issues = lint(@parser.parse("# Install\n\n[Guide](#guide)"))
  assert_true(issues.any(fn(issue) { issue.code == "MD005" }))
}

///|
test "valid document has no lint issues" {
  let issues = lint(
    @parser.parse("# Install\n\n[Install](#install)\n\n![Logo](logo.png)"),
  )
  assert_eq(issues.length(), 0)
}
