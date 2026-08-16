///|
fn diagnostic(
  code : String,
  severity : Severity,
  link : LinkRef,
  message : String,
) -> Diagnostic {
  {
    code,
    severity,
    file: link.source,
    line: link.line,
    column: link.column,
    message,
    target: link.raw_target,
  }
}

///|
fn find_document(documents : Array[DocumentNode], path : String) -> Int {
  for index, document in documents {
    if document.path == path {
      return index
    }
  }
  -1
}

///|
fn find_document_case_insensitive(
  documents : Array[DocumentNode],
  path : String,
) -> Int {
  let wanted = path.to_lower()
  for index, document in documents {
    if document.path.to_lower() == wanted {
      return index
    }
  }
  -1
}

///|
fn find_path(paths : Array[String], path : String) -> Int {
  for index, current in paths {
    if current == path {
      return index
    }
  }
  -1
}

///|
fn find_path_case_insensitive(paths : Array[String], path : String) -> Int {
  let wanted = path.to_lower()
  for index, current in paths {
    if current.to_lower() == wanted {
      return index
    }
  }
  -1
}

///|
fn heading_exists(document : DocumentNode, fragment : String) -> Bool {
  if fragment.is_empty() {
    return true
  }
  let wanted = fragment.to_lower()
  document.headings.any(fn(heading) { heading.anchor.to_lower() == wanted })
}

///|
fn default_entries(
  configured : Array[String],
  documents : Array[DocumentNode],
) -> Array[String] {
  if configured.length() > 0 {
    return configured.map(normalize_path)
  }
  for document in documents {
    if document.path.to_lower() == "readme.md" {
      return [document.path]
    }
  }
  if documents.length() > 0 {
    [documents[0].path]
  } else {
    []
  }
}

///|
fn compute_reachable(
  entries : Array[String],
  documents : Array[DocumentNode],
  edges : Array[GraphEdge],
) -> Array[String] {
  let reachable : Array[String] = []
  let queue : Array[String] = []
  for entry in entries {
    let exact = find_document(documents, entry)
    if exact >= 0 && !reachable.contains(documents[exact].path) {
      reachable.push(documents[exact].path)
      queue.push(documents[exact].path)
    }
  }
  let mut cursor = 0
  while cursor < queue.length() {
    let current = queue[cursor]
    cursor = cursor + 1
    for edge in edges {
      if edge.kind == DocumentLink &&
        edge.source == current &&
        !reachable.contains(edge.target) {
        reachable.push(edge.target)
        queue.push(edge.target)
      }
    }
  }
  reachable
}

///|
fn count_stats(
  documents : Array[DocumentNode],
  links : Array[LinkRef],
  assets : Array[String],
  reachable : Array[String],
  diagnostics : Array[Diagnostic],
) -> GraphStats {
  let mut headings = 0
  for document in documents {
    headings = headings + document.headings.length()
  }
  let mut internal_links = 0
  let mut external_links = 0
  let mut asset_links = 0
  for link in links {
    match link.kind {
      DocumentLink => internal_links = internal_links + 1
      ExternalLink => external_links = external_links + 1
      AssetLink => asset_links = asset_links + 1
    }
  }
  let mut errors = 0
  let mut warnings = 0
  for item in diagnostics {
    match item.severity {
      Error => errors = errors + 1
      Warning => warnings = warnings + 1
    }
  }
  {
    documents: documents.length(),
    headings,
    internal_links,
    external_links,
    asset_links,
    assets: assets.length(),
    reachable_documents: reachable.length(),
    errors,
    warnings,
  }
}

