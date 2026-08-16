# CraterMark DocGraph project proposal

## Project purpose

CraterMark is a MoonBit-native multi-file documentation graph and integrity
analyzer. It scans Markdown repositories, builds relationships between files,
heading anchors, links, images, and attachments, then reports missing targets,
case mismatches, orphan documents, missing resources, and unsafe paths.

The project does not aim to replace mature CommonMark parsers, documentation
readiness checkers, or static-site generators. Its boundary is repository-level
relationship analysis: whether documentation is correctly connected and what
other pages are affected by a change.

## Existing foundation

The repository already contains a source-aware Markdown AST, block and inline
extraction, stable heading slugs, a tested MoonBit CLI, examples, CI, and
multiple output helpers. This foundation supplies precise source locations for
the new graph analyzer.

## Planned and implemented work

- Recursive workspace and asset discovery
- Cross-file path and heading-anchor resolution
- Directed document graph and reverse-reference index
- Reachability and orphan-document analysis
- Missing and unused resource checks
- Windows/Linux path-case validation
- Change-impact analysis
- Text, Markdown, JSON, Mermaid, and DOT output
- Configurable roots and exclusions
- Portable pure-MoonBit graph tests

The current implementation also extracts full/collapsed reference-style links
and images plus same-line raw-HTML anchors and images. Later milestones add
external HTTP checks, issue baselines, safe repair, and Git-diff-aware
incremental scans. SARIF 2.1.0 output and GitHub Code Scanning upload are now
implemented.

## Technical route

The CLI discovers files and converts them into repository-relative inputs. A
pure MoonBit core extracts headings and links, normalizes targets, builds graph
edges, runs deterministic rules, computes reachability and reverse impacts, and
finally renders structured results. File-system code is kept outside the graph
engine so WASM tests do not require host I/O.

## Expected deliverables

- Public GitHub repository and traceable commits
- Mooncakes package release
- Complete README, architecture, configuration, and rule documentation
- Healthy and intentionally broken example workspaces
- Automated WASM and native tests
- GitHub Actions CI
- Reproducible CLI demonstrations and machine-readable reports
