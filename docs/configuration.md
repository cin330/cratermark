# Configuration

CraterMark reads `cratermark.toml` from the root passed to the CLI.

## Entry points

```toml
entries = ["README.md", "docs/index.md"]
```

Entry points are the roots used for reachability analysis. A Markdown file that
cannot be reached by following document links from any entry receives CMG004.
Without configuration, CraterMark uses a root-level `README.md`, or the first
discovered Markdown file when no README exists.

Override the entries for one command:

```bash
cratermark check . --entry docs/index.md
```

## Exclusions

```toml
exclude = ["tests/fixtures", "vendor/docs"]
```

Exclusions are normalized repository-relative path prefixes. CraterMark also
ignores `.git`, `_build`, `node_modules`, `.idea`, and `.vscode`
directories by default.

## Path behavior

- Backslashes are converted to forward slashes.
- `.` and `..` components are normalized.
- Attempts to escape the scanned root receive CMG008.
- Exact path case is enforced even on case-insensitive file systems.
