# Architecture

CraterMark separates host file-system work from the portable graph engine.

```text
Directory
   |
   v
CLI workspace scanner
   |
   v
Array[SourceFile] + asset paths + entries
   |
   v
Heading/link extraction
   |
   v
Path and anchor resolution
   |
   v
Directed documentation graph
  /          |             \
 v           v              v
Rules    Reachability   Reverse references
  \          |              /
   +---------+-------------+
             v
Structured GraphReport
             |
             v
text / Markdown / JSON / SARIF / Mermaid / DOT
```

## Packages

### `src/ast`

The source-aware block and inline model retained from v0.1. Positions are
one-based and are propagated into project diagnostics.

### `src/parser`

A focused Markdown extraction layer. It recognizes the headings, links, images,
and common block containers needed by the graph engine. CraterMark does not
claim full CommonMark compatibility.

### `src/docgraph`

The v0.2 product core:

- `types.mbt`: portable workspace, node, edge, diagnostic, statistics, and
  impact types.
- `path.mbt`: cross-platform repository-path normalization, target splitting,
  root-escape detection, and target classification.
- `extract.mbt`: AST heading anchors and inline link/resource references.
- `supplemental.mbt`: document-wide reference definitions, reference-style
  links/images, and raw-HTML `href`/`src` extraction.
- `analyze.mbt`: resolution, integrity rules, reachability, and reverse-impact
  traversal.
- `render.mbt`: terminal, Markdown, JSON, Mermaid, and DOT output.
- `sarif.mbt`: SARIF 2.1.0 rules, results, severity, and source locations for
  GitHub Code Scanning integration.

The package performs no host I/O. Tests construct in-memory workspaces and run
on the WASM backend.

### `cmd/cratermark`

Owns recursive file discovery, `cratermark.toml`, command dispatch, host I/O,
and process exit status. It supplies normalized relative paths to
`src/docgraph`.

### Compatibility packages

`src/renderer`, `src/formatter`, and `src/analyzer` preserve the v0.1
single-file commands. New project-level behavior should be added to
`src/docgraph`, not to those compatibility layers.

## Graph semantics

Each Markdown file is a document node. Valid relative Markdown links produce
document edges. Referenced images and attachments produce asset edges. External
URLs are counted but do not produce repository reachability edges.

Configured entries seed a breadth-first traversal. Any document outside the
resulting reachable set receives CMG004. Reverse traversal powers the
`affected` command.

## Determinism

- Repository paths always use forward slashes.
- Directory entries are sorted before traversal.
- Heading anchor suffixes are generated in source order.
- Diagnostics and graph edges follow document and source order.
- No network request is needed for the v0.2 analyzer.
