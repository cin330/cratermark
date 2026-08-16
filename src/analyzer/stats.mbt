///|
pub(all) struct CodeLanguage {
  language : String
  count : Int
} derive(Eq, Debug)

///|
pub(all) struct DocumentStats {
  lines : Int
  words : Int
  headings : Int
  paragraphs : Int
  links : Int
  images : Int
  lists : Int
  code_blocks : Int
  code_languages : Array[CodeLanguage]
} derive(Eq, Debug)

///|
priv struct MutableStats {
  mut words : Int
  mut headings : Int
  mut paragraphs : Int
  mut links : Int
  mut images : Int
  mut lists : Int
  mut code_blocks : Int
  languages : Array[String]
  language_counts : Array[Int]
}

///|
fn count_words(value : String) -> Int {
  let mut count = 0
  let mut in_word = false
  for char in value.iter() {
    if char.is_whitespace() {
      in_word = false
    } else if !in_word {
      count = count + 1
      in_word = true
    }
  }
  count
}

///|
fn count_inlines(nodes : Array[@ast.Inline], stats : MutableStats) -> Unit {
  for node in nodes {
    match node {
      @ast.Text(value, _) | @ast.InlineCode(value, _) =>
        stats.words = stats.words + count_words(value)
      @ast.Strong(children, _) | @ast.Emphasis(children, _) =>
        count_inlines(children, stats)
      @ast.Link(children, _, _) => {
        stats.links = stats.links + 1
        count_inlines(children, stats)
      }
      @ast.Image(alt, _, _) => {
        stats.images = stats.images + 1
        stats.words = stats.words + count_words(alt)
      }
    }
  }
}

///|
fn add_language(language : String, stats : MutableStats) -> Unit {
  if language == "" {
    return
  }
  let mut found = false
  for index, current in stats.languages {
    if current == language {
      stats.language_counts[index] = stats.language_counts[index] + 1
      found = true
      break
    }
  }
  if !found {
    stats.languages.push(language)
    stats.language_counts.push(1)
  }
}

///|
fn count_blocks(blocks : Array[@ast.Block], stats : MutableStats) -> Unit {
  for block in blocks {
    match block {
      @ast.Heading(_, children, _) => {
        stats.headings = stats.headings + 1
        count_inlines(children, stats)
      }
      @ast.Paragraph(children, _) => {
        stats.paragraphs = stats.paragraphs + 1
        count_inlines(children, stats)
      }
      @ast.CodeBlock(language, code, _) => {
        stats.code_blocks = stats.code_blocks + 1
        stats.words = stats.words + count_words(code)
        add_language(language, stats)
      }
      @ast.BlockQuote(children, _) => count_blocks(children, stats)
      @ast.List(_, _, items, _) => {
        stats.lists = stats.lists + 1
        for item in items {
          count_blocks(item.children, stats)
        }
      }
      @ast.HorizontalRule(_) => ()
    }
  }
}

///|
pub fn document_stats(document : @ast.Document) -> DocumentStats {
  let state : MutableStats = {
    words: 0,
    headings: 0,
    paragraphs: 0,
    links: 0,
    images: 0,
    lists: 0,
    code_blocks: 0,
    languages: [],
    language_counts: [],
  }
  count_blocks(document.children, state)
  let languages : Array[CodeLanguage] = []
  for index, language in state.languages {
    languages.push({ language, count: state.language_counts[index] })
  }
  {
    lines: document.source.split("\n").to_array().length(),
    words: state.words,
    headings: state.headings,
    paragraphs: state.paragraphs,
    links: state.links,
    images: state.images,
    lists: state.lists,
    code_blocks: state.code_blocks,
    code_languages: languages,
  }
}

///|
pub fn render_stats(stats : DocumentStats) -> String {
  let out = StringBuilder()
  out.write_string("Document Statistics\n\n")
  out.write_string("Lines: \{stats.lines}\n")
  out.write_string("Words: \{stats.words}\n")
  out.write_string("Headings: \{stats.headings}\n")
  out.write_string("Paragraphs: \{stats.paragraphs}\n")
  out.write_string("Links: \{stats.links}\n")
  out.write_string("Images: \{stats.images}\n")
  out.write_string("Lists: \{stats.lists}\n")
  out.write_string("Code Blocks: \{stats.code_blocks}\n")
  if stats.code_languages.length() > 0 {
    out.write_string("\nCode Languages\n\n")
    for entry in stats.code_languages {
      out.write_string("\{entry.language}: \{entry.count}\n")
    }
  }
  out.to_string()
}
