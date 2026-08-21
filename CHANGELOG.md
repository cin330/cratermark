# Changelog

All notable changes to CraterMark are documented here.

## 0.5.0 - 2026-08-21

- Resolve shortcut reference links and images such as `[guide]` when a matching
  definition exists, and leave unmatched brackets as plain text.
- Extract raw-HTML `<a>` and `<img>` targets whose opening tag spans several
  lines, reporting the position of the tag start.
- Mask fenced code blocks and multiline HTML comments before extraction so
  sample links inside them are no longer analyzed.
- Add a black-box test suite for the public `docgraph` API alongside the
  existing white-box tests.
- Pin text files to LF through `.gitattributes` so `moon fmt --check` and
  `moon info` behave the same on Windows and Linux.
- Run CI on Linux and macOS, fail on warnings in tests, and verify that the
  generated `.mbti` interfaces are committed.
- Document dependency licenses, fixture provenance, and AI assistance in
  `docs/third-party.md`.

## 0.4.1 - 2026-08-16

- Fix a false negative where undefined reference-style links and images were
  silently ignored.
- Add CMG009 diagnostics with source positions, reference identifiers, SARIF
  rule metadata, regression tests, and a broken-workspace fixture.

## 0.4.0 - 2026-08-16

- Add GitHub-compatible SARIF 2.1.0 output with CMG rule metadata, severity,
  messages, target properties, and repository-relative source locations.
- Add `--output` for project reports and make `scan` non-failing so CI can
  retain and upload findings while `check` remains a quality gate.
- Upload generated SARIF through GitHub Actions with fork-safe permissions.
- Add SARIF regression coverage and a dedicated integration guide.

## 0.3.0 - 2026-08-16

- Extract full and collapsed reference-style Markdown links.
- Resolve reference-style images through document-wide definitions.
- Extract links from raw-HTML `<a href>` and `<img src>` tags, including
  single-quoted, double-quoted, and unquoted attributes.
- Ignore supplemental link syntax inside fenced and inline code.
- Add runnable examples and five graph-engine regression tests.

## 0.2.0 - 2026-08-16

- Reposition CraterMark as a project-level documentation graph and integrity
  analyzer instead of a general-purpose Markdown parser.
- Add recursive workspace scanning with configurable entries and exclusions.
- Resolve cross-file document links, heading anchors, images, and attachments.
- Add CMG001-CMG010 diagnostics for missing targets, case mismatches,
  unreachable documents, unused assets, duplicate headings, workspace escapes,
  and unsafe URL schemes.
- Add reverse-reference change-impact analysis.
- Add text, Markdown, JSON, Mermaid, and Graphviz DOT reports.
- Add a healthy multi-file example workspace and nine graph-focused tests.
- Keep v0.1 single-file parsing and rendering commands as compatibility tools.

## 0.1.0 - 2026-08-16

- Add a structured Markdown AST with source positions.
- Parse headings, paragraphs, fenced code, quotes, lists, rules, emphasis,
  inline code, links, and images.
- Render HTML, JSON, and normalized Markdown.
- Add TOC generation, statistics, and five lint rules.
- Add the `parse`, `render`, `fmt`, `check`, `toc`, and `stats` CLI commands.
