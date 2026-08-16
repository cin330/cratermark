///|
test "format normalizes Markdown" {
  let document = @parser.parse("#    Hello\n\n-   A\n- B")
  assert_eq(format(document), "# Hello\n\n- A\n- B\n")
}
