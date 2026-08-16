///|
test "render basic HTML" {
  let document = @parser.parse("# Hello\n\nWorld")
  assert_eq(
    render_html(document),
    "<h1 id=\"hello\">Hello</h1>\n<p>World</p>\n",
  )
}

///|
test "escape HTML content and attributes" {
  let document = @parser.parse("<tag> [x](\"bad\")")
  assert_eq(
    render_html(document),
    "<p>&lt;tag&gt; <a href=\"&quot;bad&quot;\">x</a></p>\n",
  )
}

///|
test "block dangerous URLs" {
  let document = @parser.parse("[bad](javascript:alert)")
  assert_true(render_html(document).contains("href=\"#\""))
}

///|
test "render canonical Markdown" {
  let document = @parser.parse("#    Hello\n\n-   A\n- B")
  assert_eq(render_markdown(document), "# Hello\n\n- A\n- B\n")
}

///|
test "render stable JSON node types" {
  let document = @parser.parse("# Hello")
  let output = render_json(document)
  assert_true(output.contains("\"type\": \"document\""))
  assert_true(output.contains("\"type\": \"heading\""))
  assert_true(output.contains("\"line\": 1"))
}
