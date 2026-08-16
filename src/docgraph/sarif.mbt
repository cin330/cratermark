///|
priv struct SarifRule {
  id : String
  name : String
  description : String
  level : String
}

///|
fn sarif_rules() -> Array[SarifRule] {
  [
    {
      id: "CMG001",
      name: "missingDocument",
      description: "Linked Markdown document does not exist.",
      level: "error",
    },
    {
      id: "CMG002",
      name: "missingAnchor",
      description: "Heading anchor does not exist in the target document.",
      level: "error",
    },
    {
      id: "CMG003",
      name: "pathCaseMismatch",
      description: "Document or resource path has the wrong letter case.",
      level: "error",
    },
    {
      id: "CMG004",
      name: "unreachableDocument",
      description: "Document is unreachable from configured entry points.",
      level: "warning",
    },
    {
      id: "CMG005",
      name: "missingResource",
      description: "Referenced image or attachment does not exist.",
      level: "error",
    },
    {
      id: "CMG006",
      name: "unusedResource",
      description: "Scanned document asset is not referenced.",
      level: "warning",
    },
    {
      id: "CMG007",
      name: "duplicateHeadingAnchor",
      description: "Duplicate heading required a generated anchor suffix.",
      level: "warning",
    },
    {
      id: "CMG008",
      name: "workspaceEscape",
      description: "Link escapes the configured workspace root.",
      level: "error",
    },
    {
      id: "CMG010",
      name: "unsafeUrlScheme",
      description: "Link uses an unsafe URL scheme.",
      level: "error",
    },
  ]
}

///|
fn sarif_rule_index(rules : Array[SarifRule], code : String) -> Int {
  for index, rule in rules {
    if rule.id == code {
      return index
    }
  }
  0
}

///|
fn sarif_uri(path : String) -> String {
  normalize_path(path)
  .replace_all(old="%", new="%25")
  .replace_all(old=" ", new="%20")
  .replace_all(old="#", new="%23")
  .replace_all(old="?", new="%3F")
}

///|
/// Render a SARIF 2.1.0 log compatible with GitHub Code Scanning.
pub fn render_sarif(report : GraphReport) -> String {
  let rules = sarif_rules()
  let out = StringBuilder()
  out.write_string("{\n")
  out.write_string(
    "  \"$schema\": \"https://json.schemastore.org/sarif-2.1.0.json\",\n",
  )
  out.write_string("  \"version\": \"2.1.0\",\n")
  out.write_string("  \"runs\": [\n    {\n")
  out.write_string("      \"tool\": {\n        \"driver\": {\n")
  out.write_string("          \"name\": \"CraterMark\",\n")
  out.write_string("          \"semanticVersion\": \"0.4.0\",\n")
  out.write_string(
    "          \"informationUri\": \"https://github.com/cin330/cratermark\",\n",
  )
  out.write_string("          \"rules\": [")
  for index, rule in rules {
    if index > 0 {
      out.write_char(',')
    }
    out.write_string("\n            {\"id\":")
    out.write_string(json_escape(rule.id))
    out.write_string(",\"name\":")
    out.write_string(json_escape(rule.name))
    out.write_string(",\"shortDescription\":{\"text\":")
    out.write_string(json_escape(rule.description))
    out.write_string("},\"defaultConfiguration\":{\"level\":")
    out.write_string(json_escape(rule.level))
    out.write_string(
      "},\"helpUri\":\"https://github.com/cin330/cratermark/blob/main/docs/rules.md\",\"properties\":{\"precision\":\"high\",\"problem.severity\":",
    )
    out.write_string(json_escape(rule.level))
    out.write_string(",\"tags\":[\"documentation\",\"correctness\"]}}")
  }
  if rules.length() > 0 {
    out.write_string("\n          ")
  }
  out.write_string("]\n        }\n      },\n")
  out.write_string("      \"results\": [")
  for index, item in report.diagnostics {
    if index > 0 {
      out.write_char(',')
    }
    let line = if item.line > 0 { item.line } else { 1 }
    let column = if item.column > 0 { item.column } else { 1 }
    out.write_string("\n        {\"ruleId\":")
    out.write_string(json_escape(item.code))
    out.write_string(",\"ruleIndex\":")
    out.write_string(sarif_rule_index(rules, item.code).to_string())
    out.write_string(",\"level\":")
    out.write_string(json_escape(severity_name(item.severity)))
    out.write_string(",\"message\":{\"text\":")
    out.write_string(json_escape(item.message))
    out.write_string("},\"locations\":[{\"physicalLocation\":{")
    out.write_string("\"artifactLocation\":{\"uri\":")
    out.write_string(json_escape(sarif_uri(item.file)))
    out.write_string("},\"region\":{\"startLine\":")
    out.write_string(line.to_string())
    out.write_string(",\"startColumn\":")
    out.write_string(column.to_string())
    out.write_string("}}}]")
    if !item.target.is_empty() {
      out.write_string(",\"properties\":{\"target\":")
      out.write_string(json_escape(item.target))
      out.write_char('}')
    }
    out.write_char('}')
  }
  if report.diagnostics.length() > 0 {
    out.write_string("\n      ")
  }
  out.write_string("]\n    }\n  ]\n}\n")
  out.to_string()
}
