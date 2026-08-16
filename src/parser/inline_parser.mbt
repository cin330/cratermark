///|
fn inline_position(
  line : Int,
  start_column : Int,
  start : Int,
  end : Int,
) -> @ast.Position {
  {
    start_line: line,
    start_column: start_column + start,
    end_line: line,
    end_column: start_column + end,
  }
}

///|
fn find_from(source : String, marker : String, start : Int) -> Int? {
  if start >= source.length() {
    return None
  }
  match source[start:].find(marker) {
    Some(offset) => Some(start + offset)
    None => None
  }
}

///|
fn push_text(
  output : Array[@ast.Inline],
  source : String,
  start : Int,
  end : Int,
  line : Int,
  start_column : Int,
) -> Unit {
  if end > start {
    output.push(
      @ast.Text(
        source[start:end].to_owned(),
        inline_position(line, start_column, start, end),
      ),
    )
  }
}

///|
/// Parse inline Markdown independently from block parsing.
pub fn parse_inlines(
  source : String,
  line : Int,
  start_column : Int,
) -> Array[@ast.Inline] {
  let output : Array[@ast.Inline] = []
  let mut index = 0
  let mut text_start = 0
  let length = source.length()
  while index < length {
    if source[index:].has_prefix("![") {
      match find_from(source, "](", index + 2) {
        Some(label_end) =>
          match find_from(source, ")", label_end + 2) {
            Some(url_end) => {
              push_text(output, source, text_start, index, line, start_column)
              let alt = source[index + 2:label_end].to_owned()
              let url = source[label_end + 2:url_end].to_owned()
              output.push(
                @ast.Image(
                  alt,
                  url,
                  inline_position(line, start_column, index, url_end + 1),
                ),
              )
              index = url_end + 1
              text_start = index
              continue
            }
            None => ()
          }
        None => ()
      }
    }
    if source[index:].has_prefix("[") {
      match find_from(source, "](", index + 1) {
        Some(label_end) =>
          match find_from(source, ")", label_end + 2) {
            Some(url_end) => {
              push_text(output, source, text_start, index, line, start_column)
              let label = source[index + 1:label_end].to_owned()
              let url = source[label_end + 2:url_end].to_owned()
              output.push(
                @ast.Link(
                  parse_inlines(label, line, start_column + index + 1),
                  url,
                  inline_position(line, start_column, index, url_end + 1),
                ),
              )
              index = url_end + 1
              text_start = index
              continue
            }
            None => ()
          }
        None => ()
      }
    }
    if source[index:].has_prefix("**") {
      match find_from(source, "**", index + 2) {
        Some(close) if close > index + 2 => {
          push_text(output, source, text_start, index, line, start_column)
          let inner = source[index + 2:close].to_owned()
          output.push(
            @ast.Strong(
              parse_inlines(inner, line, start_column + index + 2),
              inline_position(line, start_column, index, close + 2),
            ),
          )
          index = close + 2
          text_start = index
          continue
        }
        _ => ()
      }
    }
    if source[index:].has_prefix("`") {
      match find_from(source, "`", index + 1) {
        Some(close) if close > index + 1 => {
          push_text(output, source, text_start, index, line, start_column)
          output.push(
            @ast.InlineCode(
              source[index + 1:close].to_owned(),
              inline_position(line, start_column, index, close + 1),
            ),
          )
          index = close + 1
          text_start = index
          continue
        }
        _ => ()
      }
    }
    let marker = if source[index:].has_prefix("*") {
      "*"
    } else if source[index:].has_prefix("_") {
      "_"
    } else {
      ""
    }
    if marker != "" {
      match find_from(source, marker, index + 1) {
        Some(close) if close > index + 1 => {
          push_text(output, source, text_start, index, line, start_column)
          let inner = source[index + 1:close].to_owned()
          output.push(
            @ast.Emphasis(
              parse_inlines(inner, line, start_column + index + 1),
              inline_position(line, start_column, index, close + 1),
            ),
          )
          index = close + 1
          text_start = index
          continue
        }
        _ => ()
      }
    }
    index = index + 1
  }
  push_text(output, source, text_start, length, line, start_column)
  output
}
