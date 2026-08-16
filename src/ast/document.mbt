///|
/// The root of a parsed Markdown document.
pub(all) struct Document {
  children : Array[Block]
  source : String
} derive(Eq, Debug)

///|
pub fn Document::new(children : Array[Block], source : String) -> Document {
  { children, source }
}
