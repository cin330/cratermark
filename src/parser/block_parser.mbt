///|
fn heading_level(line : String) -> Int {
  let mut level = 0
  while level < line.length() && level < 6 && line.get_char(level) == Some('#') {
    level = level + 1
  }
  if level > 0 && level < line.length() && line.get_char(level) == Some(' ') {
    level
  } else {
    0
  }
}

///|
fn is_fence(line : String) -> Bool {
  line.trim().has_prefix("```")
}

///|
fn is_rule(line : String) -> Bool {
  let value = line.trim()
  value == "---" || value == "***" || value == "___"
}

///|
fn list_marker(line : String) -> (Bool, Int, Int)? {
  if line.has_prefix("- ") || line.has_prefix("* ") || line.has_prefix("+ ") {
    return Some((false, 1, 2))
  }
  let mut index = 0
  let mut number = 0
  while index < line.length() {
    match line.get_char(index) {
      Some(char) if char.is_ascii_digit() => {
        number = number * 10 + char.to_int() - '0'.to_int()
        index = index + 1
      }
      _ => break
    }
  }
  if index > 0 &&
    index + 1 < line.length() &&
    line.get_char(index) == Some('.') &&
    line.get_char(index + 1) == Some(' ') {
    Some((true, number, index + 2))
  } else {
    None
  }
}

///|
fn is_block_start(line : String) -> Bool {
  heading_level(line) > 0 ||
  is_fence(line) ||
  is_rule(line) ||
  line.trim().has_prefix(">") ||
  list_marker(line) is Some(_)
}

///|
fn join_lines(
  lines : Array[String],
  start : Int,
  end : Int,
  separator : String,
) -> String {
  let out = StringBuilder()
  for index = start; index < end; index = index + 1 {
    if index > start {
      out.write_string(separator)
    }
    out.write_string(lines[index])
  }
  out.to_string()
}

///|
fn parse_blocks(lines : Array[String], base_line : Int) -> Array[@ast.Block] {
  let blocks : Array[@ast.Block] = []
  let mut index = 0
  while index < lines.length() {
    let line = lines[index]
    if line.is_blank() {
      index = index + 1
      continue
    }
    let line_number = base_line + index
    let level = heading_level(line)
    if level > 0 {
      let value = line[level + 1:].trim().to_owned()
      let pos = @ast.Position::line(line_number, line.length() + 1)
      blocks.push(
        @ast.Heading(level, parse_inlines(value, line_number, level + 2), pos),
      )
      index = index + 1
      continue
    }
    if is_fence(line) {
      let start = index
      let info = line.trim().to_owned()[3:].trim().to_owned()
      index = index + 1
      let content_start = index
      while index < lines.length() && !is_fence(lines[index]) {
        index = index + 1
      }
      let code = join_lines(lines, content_start, index, "\n")
      if index < lines.length() {
        index = index + 1
      }
      let pos : @ast.Position = {
        start_line: base_line + start,
        start_column: 1,
        end_line: base_line + index - 1,
        end_column: if index > 0 {
          lines[index - 1].length() + 1
        } else {
          1
        },
      }
      blocks.push(@ast.CodeBlock(info, code, pos))
      continue
    }
    if is_rule(line) {
      blocks.push(
        @ast.HorizontalRule(@ast.Position::line(line_number, line.length() + 1)),
      )
      index = index + 1
      continue
    }
    if line.trim().has_prefix(">") {
      let start = index
      let quoted : Array[String] = []
      while index < lines.length() && lines[index].trim().has_prefix(">") {
        let raw = lines[index].trim().to_owned()
        let value = raw[1:].trim_start().to_owned()
        quoted.push(value)
        index = index + 1
      }
      let pos : @ast.Position = {
        start_line: base_line + start,
        start_column: 1,
        end_line: base_line + index - 1,
        end_column: lines[index - 1].length() + 1,
      }
      blocks.push(@ast.BlockQuote(parse_blocks(quoted, base_line + start), pos))
      continue
    }
    match list_marker(line) {
      Some((ordered, first_number, _)) => {
        let start = index
        let items : Array[@ast.ListItem] = []
        while index < lines.length() {
          match list_marker(lines[index]) {
            Some((item_ordered, _, content_start)) if item_ordered == ordered => {
              let item_line = lines[index]
              let value = item_line[content_start:].trim_end().to_owned()
              let item_pos = @ast.Position::line(
                base_line + index,
                item_line.length() + 1,
              )
              items.push({
                children: [
                  @ast.Paragraph(
                    parse_inlines(value, base_line + index, content_start + 1),
                    item_pos,
                  ),
                ],
                position: item_pos,
              })
              index = index + 1
            }
            _ => break
          }
        }
        let pos : @ast.Position = {
          start_line: base_line + start,
          start_column: 1,
          end_line: base_line + index - 1,
          end_column: lines[index - 1].length() + 1,
        }
        blocks.push(@ast.List(ordered, first_number, items, pos))
        continue
      }
      None => ()
    }
    let start = index
    index = index + 1
    while index < lines.length() &&
          !lines[index].is_blank() &&
          !is_block_start(lines[index]) {
      index = index + 1
    }
    let value = join_lines(lines, start, index, " ").trim().to_owned()
    let pos : @ast.Position = {
      start_line: base_line + start,
      start_column: 1,
      end_line: base_line + index - 1,
      end_column: lines[index - 1].length() + 1,
    }
    blocks.push(@ast.Paragraph(parse_inlines(value, line_number, 1), pos))
  }
  blocks
}

///|
/// Parse a Markdown source string into CraterMark's structured AST.
pub fn parse(source : String) -> @ast.Document {
  let normalized = source
    .replace_all(old="\r\n", new="\n")
    .replace_all(old="\r", new="\n")
  let lines = normalized
    .split("\n")
    .map(fn(part) { part.to_owned() })
    .to_array()
  @ast.Document::new(parse_blocks(lines, 1), normalized)
}
