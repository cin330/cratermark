# Supported Markdown syntax

CraterMark v0.1 recognizes the following forms.

| Construct | Example | Notes |
| --- | --- | --- |
| ATX heading | `## Install` | Levels 1 through 6; a space is required |
| Paragraph | `Hello world` | Consecutive non-block lines are joined with a space |
| Fenced code | <code>```moonbit</code> | Backtick fences; optional language |
| Block quote | `> Note` | Consecutive quoted lines |
| Unordered list | `- Item` | `-`, `*`, or `+` marker |
| Ordered list | `3. Item` | Starting number is retained |
| Horizontal rule | `---` | Also `***` and `___` |
| Strong | `**bold**` | Parsed recursively |
| Emphasis | `*italic*` | `*` or `_` marker |
| Inline code | `` `code` `` | Single backtick delimiter |
| Link | `[label](url)` | Inline label content is parsed |
| Image | `![alt](url)` | Empty alt text is linted |

## Not yet supported

- Nested and loose lists
- Indented code blocks
- Setext headings
- Raw HTML block semantics
- Reference-style links and images
- Escaped delimiters and multiline inline constructs
- Tables, task lists, strikethrough, and footnotes
- Full CommonMark delimiter precedence

Unsupported input is preserved as paragraph text wherever possible.
