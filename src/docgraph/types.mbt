///|
/// One Markdown source supplied to the project-level analyzer.
pub(all) struct SourceFile {
  path : String
  content : String
} derive(Eq, Debug)

///|
pub fn SourceFile::new(path : String, content : String) -> SourceFile {
  { path: normalize_path(path), content }
}

///|
/// All inputs needed to analyze a documentation workspace. Assets contain
/// repository-relative paths but do not need to be read into memory.
pub(all) struct Workspace {
  documents : Array[SourceFile]
  assets : Array[String]
  entries : Array[String]
} derive(Eq, Debug)

///|
pub fn Workspace::new(
  documents : Array[SourceFile],
  assets? : Array[String] = [],
  entries? : Array[String] = [],
) -> Workspace {
  {
    documents,
    assets: assets.map(normalize_path),
    entries: entries.map(normalize_path),
  }
}

///|
pub(all) enum Severity {
  Warning
  Error
} derive(Eq, Debug)

///|
pub(all) enum LinkKind {
  DocumentLink
  AssetLink
  ExternalLink
} derive(Eq, Debug)

///|
pub(all) struct HeadingRef {
  title : String
  anchor : String
  line : Int
  duplicate : Bool
} derive(Eq, Debug)

///|
pub(all) struct DocumentNode {
  path : String
  headings : Array[HeadingRef]
} derive(Eq, Debug)

///|
pub(all) struct LinkRef {
  source : String
  label : String
  raw_target : String
  target_path : String
  fragment : String
  kind : LinkKind
  line : Int
  column : Int
  escaped_root : Bool
} derive(Eq, Debug)

///|
pub(all) struct GraphEdge {
  source : String
  target : String
  kind : LinkKind
  line : Int
} derive(Eq, Debug)

///|
pub(all) struct Diagnostic {
  code : String
  severity : Severity
  file : String
  line : Int
  column : Int
  message : String
  target : String
} derive(Eq, Debug)

///|
pub(all) struct GraphStats {
  documents : Int
  headings : Int
  internal_links : Int
  external_links : Int
  asset_links : Int
  assets : Int
  reachable_documents : Int
  errors : Int
  warnings : Int
} derive(Eq, Debug)

///|
/// Complete, deterministic result of a workspace analysis.
pub(all) struct GraphReport {
  entries : Array[String]
  documents : Array[DocumentNode]
  assets : Array[String]
  links : Array[LinkRef]
  edges : Array[GraphEdge]
  reachable : Array[String]
  diagnostics : Array[Diagnostic]
  stats : GraphStats
} derive(Eq, Debug)

///|
pub(all) struct ImpactReport {
  changed : String
  direct : Array[String]
  transitive : Array[String]
} derive(Eq, Debug)
