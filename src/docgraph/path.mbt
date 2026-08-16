///|
fn join_parts(parts : Array[String]) -> String {
  let out = StringBuilder()
  for index, part in parts {
    if index > 0 {
      out.write_char('/')
    }
    out.write_string(part)
  }
  out.to_string()
}

///|
fn normalize_path_detail(path : String) -> (String, Bool) {
  let value = path.replace_all(old="\\", new="/")
  let parts = value.split("/").map(fn(part) { part.to_owned() }).to_array()
  let stack : Array[String] = []
  let mut escaped = false
  for part in parts {
    if part.is_empty() || part == "." {
      continue
    }
    if part == ".." {
      if stack.length() > 0 {
        let _ = stack.pop()
      } else {
        escaped = true
      }
    } else {
      stack.push(part)
    }
  }
  (join_parts(stack), escaped)
}

///|
/// Normalize a repository-relative path using forward slashes.
pub fn normalize_path(path : String) -> String {
  normalize_path_detail(path).0
}

///|
pub fn dirname(path : String) -> String {
  let normalized = normalize_path(path)
  let parts = normalized.split("/").map(fn(part) { part.to_owned() }).to_array()
  if parts.length() <= 1 {
    return ""
  }
  let _ = parts.pop()
  join_parts(parts)
}

///|
fn join_relative(base : String, target : String) -> (String, Bool) {
  if target.has_prefix("/") {
    return normalize_path_detail(target[1:].to_owned())
  }
  if base.is_empty() {
    normalize_path_detail(target)
  } else {
    normalize_path_detail(base + "/" + target)
  }
}

///|
fn split_target(raw : String) -> (String, String) {
  let value = raw.trim().to_owned()
  let mut fragment_at = -1
  for index = 0; index < value.length(); index = index + 1 {
    if value.get_char(index) == Some('#') {
      fragment_at = index
      break
    }
  }
  let (before_fragment, fragment) = if fragment_at >= 0 {
    (value[:fragment_at].to_owned(), value[fragment_at + 1:].to_owned())
  } else {
    (value, "")
  }
  let mut query_at = -1
  for index = 0; index < before_fragment.length(); index = index + 1 {
    if before_fragment.get_char(index) == Some('?') {
      query_at = index
      break
    }
  }
  let path = if query_at >= 0 {
    before_fragment[:query_at].to_owned()
  } else {
    before_fragment
  }
  (path, fragment)
}

///|
pub fn is_external_target(target : String) -> Bool {
  let value = target.trim().to_owned().to_lower()
  value.contains("://") ||
  value.has_prefix("mailto:") ||
  value.has_prefix("tel:") ||
  value.has_prefix("data:") ||
  value.has_prefix("javascript:")
}

///|
pub fn is_unsafe_target(target : String) -> Bool {
  let value = target.trim().to_owned().to_lower()
  value.has_prefix("javascript:") || value.has_prefix("data:text/html")
}

///|
pub fn is_markdown_path(path : String) -> Bool {
  let value = path.to_lower()
  value.has_suffix(".md") ||
  value.has_suffix(".markdown") ||
  value.has_suffix(".mdx")
}

///|
pub fn is_document_asset(path : String) -> Bool {
  let value = path.to_lower()
  value.has_suffix(".png") ||
  value.has_suffix(".jpg") ||
  value.has_suffix(".jpeg") ||
  value.has_suffix(".gif") ||
  value.has_suffix(".webp") ||
  value.has_suffix(".svg") ||
  value.has_suffix(".pdf") ||
  value.has_suffix(".zip") ||
  value.has_suffix(".json")
}

///|
fn classify_relative_target(path : String, image : Bool) -> LinkKind {
  if image {
    return AssetLink
  }
  if path.is_empty() || is_markdown_path(path) || !path.contains(".") {
    DocumentLink
  } else {
    AssetLink
  }
}

///|
fn resolve_target(
  source : String,
  raw : String,
  image : Bool,
) -> (String, String, LinkKind, Bool) {
  if is_external_target(raw) {
    return (raw, "", ExternalLink, false)
  }
  let (path, fragment) = split_target(raw)
  let kind = classify_relative_target(path, image)
  if path.is_empty() {
    return (normalize_path(source), fragment, kind, false)
  }
  let (resolved, escaped) = join_relative(dirname(source), path)
  (resolved, fragment, kind, escaped)
}
