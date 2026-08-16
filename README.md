# CraterMark

> A MoonBit-native documentation graph and integrity analyzer.

CraterMark scans a complete Markdown workspace, resolves links across files,
builds a dependency graph, and reports structural problems before readers find
them. It is designed for documentation repositories, open-source projects,
knowledge bases, and CI pipelines.

CraterMark is not trying to be another full CommonMark implementation. Its
source-aware Markdown parser is an extraction layer; the product is the
project-level graph, integrity rules, and change-impact analysis built on top.

## What it catches

Given this project:

```text
README.md
docs/
  install.md
  config.md
  orphan.md
assets/
  logo.svg
  unused.png
```

CraterMark can report:

```text
error CMG001 README.md:12:1
  Document target 'docs/missing.md' does not exist.

error CMG002 README.md:18:1
  Anchor '#server' does not exist in 'docs/config.md'.

warning CMG004 docs/orphan.md:1:1
  Document is unreachable from the configured entry points.

warning CMG006 assets/unused.png
  Document asset is not referenced by any Markdown file.
```

## Core capabilities

- Recursive Markdown workspace discovery
- Inline, reference-style, and raw-HTML link/image extraction
- Cross-file link and heading-anchor resolution
- Windows/Linux path-case mismatch detection
- Missing image and attachment detection
- Unused document asset detection
- Entry-point reachability and orphan-document analysis
- Reverse-reference and transitive change-impact analysis
- Mermaid, Graphviz DOT, JSON, Markdown, SARIF 2.1.0, and terminal output
- Source file, line, and column diagnostics
- Configurable entry points and excluded directory prefixes
- Non-zero exit status when integrity errors are found

## Quick start

