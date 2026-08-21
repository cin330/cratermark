# Development

## Requirements

- MoonBit 0.1.20260807 or newer
- A C compiler for native CLI linking, or Node.js for the JavaScript target

## Validation

```bash
moon update
moon fmt
moon info
moon check -d
moon test --target wasm -d
moon build --target js
moon run cmd/cratermark check .
```

CI additionally runs native tests and builds the native executable.

## Running the graph commands

```bash
moon run cmd/cratermark check examples/workspace
moon run cmd/cratermark graph examples/workspace --format mermaid
moon run cmd/cratermark affected examples/workspace reference/api.md
moon run cmd/cratermark scan . --format sarif --output cratermark.sarif
```

On Windows without a C compiler:

```bat
cratermark.cmd check examples\workspace
cratermark.cmd graph examples\workspace --format dot
```

## Tests

MoonBit tests are colocated with packages. White-box tests live in
`*_wbtest.mbt` files and may touch package internals; black-box tests live in
`*_test.mbt` files and use only the public `@docgraph` API, which is what a
consuming project sees. Both run under `moon test`.

The `src/docgraph` tests use in-memory workspaces and cover:

1. Cross-platform path normalization.
2. Healthy document, anchor, and asset resolution.
3. Missing documents, anchors, and resources.
4. Case-mismatch graph connectivity.
5. Orphan documents and unused assets.
6. Unsafe schemes and root traversal.
7. Stable duplicate-heading anchors.
8. Direct and transitive impact analysis.
9. Machine-readable and graph output.
10. Full, collapsed, and shortcut reference links and images.
11. Raw-HTML tags that span several lines.
12. Code fences and multiline HTML comments that must not produce links.

Intentionally broken CLI fixtures live below `tests/fixtures` and are excluded
by the repository `cratermark.toml`.

## Adding a rule

1. Add the diagnostic in `src/docgraph/analyze.mbt`.
2. Assign a stable CMG code and severity.
3. Add an in-memory positive and negative test.
4. Document the behavior in [rules.md](rules.md).
5. Ensure text, Markdown, and JSON reports need no rule-specific parsing.

## Release checklist

1. Run formatting, type checking, WASM tests, and both CLI examples.
2. Confirm `cratermark check .` reports zero errors.
3. Update README, rules, configuration, proposal, and changelog.
4. Check `moon.mod` metadata and generated package interfaces.
5. Verify GitHub Actions after pushing.
6. Run a Mooncakes dry-run and publish the tagged version.
