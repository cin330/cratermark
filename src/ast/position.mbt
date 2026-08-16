///|
/// A half-open source range. Lines and columns are one-based.
pub(all) struct Position {
  start_line : Int
  start_column : Int
  end_line : Int
  end_column : Int
} derive(Eq, Debug)

///|
pub fn Position::line(line : Int, end_column : Int) -> Position {
  { start_line: line, start_column: 1, end_line: line, end_column }
}

///|
pub fn Position::unknown() -> Position {
  { start_line: 0, start_column: 0, end_line: 0, end_column: 0 }
}
