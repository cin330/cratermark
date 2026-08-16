# Changelog

All notable changes to CraterMark are documented here.

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
