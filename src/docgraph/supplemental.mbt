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
fn normalize_reference_id(value : String) -> String {
  let out = StringBuilder()
  let mut pending_space = false
  let mut has_content = false
  for char in value.trim().to_owned().to_lower() {
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
    if label_end < 0 || line_text.get_char(label_end + 1) != Some('[') {
      index = index + 1
      continue
    }
    let reference_end = find_marker(line_text, "]", label_end + 2)
    if reference_end < 0 {
      index = index + 1
      continue
    }
    let label = line_text[open + 1:label_end].to_owned()
    let explicit_id = line_text[label_end + 2:reference_end].to_owned()
    let id = if explicit_id.trim().is_empty() { label } else { explicit_id }
    match find_reference(definitions, id) {
      Some(target) =>
        push_supplemental_link(
          source,
          label,
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
  whitespace(char) || char == Some('>') || char == Some('/')
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
fn inside_inline_code(line : String, position : Int) -> Bool {
  let mut ticks = 0
  for index = 0; index < position; index = index + 1 {
    if line.get_char(index) == Some('`') {
      ticks = ticks + 1
    }
  }
  ticks % 2 == 1
}

///|
fn collect_html_links(
  source : String,
  line_text : String,
  line_number : Int,
  links : Array[LinkRef],
) -> Unit {
  let lower = line_text.to_lower()
  let mut index = 0
  while index < lower.length() {
    let is_anchor = lower[index:].has_prefix("<a") &&
      html_name_boundary(lower.get_char(index + 2))
    let is_image = lower[index:].has_prefix("<img") &&
      html_name_boundary(lower.get_char(index + 4))
    if (!is_anchor && !is_image) || inside_inline_code(line_text, index) {
      index = index + 1
      continue
    }
    let tag_end = find_marker(line_text, ">", index + 1)
    if tag_end < 0 {
      return
    }
    let tag = line_text[index:tag_end + 1].to_owned()
    let attribute = if is_image { "src" } else { "href" }
    match html_attribute(tag, attribute) {
      Some(target) => {
        let label = if is_image {
          html_attribute(tag, "alt").unwrap_or("")
        } else {
          let close = find_marker(lower, "</a>", tag_end + 1)
          if close >= 0 {
            line_text[tag_end + 1:close].to_owned().trim().to_owned()
          } else {
            ""
          }
        }
        push_supplemental_link(
          source,
          label,
          target,
          is_image,
          line_number,
          index + 1,
          links,
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
  let mut fenced = false
  for line_index, part in content.split("\n") {
    let line = part.to_owned()
    let trimmed = line.trim().to_owned()
    if trimmed.has_prefix("```") || trimmed.has_prefix("~~~") {
      fenced = !fenced
      continue
    }
    if fenced || trimmed.has_prefix("<!--") {
      continue
    }
    collect_reference_links(
      source,
      line,
      line_index + 1,
      definitions,
      links,
      diagnostics,
    )
    collect_html_links(source, line, line_index + 1, links)
  }
}
