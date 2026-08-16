# Integrity rule reference

## CMG001 — missing document

A relative Markdown link resolves to a file that is not part of the workspace.

## CMG002 — missing anchor

The target document exists, but its generated heading anchors do not contain the
requested fragment.

## CMG003 — path case mismatch

A case-insensitive match exists but the spelling in the link differs from the
real path. This catches links that work on Windows but fail on Linux hosting.

## CMG004 — unreachable document

No configured entry point can reach the document through Markdown links.

## CMG005 — missing resource

An image or attachment path does not exist among scanned document assets.

## CMG006 — unused resource

A scanned image or attachment has no incoming Markdown reference.

## CMG007 — duplicate heading

Multiple headings generate the same base slug. CraterMark records the stable
suffix used by the extractor and reports the ambiguity.

## CMG008 — workspace escape

Normalizing a relative target would traverse above the scanned project root.

## CMG009 — undefined reference

A full or collapsed reference-style link or image uses an identifier that has
no matching definition in the same Markdown document. CraterMark reports each
source occurrence so it can be annotated on the affected PR line.

## CMG010 — unsafe scheme

A link starts with an unsafe scheme such as `javascript:` or
`data:text/html`.
