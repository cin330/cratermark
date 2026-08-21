///|
priv struct ReferenceDefinition {
  id : String
  target : String
}

///|
fn find_marker(source : String, marker : String, start : Int) -> Int {
  if start >= source.length() {
    return -1
  }
  match source[start:].find(marker) {
    Some(offset) => start + offset
    None => -1
  }
}

///|
fn whitespace(char : Char?) -> Bool {
  char == Some(' ') || char == Some('\t') || char == Some('\r')
}

///|
/// Collapses every whitespace run into a single space and trims the edges.
fn collapse_whitespace(value : String) -> String {
  let out = StringBuilder()
  let mut pending_space = false
  let mut has_content = false
  for char in value {
    if char == ' ' || char == '\t' || char == '\r' || char == '\n' {
      pending_space = has_content
    } else {
      if pending_space {
        out.write_char(' ')
        pending_space = false
      }
      out.write_char(char)
      has_content = true
    }
  }
  out.to_string()
}

///|
fn normalize_reference_id(value : String) -> String {
  collapse_whitespace(value).to_lower()
}

///|
fn definition_target(value : String) -> String {
  let rest = value.trim().to_owned()
  if rest.is_empty() {
    return ""
  }
  if rest.get_char(0) == Some('<') {
    let close = find_marker(rest, ">", 1)
    if close > 1 {
      return rest[1:close].to_owned()
    }
    return ""
  }
  let mut end = 0
  while end < rest.length() && !whitespace(rest.get_char(end)) {
    end = end + 1
  }
  rest[:end].to_owned()
}

///|
fn parse_reference_definition(line : String) -> ReferenceDefinition? {
  let value = line.trim().to_owned()
  if !value.has_prefix("[") || value.has_prefix("![") {
    return None
  }
  let close = find_marker(value, "]:", 1)
  if close <= 1 {
    return None
  }
  let id = normalize_reference_id(value[1:close].to_owned())
  let target = definition_target(value[close + 2:].to_owned())
  if id.is_empty() || target.is_empty() {
    None
  } else {
    Some({ id, target })
  }
}

///|
fn find_reference(
  definitions : Array[ReferenceDefinition],
  id : String,
) -> String? {
  let wanted = normalize_reference_id(id)
  for definition in definitions {
    if definition.id == wanted {
      return Some(definition.target)
    }
  }
  None
}

///|
fn collect_reference_definitions(
  content : String,
) -> Array[ReferenceDefinition] {
  let definitions : Array[ReferenceDefinition] = []
  let mut fenced = false
  for part in content.split("\n") {
    let line = part.to_owned()
    let trimmed = line.trim().to_owned()
    if trimmed.has_prefix("```") || trimmed.has_prefix("~~~") {
      fenced = !fenced
      continue
    }
    if fenced {
      continue
    }
    match parse_reference_definition(line) {
      Some(definition) =>
        if find_reference(definitions, definition.id) is None {
          definitions.push(definition)
        }
      None => ()
    }
  }
  definitions
}

///|
fn blank_run(count : Int) -> String {
  let out = StringBuilder()
  for index = 0; index < count; index = index + 1 {
    out.write_char(' ')
  }
  out.to_string()
}

///|
/// Returns a copy of `content` in which fenced code blocks and HTML comments
/// are replaced by spaces. Length, offsets, and line breaks are preserved, so
/// a position found in the mask is also valid in the original source.
fn mask_unscannable(content : String) -> String {
  let out = StringBuilder()
  let mut fenced = false
  let mut comment = false
  let mut first = true
  for part in content.split("\n") {
    let line = part.to_owned()
    if !first {
      out.write_char('\n')
    }
    first = false
    let trimmed = line.trim().to_owned()
    if trimmed.has_prefix("```") || trimmed.has_prefix("~~~") {
      fenced = !fenced
      out.write_string(blank_run(line.length()))
      continue
    }
    if fenced {
      out.write_string(blank_run(line.length()))
      continue
    }
    let mut index = 0
    while index < line.length() {
      if comment {
        let close = find_marker(line, "-->", index)
        if close < 0 {
          out.write_string(blank_run(line.length() - index))
          index = line.length()
        } else {
          out.write_string(blank_run(close + 3 - index))
          index = close + 3
          comment = false
        }
        continue
      }
      let open = find_marker(line, "<!--", index)
      if open < 0 {
        out.write_string(line[index:].to_owned())
        index = line.length()
        continue
      }
      out.write_string(line[index:open].to_owned())
      index = open
      comment = true
    }
  }
  out.to_string()
}

