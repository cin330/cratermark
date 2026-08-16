# SARIF and GitHub Code Scanning

CraterMark emits SARIF 2.1.0 so documentation integrity findings can be
consumed by GitHub Code Scanning and other SARIF-compatible systems.

## Generate a report

```bash
moon run cmd/cratermark scan . --format sarif --output cratermark.sarif
```

Use `scan` when a report must be produced even if the workspace contains
errors. Use `check` when the command should additionally return exit status 1
for errors:

```bash
moon run cmd/cratermark check . --format sarif --output cratermark.sarif
```

Without `--output`, SARIF is written to standard output.

## GitHub Actions

The repository workflow uses:

```yaml
permissions:
  contents: read
  security-events: write

steps:
  - uses: actions/checkout@v6
  - name: Generate CraterMark SARIF
    run: moon run cmd/cratermark scan . --format sarif --output cratermark.sarif
  - name: Upload CraterMark results
    uses: github/codeql-action/upload-sarif@v4
    with:
      sarif_file: cratermark.sarif
      category: cratermark/documentation
```

Uploads from pull requests originating in forks should be skipped because
their workflow token does not receive `security-events: write`. CraterMark's
included workflow applies this guard automatically.

## Result mapping

Each diagnostic maps to one SARIF result containing:

- its stable `CMG` rule identifier and rule index;
- `error` or `warning` severity;
- the human-readable diagnostic message;
- a repository-relative artifact URI;
- one-based source line and column;
- the original link target when one exists.

The upload action can add fingerprints when they are absent, allowing GitHub
to track the same finding across later commits.
