# Third-party code, licenses, and provenance

CraterMark is released under the MIT License, in the `LICENSE` file at the
repository root. This page records everything in the repository that CraterMark
did not write itself, so that license obligations can be checked without
reading the whole tree.

## Origin of the project

CraterMark is an original MoonBit project. It is not a port of, and does not
copy source from, an existing library in another language ecosystem. The
Markdown extraction layer follows the publicly documented
[CommonMark](https://commonmark.org/) syntax rules, which are a specification
rather than a code base; no CommonMark reference implementation was copied.

The SARIF output follows the OASIS
[SARIF 2.1.0 specification](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html).
Only the schema shape is implemented; no schema file or validator source is
vendored.

## Runtime dependencies

| Dependency | Version | License | Why it is needed |
| --- | --- | --- | --- |
| [`moonbitlang/core`](https://github.com/moonbitlang/core) | bundled with the toolchain | Apache-2.0 | Standard library |
| [`moonbitlang/x`](https://github.com/moonbitlang/x) | 0.4.50 | Apache-2.0 | `fs` and `sys` host access for the CLI |

Both dependencies are resolved by `moon` from mooncakes.io. No dependency
source is vendored into this repository, so no third-party source files are
redistributed here.

The graph engine in `src/docgraph` uses neither of them; host access lives in
`cmd/cratermark` only. A consumer that embeds the library therefore pulls in
`moonbitlang/core` alone.

## Build and CI components

| Component | License | Use |
| --- | --- | --- |
| [`actions/checkout`](https://github.com/actions/checkout) | MIT | CI checkout step |
| [`github/codeql-action/upload-sarif`](https://github.com/github/codeql-action) | MIT | Uploads `cratermark.sarif` to Code Scanning |

These are referenced by the workflow at build time and are not redistributed.

## Documents, fixtures, and assets

Every Markdown file under `docs/`, `examples/`, and `tests/fixtures/`, and every
SVG under `examples/` and `tests/fixtures/`, was written for this repository and
is covered by the project license. The fixtures deliberately contain broken
links, wrong-case paths, orphan pages, and unused assets, because that is what
the rule tests assert on. They are not copied from any external documentation
set, and they contain no personal data.

`examples/logo.svg` and `examples/workspace/assets/diagram.svg` are hand-written
plain SVG. No icon set, font, or stock image is bundled.

## AI assistance

AI coding assistants were used during development for code generation, test
drafting, and documentation editing, which the competition rules permit. The
project goals, module boundaries, rule semantics, and the decision to accept
each change are the author's. Every AI-assisted change is covered by the test
suite in `src/**/*_test.mbt` and `src/**/*_wbtest.mbt` and by the CI pipeline,
and no proprietary, closed-source, or unattributed third-party code was
introduced through it.

## Reporting a compliance problem

If you believe a file in this repository infringes a license, please open an
issue on the [GitHub repository](https://github.com/cin330/cratermark) with the
file path and the upstream source you believe it came from.