///|
/// Build the documentation graph and run the CMG001-CMG010 integrity rules.
pub fn analyze(workspace : Workspace) -> GraphReport {
  let documents : Array[DocumentNode] = []
  let links : Array[LinkRef] = []
  let diagnostics : Array[Diagnostic] = []
  for source in workspace.documents {
    let (document, extracted) = extract_document(source)
    documents.push(document)
    for link in extracted {
      links.push(link)
    }
  }
  for document in documents {
    for heading in document.headings {
      if heading.duplicate {
        diagnostics.push({
          code: "CMG007",
          severity: Warning,
          file: document.path,
          line: heading.line,
          column: 1,
          message: "Duplicate heading anchor; generated '#\{heading.anchor}'.",
          target: heading.anchor,
        })
      }
    }
  }
  let edges : Array[GraphEdge] = []
  let referenced_assets : Array[String] = []
  for link in links {
    if link.kind == ExternalLink {
      if is_unsafe_target(link.raw_target) {
        diagnostics.push(
          diagnostic("CMG010", Error, link, "Unsafe URL scheme is not allowed."),
        )
      }
      continue
    }
    if link.escaped_root {
      diagnostics.push(
        diagnostic(
          "CMG008",
          Error,
          link,
          "Link escapes the configured documentation root.",
        ),
      )
      continue
    }
    match link.kind {
      DocumentLink => {
        let exact = find_document(documents, link.target_path)
        if exact >= 0 {
          let target = documents[exact]
          edges.push({
            source: link.source,
            target: target.path,
            kind: DocumentLink,
            line: link.line,
          })
          if !heading_exists(target, link.fragment) {
            diagnostics.push(
              diagnostic(
                "CMG002",
                Error,
                link,
                "Anchor '#\{link.fragment}' does not exist in '\{target.path}'.",
              ),
            )
          }
        } else {
          let candidate = find_document_case_insensitive(
            documents,
            link.target_path,
          )
          if candidate >= 0 {
            let actual = documents[candidate].path
            diagnostics.push(
              diagnostic(
                "CMG003",
                Error,
                link,
                "Path case mismatch; actual path is '\{actual}'.",
              ),
            )
            edges.push({
              source: link.source,
              target: actual,
              kind: DocumentLink,
              line: link.line,
            })
          } else {
            diagnostics.push(
              diagnostic(
                "CMG001",
                Error,
                link,
                "Document target '\{link.target_path}' does not exist.",
              ),
            )
          }
        }
      }
      AssetLink => {
        let exact = find_path(workspace.assets, link.target_path)
        if exact >= 0 {
          let actual = workspace.assets[exact]
          if !referenced_assets.contains(actual) {
            referenced_assets.push(actual)
          }
          edges.push({
            source: link.source,
            target: actual,
            kind: AssetLink,
            line: link.line,
          })
        } else {
          let candidate = find_path_case_insensitive(
            workspace.assets,
            link.target_path,
          )
          if candidate >= 0 {
            let actual = workspace.assets[candidate]
            if !referenced_assets.contains(actual) {
              referenced_assets.push(actual)
            }
            diagnostics.push(
              diagnostic(
                "CMG003",
                Error,
                link,
                "Resource path case mismatch; actual path is '\{actual}'.",
              ),
            )
          } else {
            diagnostics.push(
              diagnostic(
                "CMG005",
                Error,
                link,
                "Referenced resource '\{link.target_path}' does not exist.",
              ),
            )
          }
        }
      }
      ExternalLink => ()
    }
  }
  for asset in workspace.assets {
    if !referenced_assets.contains(asset) {
      diagnostics.push({
        code: "CMG006",
        severity: Warning,
        file: asset,
        line: 0,
        column: 0,
        message: "Document asset is not referenced by any Markdown file.",
        target: asset,
      })
    }
  }
  let entries = default_entries(workspace.entries, documents)
  let reachable = compute_reachable(entries, documents, edges)
  for document in documents {
    if !reachable.contains(document.path) && !entries.contains(document.path) {
      diagnostics.push({
        code: "CMG004",
        severity: Warning,
        file: document.path,
        line: 1,
        column: 1,
        message: "Document is unreachable from the configured entry points.",
        target: document.path,
      })
    }
  }
  let stats = count_stats(
    documents,
    links,
    workspace.assets,
    reachable,
    diagnostics,
  )
  {
    entries,
    documents,
    assets: workspace.assets,
    links,
    edges,
    reachable,
    diagnostics,
    stats,
  }
}

///|
/// Compute reverse references for a changed document.
pub fn affected(report : GraphReport, changed : String) -> ImpactReport {
  let normalized = normalize_path(changed)
  let direct : Array[String] = []
  for edge in report.edges {
    if edge.kind == DocumentLink &&
      edge.target == normalized &&
      !direct.contains(edge.source) {
      direct.push(edge.source)
    }
  }
  let transitive : Array[String] = []
  let queue = direct.copy()
  let mut cursor = 0
  while cursor < queue.length() {
    let current = queue[cursor]
    cursor = cursor + 1
    for edge in report.edges {
      if edge.kind == DocumentLink &&
        edge.target == current &&
        edge.source != normalized &&
        !direct.contains(edge.source) &&
        !transitive.contains(edge.source) {
        transitive.push(edge.source)
        queue.push(edge.source)
      }
    }
  }
  { changed: normalized, direct, transitive }
}
