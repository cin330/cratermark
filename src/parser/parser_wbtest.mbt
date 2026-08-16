///|
test "parse ATX heading and source position" {
  let document = parse("# Hello")
  assert_eq(document.children.length(), 1)
  match document.children[0] {
    @ast.Heading(level, children, position) => {
      assert_eq(level, 1)
      assert_eq(@ast.inline_plain_text(children), "Hello")
      assert_eq(position.start_line, 1)
    }
    _ => fail("expected heading")
  }
}

///|
test "parse level six heading" {
  let document = parse("###### Deep")
  assert_true(document.children[0] is @ast.Heading(6, _, _))
}

///|
test "reject invalid level seven heading" {
  let document = parse("####### Not a heading")
  assert_true(document.children[0] is @ast.Paragraph(_, _))
}

///|
test "join paragraph continuation lines" {
  let document = parse("Hello\nworld")
  match document.children[0] {
    @ast.Paragraph(children, _) =>
      assert_eq(@ast.inline_plain_text(children), "Hello world")
    _ => fail("expected paragraph")
  }
}

///|
test "parse strong emphasis inline code link and image" {
  let document = parse(
    "**bold** *italic* `code` [site](https://example.com) ![alt](img.png)",
  )
  match document.children[0] {
    @ast.Paragraph(children, _) => {
      assert_true(children[0] is @ast.Strong(_, _))
      assert_true(children[2] is @ast.Emphasis(_, _))
      assert_true(children[4] is @ast.InlineCode("code", _))
      assert_true(children[6] is @ast.Link(_, "https://example.com", _))
      assert_true(children[8] is @ast.Image("alt", "img.png", _))
    }
    _ => fail("expected paragraph")
  }
}

///|
test "parse fenced code block with language" {
  let document = parse("```moonbit\nfn main {}\n```")
  assert_true(
    document.children[0] is @ast.CodeBlock("moonbit", "fn main {}", _),
  )
}

///|
test "parse unclosed fenced code block through EOF" {
  let document = parse("```text\nhello")
  assert_true(document.children[0] is @ast.CodeBlock("text", "hello", _))
}

///|
test "parse block quote" {
  let document = parse("> quoted text")
  match document.children[0] {
    @ast.BlockQuote(children, _) =>
      assert_true(children[0] is @ast.Paragraph(_, _))
    _ => fail("expected quote")
  }
}

///|
test "parse unordered list" {
  let document = parse("- Apple\n- Banana")
  match document.children[0] {
    @ast.List(ordered, start, items, _) => {
      assert_false(ordered)
      assert_eq(start, 1)
      assert_eq(items.length(), 2)
    }
    _ => fail("expected list")
  }
}

///|
test "parse ordered list start" {
  let document = parse("3. Three\n4. Four")
  assert_true(document.children[0] is @ast.List(true, 3, _, _))
}

///|
test "parse horizontal rule" {
  let document = parse("---")
  assert_true(document.children[0] is @ast.HorizontalRule(_))
}

///|
test "normalize CRLF" {
  let document = parse("# A\r\n\r\nB")
  assert_eq(document.children.length(), 2)
  assert_eq(document.source, "# A\n\nB")
}
