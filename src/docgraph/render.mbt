///|
pub fn severity_name(severity : Severity) -> String {
  match severity {
    Warning => "warning"
    Error => "error"
  }
}

///|
fn link_kind_name(kind : LinkKind) -> String {
  match kind {
    DocumentLink => "document"
    AssetLink => "asset"
    ExternalLink => "external"
  }
}

///|
fn json_escape(value : String) -> String {
  let out = StringBuilder()
  out.write_char('"')
  for char in value {
    match char {
      '"' => out.write_string("\\\"")
      '\\' => out.write_string("\\\\")
      '\n' => out.write_string("\\n")
      '\r' => out.write_string("\\r")
      '\t' => out.write_string("\\t")
      _ => out.write_char(char)
    }
  }
  out.write_char('"')
  out.to_string()
}

///|
pub fn render_stats(stats : GraphStats) -> String {
  let out = StringBuilder()
  out.write_string("Documents: \{stats.documents}\n")
  out.write_string("Headings: \{stats.headings}\n")
  out.write_string("Internal links: \{stats.internal_links}\n")
  out.write_string("External links: \{stats.external_links}\n")
  out.write_string("Asset links: \{stats.asset_links}\n")
  out.write_string("Assets: \{stats.assets}\n")
  out.write_string(
    "Reachable documents: \{stats.reachable_documents}/\{stats.documents}\n",
  )
  out.write_string("Errors: \{stats.errors}\n")
  out.write_string("Warnings: \{stats.warnings}\n")
  out.to_string()
}

///|
pub fn render_text(report : GraphReport) -> String {
  let out = StringBuilder()
  out.write_string("CraterMark documentation integrity report\n\n")
  if report.diagnostics.length() == 0 {
    out.write_string("No integrity problems found.\n\n")
  } else {
    for item in report.diagnostics {
      out.write_string(
        "\{severity_name(item.severity)} \{item.code} \{item.file}",
      )
      if item.line > 0 {
        out.write_string(":\{item.line}:\{item.column}")
      }
      out.write_string("\n  \{item.message}\n\n")
    }
  }
  out.write_string(render_stats(report.stats))
  out.to_string()
}

///|
pub fn render_markdown_report(report : GraphReport) -> String {
  let out = StringBuilder()
  out.write_string("# CraterMark documentation integrity report\n\n")
  out.write_string("| Severity | Rule | Location | Message |\n")
  out.write_string("| --- | --- | --- | --- |\n")
  if report.diagnostics.length() == 0 {
    out.write_string("| - | - | - | No integrity problems found |\n")
  } else {
    for item in report.diagnostics {
      let location = if item.line > 0 {
        "\{item.file}:\{item.line}:\{item.column}"
      } else {
        item.file
      }
      out.write_string(
        "| \{severity_name(item.severity)} | \{item.code} | `\{location}` | \{item.message} |\n",
      )
    }
  }
  out.write_string("\n## Summary\n\n```text\n")
  out.write_string(render_stats(report.stats))
  out.write_string("```\n")
  out.to_string()
}

///|
pub fn render_json_report(report : GraphReport) -> String {
  let out = StringBuilder()
  out.write_string("{\n  \"stats\": {")
  out.write_string("\"documents\":\{report.stats.documents},")
  out.write_string("\"headings\":\{report.stats.headings},")
  out.write_string("\"internal_links\":\{report.stats.internal_links},")
  out.write_string("\"external_links\":\{report.stats.external_links},")
  out.write_string("\"asset_links\":\{report.stats.asset_links},")
  out.write_string("\"assets\":\{report.stats.assets},")
  out.write_string(
    "\"reachable_documents\":\{report.stats.reachable_documents},",
  )
  out.write_string("\"errors\":\{report.stats.errors},")
  out.write_string("\"warnings\":\{report.stats.warnings}},\n")
  out.write_string("  \"diagnostics\": [")
  for index, item in report.diagnostics {
    if index > 0 {
      out.write_char(',')
    }
    out.write_string("\n    {\"code\":")
    out.write_string(json_escape(item.code))
    out.write_string(",\"severity\":")
    out.write_string(json_escape(severity_name(item.severity)))
    out.write_string(",\"file\":")
    out.write_string(json_escape(item.file))
    out.write_string(",\"line\":\{item.line},\"column\":\{item.column}")
    out.write_string(",\"message\":")
    out.write_string(json_escape(item.message))
    out.write_char('}')
  }
  if report.diagnostics.length() > 0 {
    out.write_char('\n')
    out.write_string("  ")
  }
  out.write_string("],\n  \"edges\": [")
  for index, edge in report.edges {
    if index > 0 {
      out.write_char(',')
    }
    out.write_string("\n    {\"source\":")
    out.write_string(json_escape(edge.source))
    out.write_string(",\"target\":")
    out.write_string(json_escape(edge.target))
    out.write_string(",\"kind\":")
    out.write_string(json_escape(link_kind_name(edge.kind)))
    out.write_string(",\"line\":\{edge.line}}")
  }
  if report.edges.length() > 0 {
    out.write_char('\n')
    out.write_string("  ")
  }
  out.write_string("]\n}\n")
  out.to_string()
}

///|
fn graph_node_id(path : String, paths : Array[String]) -> String {
  for index, current in paths {
    if current == path {
      return "n\{index}"
    }
  }
  "unknown"
}

///|
fn graph_paths(report : GraphReport) -> Array[String] {
  let paths : Array[String] = []
  for document in report.documents {
    paths.push(document.path)
  }
  for asset in report.assets {
    if !paths.contains(asset) {
      paths.push(asset)
    }
  }
  paths
}

///|
pub fn render_mermaid(report : GraphReport) -> String {
  let paths = graph_paths(report)
  let out = StringBuilder()
  out.write_string("graph TD\n")
  for index, path in paths {
    out.write_string("  n\{index}[")
    out.write_string(json_escape(path))
    out.write_string("]\n")
  }
  for edge in report.edges {
    let source = graph_node_id(edge.source, paths)
    let target = graph_node_id(edge.target, paths)
    if source != "unknown" && target != "unknown" {
      out.write_string("  \{source} --> \{target}\n")
    }
  }
  out.to_string()
}

///|
pub fn render_dot(report : GraphReport) -> String {
  let out = StringBuilder()
  out.write_string("digraph documentation {\n")
  for document in report.documents {
    out.write_string("  \{json_escape(document.path)};\n")
  }
  for edge in report.edges {
    out.write_string(
      "  \{json_escape(edge.source)} -> \{json_escape(edge.target)};\n",
    )
  }
  out.write_string("}\n")
  out.to_string()
}

///|
pub fn render_impact(impact : ImpactReport) -> String {
  let out = StringBuilder()
  out.write_string("Changed:\n  \{impact.changed}\n\n")
  out.write_string("Directly affected:\n")
  if impact.direct.length() == 0 {
    out.write_string("  (none)\n")
  } else {
    for path in impact.direct {
      out.write_string("  \{path}\n")
    }
  }
  out.write_string("\nTransitively affected:\n")
  if impact.transitive.length() == 0 {
    out.write_string("  (none)\n")
  } else {
    for path in impact.transitive {
      out.write_string("  \{path}\n")
    }
  }
  out.to_string()
}