///|
/// Translates a zero-based offset into a one-based line and column pair.
fn offset_position(content : String, offset : Int) -> (Int, Int) {
  let limit = if offset < content.length() { offset } else { content.length() }
  let mut line = 1
  let mut column = 1
  for index = 0; index < limit; index = index + 1 {
    if content.get_char(index) == Some('\n') {
      line = line + 1
      column = 1
    } else {
      column = column + 1
    }
  }
  (line, column)
}

///|
fn push_supplemental_link(
  source : String,
  label : String,
  target : String,
  image : Bool,
  line : Int,
  column : Int,
  links : Array[LinkRef],
) -> Unit {
  let (target_path, fragment, kind, escaped_root) = resolve_target(
    source, target, image,
  )
  links.push({
    source,
    label,
    raw_target: target,
    target_path,
    fragment,
    kind,
    line,
    column,
    escaped_root,
  })
}

///|
/// Extracts full (`[text][id]`), collapsed (`[text][]`), and shortcut
/// (`[text]`) reference links from one already masked source line. A shortcut
/// becomes a link only when a matching definition exists; otherwise the
/// brackets are ordinary text and are left alone.
fn collect_reference_links(
  source : String,
  line_text : String,
  line_number : Int,
  definitions : Array[ReferenceDefinition],
  links : Array[LinkRef],
  diagnostics : Array[Diagnostic],
) -> Unit {
  if parse_reference_definition(line_text) is Some(_) {
    return
  }
  let mut index = 0
  while index < line_text.length() {
    if line_text.get_char(index) == Some('`') {
      let close = find_marker(line_text, "`", index + 1)
      if close >= 0 {
        index = close + 1
        continue
      }
    }
    let image = line_text[index:].has_prefix("![")
    let open = if image { index + 1 } else { index }
    if line_text.get_char(open) != Some('[') {
      index = index + 1
      continue
    }
    let label_end = find_marker(line_text, "]", open + 1)
    if label_end < 0 {
      index = index + 1
      continue
    }
    let label = line_text[open + 1:label_end].to_owned()
    let next = line_text.get_char(label_end + 1)
    if next != Some('[') {
      // Inline links come from the Markdown parser and definitions are
      // collected separately, so only a resolvable shortcut is a link here.
      if next == Some('(') || next == Some(':') {
        index = index + 1
        continue
      }
      match find_reference(definitions, label) {
        Some(target) => {
          push_supplemental_link(
            source,
            collapse_whitespace(label),
            target,
            image,
            line_number,
            index + 1,
            links,
          )
          index = label_end + 1
        }
        None => index = index + 1
      }
      continue
    }
    let reference_end = find_marker(line_text, "]", label_end + 2)
    if reference_end < 0 {
      index = index + 1
      continue
    }
    let explicit_id = line_text[label_end + 2:reference_end].to_owned()
    let id = if explicit_id.trim().is_empty() { label } else { explicit_id }
    match find_reference(definitions, id) {
      Some(target) =>
        push_supplemental_link(
          source,
          collapse_whitespace(label),
          target,
          image,
          line_number,
          index + 1,
          links,
        )
      None => {
        let reference_id = normalize_reference_id(id)
        diagnostics.push({
          code: "CMG009",
          severity: Error,
          file: source,
          line: line_number,
          column: index + 1,
          message: "Reference definition '[\{reference_id}]' does not exist.",
          target: reference_id,
        })
      }
    }
    index = reference_end + 1
  }
}

///|
fn html_name_boundary(char : Char?) -> Bool {
  whitespace(char) ||
  char == Some('\n') ||
  char == Some('>') ||
  char == Some('/')
}

