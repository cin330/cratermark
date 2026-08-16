///|
/// Build a predictable GitHub-style heading anchor.
pub fn slugify(value : String) -> String {
  let out = StringBuilder()
  let mut pending_dash = false
  for char in value.to_lower().iter() {
    if char.is_ascii_alphabetic() || char.is_ascii_digit() || !char.is_ascii() {
      if pending_dash && !out.is_empty() {
        out.write_char('-')
      }
      pending_dash = false
      out.write_char(char)
    } else if char.is_whitespace() || char == '-' || char == '_' {
      pending_dash = true
    }
  }
  out.to_string()
}
