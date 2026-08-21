# Supported Markdown syntax

CraterMark's focused extraction layer recognizes the following forms. This
layer supports the project graph; full CommonMark compatibility is not a
CraterMark goal.

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
| Link | <code>&#91;label&#93;(url)</code> | Inline label content is parsed |
| Image | <code>!&#91;alt&#93;(url)</code> | Empty alt text is linted |
| Reference link | <code>&#91;label&#93;&#91;id&#93;</code> | Full, collapsed, and shortcut references feed the project graph |
| Reference image | <code>!&#91;alt&#93;&#91;id&#93;</code> | Definition targets are resolved across the document |
| HTML anchor | `<a href="guide.md">` | Opening tags may span several lines |
| HTML image | `<img src="logo.svg">` | Quoted and unquoted attributes are recognized |
| HTML comment | `<!-- ... -->` | Multiline comments are masked out before extraction |

## Not yet supported

- Nested and loose lists
- Indented code blocks
- Setext headings
- Full raw HTML block semantics beyond `<a>` and `<img>` targets
- Nested link labels such as `[see [inner]][id]`
- Escaped delimiters and multiline inline constructs
- Tables, task lists, strikethrough, and footnotes
- Full CommonMark delimiter precedence

Unsupported input is preserved as paragraph text wherever possible.