///|
/// Replaces line breaks inside a tag with spaces so attribute scanning does
/// not need to know whether the tag was written on one line or several.
fn flatten_tag(value : String) -> String {
  let out = StringBuilder()
  for char in value {
    if char == '\n' {
      out.write_char(' ')
    } else {
      out.write_char(char)
    }
  }
  out.to_string()
}

///|
fn html_attribute(tag : String, name : String) -> String? {
  let lower = tag.to_lower()
  let mut search_at = 0
  while search_at < lower.length() {
    let at = find_marker(lower, name, search_at)
    if at < 0 {
      return None
    }
    let valid_before = at == 0 || whitespace(lower.get_char(at - 1))
    let mut cursor = at + name.length()
    if !valid_before {
      search_at = cursor
      continue
    }
    while cursor < tag.length() && whitespace(tag.get_char(cursor)) {
      cursor = cursor + 1
    }
    if tag.get_char(cursor) != Some('=') {
      search_at = cursor
      continue
    }
    cursor = cursor + 1
    while cursor < tag.length() && whitespace(tag.get_char(cursor)) {
      cursor = cursor + 1
    }
    let quote = tag.get_char(cursor)
    if quote == Some('"') || quote == Some('\'') {
      let start = cursor + 1
      cursor = start
      while cursor < tag.length() && tag.get_char(cursor) != quote {
        cursor = cursor + 1
      }
      return Some(tag[start:cursor].to_owned())
    }
    let start = cursor
    while cursor < tag.length() &&
          !whitespace(tag.get_char(cursor)) &&
          tag.get_char(cursor) != Some('>') {
      cursor = cursor + 1
    }
    return Some(tag[start:cursor].to_owned())
  }
  None
}

///|
/// Reports whether `position` sits inside inline code. Backtick counting
/// restarts on every line, so one unbalanced backtick cannot hide the rest of
/// the document.
fn inside_inline_code(text : String, position : Int) -> Bool {
  let mut ticks = 0
  for index = 0; index < position; index = index + 1 {
    match text.get_char(index) {
      Some('\n') => ticks = 0
      Some('`') => ticks = ticks + 1
      _ => ()
    }
  }
  ticks % 2 == 1
}

///|
/// Extracts raw-HTML `<a>` and `<img>` targets from the whole document. The
/// scan runs over the masked copy but reads attributes from the original
/// source, which lets an opening tag span several lines.
fn collect_html_links(
  source : String,
  content : String,
  masked : String,
  links : Array[LinkRef],
) -> Unit {
  let lower = masked.to_lower()
  let mut index = 0
  while index < lower.length() {
    let is_anchor = lower[index:].has_prefix("<a") &&
      html_name_boundary(lower.get_char(index + 2))
    let is_image = lower[index:].has_prefix("<img") &&
      html_name_boundary(lower.get_char(index + 4))
    if (!is_anchor && !is_image) || inside_inline_code(masked, index) {
      index = index + 1
      continue
    }
    let tag_end = find_marker(masked, ">", index + 1)
    if tag_end < 0 {
      return
    }
    let tag = flatten_tag(content[index:tag_end + 1].to_owned())
    let attribute = if is_image { "src" } else { "href" }
    match html_attribute(tag, attribute) {
      Some(target) => {
        let label = if is_image {
          html_attribute(tag, "alt").unwrap_or("")
        } else {
          let close = find_marker(lower, "</a>", tag_end + 1)
          if close >= 0 {
            collapse_whitespace(content[tag_end + 1:close].to_owned())
          } else {
            ""
          }
        }
        let (line, column) = offset_position(content, index)
        push_supplemental_link(
          source, label, target, is_image, line, column, links,
        )
      }
      None => ()
    }
    index = tag_end + 1
  }
}

///|
fn collect_supplemental_links(
  source : String,
  content : String,
  links : Array[LinkRef],
  diagnostics : Array[Diagnostic],
) -> Unit {
  let definitions = collect_reference_definitions(content)
  let masked = mask_unscannable(content)
  for line_index, part in masked.split("\n") {
    collect_reference_links(
      source,
      part.to_owned(),
      line_index + 1,
      definitions,
      links,
      diagnostics,
    )
  }
  collect_html_links(source, content, masked, links)
}
