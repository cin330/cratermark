///|
struct ScanConfig {
  entries : Array[String]
  exclusions : Array[String]
}

///|
fn disk_join(root : String, relative : String) -> String {
  if relative.is_empty() || relative == "." {
    root
  } else if root.has_suffix("/") || root.has_suffix("\\") {
    root + relative
  } else {
    root + "/" + relative
  }
}

///|
fn quoted_values(line : String) -> Array[String] {
  let values : Array[String] = []
  let out = StringBuilder()
  let mut quoted = false
  for char in line {
    if char == '"' {
      if quoted {
        values.push(out.to_string())
        out.reset()
      }
      quoted = !quoted
    } else if quoted {
      out.write_char(char)
    }
  }
  values
}

///|
fn parse_scan_config(source : String) -> ScanConfig {
  let entries : Array[String] = []
  let exclusions : Array[String] = []
  for part in source.split("\n") {
    let line = part.trim().to_owned()
    if line.has_prefix("entries") {
      for value in quoted_values(line) {
        entries.push(@docgraph.normalize_path(value))
      }
    } else if line.has_prefix("exclude") {
      for value in quoted_values(line) {
        exclusions.push(@docgraph.normalize_path(value))
      }
    }
  }
  { entries, exclusions }
}

///|
fn load_scan_config(root : String) -> ScanConfig {
  let path = disk_join(root, "cratermark.toml")
  if !@fs.path_exists(path) {
    return { entries: [], exclusions: [] }
  }
  let source = @fs.read_file_to_string(path) catch {
    _ => return { entries: [], exclusions: [] }
  }
  parse_scan_config(source)
}

///|
fn ignored_directory(name : String) -> Bool {
  name == ".git" ||
  name == ".mooncakes" ||
  name == "_build" ||
  name == "node_modules" ||
  name == ".idea" ||
  name == ".vscode"
}

///|
fn excluded(relative : String, exclusions : Array[String]) -> Bool {
  let path = @docgraph.normalize_path(relative)
  for pattern in exclusions {
    if path == pattern || path.has_prefix(pattern + "/") {
      return true
    }
  }
  false
}

///|
fn collect_directory(
  root : String,
  relative : String,
  exclusions : Array[String],
  documents : Array[@docgraph.SourceFile],
  assets : Array[String],
) -> Unit raise @fs.IOError {
  let full = disk_join(root, relative)
  let entries = @fs.read_dir(full)
  entries.sort()
  for name in entries {
    if ignored_directory(name) {
      continue
    }
    let child_relative = if relative.is_empty() {
      name
    } else {
      relative + "/" + name
    }
    if excluded(child_relative, exclusions) {
      continue
    }
    let child_full = disk_join(root, child_relative)
    if @fs.is_dir(child_full) {
      collect_directory(root, child_relative, exclusions, documents, assets)
    } else if @docgraph.is_markdown_path(child_relative) {
      let source = @fs.read_file_to_string(child_full)
      documents.push(@docgraph.SourceFile::new(child_relative, source))
    } else if @docgraph.is_document_asset(child_relative) {
      assets.push(@docgraph.normalize_path(child_relative))
    }
  }
}

///|
fn scan_workspace(
  root : String,
  entry_override : String?,
) -> @docgraph.Workspace? {
  let documents : Array[@docgraph.SourceFile] = []
  let assets : Array[String] = []
  let config = load_scan_config(root)
  let root_is_dir = @fs.is_dir(root) catch { _ => false }
  if root_is_dir {
    collect_directory(root, "", config.exclusions, documents, assets) catch {
      @fs.IOError(message) => {
        println("cratermark: unable to scan '\{root}': \{message}")
        return None
      }
    }
  } else {
    let source = @fs.read_file_to_string(root) catch {
      @fs.IOError(message) => {
        println("cratermark: unable to read '\{root}': \{message}")
        return None
      }
    }
    documents.push(@docgraph.SourceFile::new("README.md", source))
  }
  let entries = match entry_override {
    Some(entry) => [@docgraph.normalize_path(entry)]
    None => config.entries
  }
  Some(@docgraph.Workspace::new(documents, assets~, entries~))
}
