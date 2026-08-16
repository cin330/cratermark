# Development

## Requirements

- MoonBit 0.1.20260807 or newer
- A C compiler for native CLI linking, or Node.js for the JavaScript target

## Commands

```bash
moon update
moon fmt
moon check
moon test --target wasm
moon info
```

Run the CLI with either backend:

```bash
moon run cmd/cratermark render examples/basic.md
moon run --target js cmd/cratermark render examples/basic.md
```

## Tests

MoonBit tests are colocated with their packages in `*_wbtest.mbt` files so they can
exercise parsing helpers and stable public behavior together. Fixtures intended for
manual CLI checks live in `tests/fixtures`.

Every syntax addition should include at least:

1. A normal parse case.
2. A boundary or malformed-input case.
3. HTML and Markdown output coverage.
4. Analyzer coverage when the node affects headings, links, images, lists, or code.

## Release checklist

1. Run `moon fmt` and ensure `moon check` has no warnings.
2. Run tests on WASM and native in CI.
3. Exercise all six CLI commands against `examples/complex.md`.
4. Update `CHANGELOG.md`, the feature list, and syntax boundaries.
