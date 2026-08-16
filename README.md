# CraterMark

> A structured Markdown parsing, analysis, and rendering toolkit written in MoonBit.

CraterMark turns Markdown into a source-aware AST, then lets independent renderers,
analyzers, and transformers consume that structure. It is intentionally a focused
v0.1 implementation rather than a claim of complete CommonMark compatibility.

## Features

- [x] Block and inline Markdown parser
- [x] Structured AST with one-based source positions
- [x] HTML, JSON, and normalized Markdown renderers
- [x] Table-of-contents generator
- [x] Document and code-language statistics
- [x] Extensible lint rule registry with MD001-MD005
- [x] `parse`, `render`, `fmt`, `check`, `toc`, and `stats` commands
- [ ] GitHub-style tables, task lists, strikethrough, and footnotes
- [ ] Static site generator and plugin API

## Supported syntax

CraterMark v0.1 supports ATX headings, paragraphs, fenced code blocks, block quotes,
ordered and unordered lists, horizontal rules, strong text, emphasis, inline code,
links, and images. See [docs/syntax.md](docs/syntax.md) for the exact boundary.

## Quick start

Install the current [MoonBit toolchain](https://www.moonbitlang.com/download/),
then run:

```bash
moon update
moon check
moon test --target wasm
moon run cmd/cratermark render examples/basic.md
```

The default target is native. A working C compiler is required to link the native
CLI because its file-system dependency uses a small C stub. You can instead use the
JavaScript target when Node.js is available:

```bash
moon run --target js cmd/cratermark render examples/basic.md
```

On Windows, `cratermark.cmd` automatically finds Node.js from `PATH` and falls back to
the Node.js runtime bundled with Codex Desktop:

```bat
cratermark.cmd render examples\basic.md
cratermark.cmd parse examples\demo.md
cratermark.cmd check tests\fixtures\lint.md
```

The launcher may be called from any directory. Relative Markdown paths are resolved
from the caller's current directory, while the CraterMark project is built from its own
directory internally.

When using `cmd.exe`, do not paste lines beginning with `#`; unlike PowerShell and
Bash, `cmd.exe` does not treat `#` as a comment. Use `REM` for comments instead.

## CLI

```text
cratermark parse <file>
cratermark render <file> [--format html|json|markdown]
cratermark fmt <file>
cratermark check <file>
cratermark toc <file>
cratermark stats <file>
```

Examples:

```bash
# Inspect the AST as JSON
moon run cmd/cratermark parse README.md

# Render HTML or canonical Markdown
moon run cmd/cratermark render README.md
moon run cmd/cratermark render README.md --format markdown

# Analyze a document
moon run cmd/cratermark toc README.md
moon run cmd/cratermark stats README.md
moon run cmd/cratermark check README.md

# Rewrite a file in place
moon run cmd/cratermark fmt README.md
```

## Lint rules

| Code | Severity | Rule |
| --- | --- | --- |
| MD001 | warning | Heading level jumps by more than one |
| MD002 | warning | Duplicate heading text |
| MD003 | warning | Image has empty alternative text |
| MD004 | warning | Link destination is empty |
| MD005 | error | Internal anchor does not match a heading |

Diagnostics include the source path, line, and column retained in the AST.

## Architecture

```text
Markdown source
      |
      v
Block Parser ---> Inline Parser
      |                |
      +-------+--------+
              v
        Source-aware AST
         /     |      \
        v      v       v
   Analyzer Formatter Renderer
   TOC/Lint   Markdown HTML/JSON
         \      |      /
          +-----+-----+
                v
               CLI
```

Each directory below is a separate MoonBit package:

```text
src/ast        shared document model and positions
src/parser     block and inline parsing
src/renderer   HTML, JSON, and Markdown output
src/analyzer   TOC, statistics, and lint rules
src/formatter  canonical Markdown transformation
cmd/cratermark    file I/O and command dispatch
```

For design details, see [docs/architecture.md](docs/architecture.md). For contributor
commands and test layout, see [docs/development.md](docs/development.md).

## Library use

Packages can import only the layers they need:

```moonbit
let document = @parser.parse("# Hello\n\nWelcome to **CraterMark**.")
let html = @renderer.render_html(document)
let issues = @analyzer.lint(document)
```

Package dependencies are declared in `moon.pkg`, following normal MoonBit package
rules.

## Roadmap

- **v0.2:** tables, task lists, strikethrough, footnotes, external link checking
- **v0.3:** static site generation, navigation, search index, and themes
- **v0.4:** MoonBit API documentation generation
- **v1.0:** plugin API, WASM embedding, and documentation extensions

## License

MIT