Install the current [MoonBit toolchain](https://www.moonbitlang.com/download/),
then run:

```bash
moon update
moon test --target wasm
moon run cmd/cratermark check .
moon run cmd/cratermark graph . --format mermaid
```

On Windows, the repository launcher automatically finds Node.js and can be
called from any directory:

```bat
cratermark.cmd check C:\path\to\project
cratermark.cmd graph C:\path\to\project --format dot
cratermark.cmd affected C:\path\to\project docs\api.md
```

Relative paths are resolved from the caller's current directory. In
`cmd.exe`, use `REM` for comments; `#` is not a CMD comment marker.

## Project commands

```text
cratermark check <directory> [--format text|json|markdown|sarif] [--output file] [--entry file]
cratermark scan <directory> [--format text|json|markdown|sarif] [--output file] [--entry file]
cratermark graph <directory> [--format mermaid|dot|json]
cratermark affected <directory> <changed-file>
cratermark stats <directory>
```

Examples:

```bash
# Validate a project and fail when errors exist
moon run cmd/cratermark check examples/workspace

# Export a diagram
moon run cmd/cratermark graph examples/workspace --format mermaid

# Find every document affected by an API-page change
moon run cmd/cratermark affected examples/workspace reference/api.md

# Emit machine-readable diagnostics and graph edges
moon run cmd/cratermark check examples/workspace --format json

# Generate a SARIF 2.1.0 file without failing on existing findings
moon run cmd/cratermark scan . --format sarif --output cratermark.sarif
```

`check` exits with status 1 when errors exist. `scan` renders the same report
without failing, which allows CI to upload SARIF even when findings are present.

## Integrity rules

| Code | Severity | Rule |
| --- | --- | --- |
| CMG001 | error | Linked Markdown document does not exist |
| CMG002 | error | Heading anchor does not exist in the target document |
| CMG003 | error | Document or resource path has the wrong letter case |
| CMG004 | warning | Document is unreachable from configured entry points |
| CMG005 | error | Referenced image or attachment does not exist |
| CMG006 | warning | Document asset is not referenced |
| CMG007 | warning | Duplicate heading required a generated anchor suffix |
| CMG008 | error | Link escapes the configured workspace root |
| CMG009 | error | Reference-style link or image has no matching definition |
| CMG010 | error | Link uses an unsafe URL scheme |

Diagnostics are structured values before they are rendered, so other MoonBit
packages can consume them without parsing terminal output.

## Configuration

Create `cratermark.toml` in the directory being scanned:

```toml
entries = ["README.md", "docs/index.md"]
exclude = ["tests/fixtures", "vendor/docs"]
```

`entries` define graph roots. Documents not reachable from a root receive
CMG004. `exclude` values are repository-relative directory or file prefixes.
The `--entry` option overrides configured entries for one run.

See [configuration details](docs/configuration.md) and the
[rule reference](docs/rules.md).

## GitHub Code Scanning

SARIF results contain stable CMG rule identifiers, severity, messages, and
repository-relative line/column locations. The included CI workflow generates
`cratermark.sarif` and uploads it with
`github/codeql-action/upload-sarif@v4`, allowing supported findings to appear
as Code Scanning alerts and PR annotations.

See the [SARIF and Code Scanning guide](docs/sarif.md) for standalone usage,
workflow permissions, and fork-safety details.

## Change-impact analysis

CraterMark builds reverse references as well as forward links:

```text
Changed:
  reference/api.md

Directly affected:
  guide/install.md

Transitively affected:
  README.md
```

This is the documentation equivalent of “find references”: maintainers can
rename, move, or delete a page after seeing every dependent document.

## Library use

The graph engine is pure and receives in-memory inputs, which keeps it portable
to WASM and easy to test:

```moonbit
let workspace = @docgraph.Workspace::new([
  @docgraph.SourceFile::new("README.md", "# Home\n\n[Guide](guide.md)"),
  @docgraph.SourceFile::new("guide.md", "# Guide"),
])
let report = @docgraph.analyze(workspace)
let diagram = @docgraph.render_mermaid(report)
```

File discovery is deliberately isolated in the CLI package.

## Architecture

```text
Workspace scanner
      |
      v
Markdown heading/link extractor
      |
      v
Path + anchor resolver
      |
      v
Directed documentation graph
   /       |          \
  v        v           v
Rules   Reachability  Reverse references
  \        |           /
   +-------+----------+
           v
 text / JSON / Markdown / SARIF / Mermaid / DOT
```

See [architecture](docs/architecture.md) for package boundaries.

## Ecosystem boundary

| Tool category | Primary question |
| --- | --- |
| Markdown parser/renderers | What syntax is present and how should it render? |
| Outline readers | What headings exist inside one file? |
| Documentation-readiness checkers | Are README, API comments, metadata, and CI present? |
| Static-site generators | How should Markdown become a website? |
| **CraterMark** | **Are all documents, anchors, and assets correctly connected across the repository?** |

The distinction is intentional: CraterMark operates on relationships between
files rather than competing on CommonMark completeness or website themes.

## Compatibility commands

The v0.1 single-file commands remain available for debugging and migration, but
they are no longer the main project direction:

```text
cratermark parse <file>
cratermark render <file> [--format html|json|markdown]
cratermark fmt <file>
cratermark toc <file>
```

The supported syntax boundary of that extraction layer is documented in
[syntax.md](docs/syntax.md).

## Examples and project documents

- [Healthy multi-file workspace](examples/workspace/README.md)
- [Basic Markdown input](examples/basic.md)
- [Parser demonstration](examples/demo.md)
- [Complex input](examples/complex.md)
- [Competition project proposal](docs/project-proposal.md)
- [Development guide](docs/development.md)
- [Changelog](CHANGELOG.md)

## Current limitations

- Reference-style extraction supports full and collapsed labels; shortcut-only
  references such as `[guide]` are not interpreted as links.
- Raw-HTML extraction currently requires each `<a>` or `<img>` opening tag to
  appear on one source line.
- External HTTP URLs are counted but are not fetched.
- Exclusions are path prefixes rather than a complete glob implementation.
- Safe automatic repair and issue baselines are planned for later releases.

## License

MIT
