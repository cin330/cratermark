///|
fn usage() -> String {
  let text =
    #|CraterMark - structured Markdown toolkit
    #|
    #|Usage:
    #|  cratermark parse <file>
    #|  cratermark render <file> [--format html|json|markdown]
    #|  cratermark fmt <file>
    #|  cratermark check <file>
    #|  cratermark toc <file>
    #|  cratermark stats <file>
    #|
    #|Commands:
    #|  parse    Parse Markdown and print the AST as JSON
    #|  render   Render HTML by default, or select another format
    #|  fmt      Rewrite the file as canonical Markdown
    #|  check    Run MD001-MD005 lint rules
    #|  toc      Generate a Markdown table of contents
    #|  stats    Print document statistics
  text
}

///|
fn option_value(args : Array[String], name : String) -> String? {
  for index = 0; index + 1 < args.length(); index = index + 1 {
    if args[index] == name {
      return Some(args[index + 1])
    }
  }
  None
}

///|
/// Native executables expose one launcher argument while the JavaScript
/// backend exposes both Node and script paths. Locate the command instead of
/// relying on a backend-specific offset.
fn command_index(args : Array[String]) -> Int {
  for index, value in args {
    if value == "parse" ||
      value == "render" ||
      value == "fmt" ||
      value == "check" ||
      value == "toc" ||
      value == "stats" {
      return index
    }
  }
  -1
}

///|
fn read_source(path : String) -> String? {
  Some(@fs.read_file_to_string(path)) catch {
    @fs.IOError(message) => {
      println("cratermark: unable to read '\{path}': \{message}")
      None
    }
  }
}

///|
fn write_source(path : String, content : String) -> Bool {
  @fs.write_string_to_file(path, content) catch {
    @fs.IOError(message) => {
      println("cratermark: unable to write '\{path}': \{message}")
      return false
    }
  }
  true
}

///|
fn main {
  let args = @env.args()
  if args.any(fn(arg) { arg == "help" || arg == "--help" || arg == "-h" }) {
    println(usage())
    return
  }
  let command_at = command_index(args)
  if command_at < 0 {
    println(usage())
    return
  }
  if command_at + 1 >= args.length() {
    println("cratermark: missing Markdown file\n\n\{usage()}")
    return
  }
  let command = args[command_at]
  let path = args[command_at + 1]
  let source = match read_source(path) {
    Some(value) => value
    None => return
  }
  let document = @parser.parse(source)
  match command {
    "parse" => println(@renderer.render_json(document))
    "render" => {
      let format = option_value(args, "--format").unwrap_or("html")
      match format {
        "html" => println(@renderer.render_html(document))
        "json" => println(@renderer.render_json(document))
        "markdown" | "md" => println(@renderer.render_markdown(document))
        _ => println("cratermark: unsupported format '\{format}'")
      }
    }
    "fmt" =>
      if write_source(path, @formatter.format(document)) {
        println("formatted \{path}")
      }
    "check" => println(@analyzer.render_lint(path, @analyzer.lint(document)))
    "toc" => println(@analyzer.render_toc(document))
    "stats" =>
      println(@analyzer.render_stats(@analyzer.document_stats(document)))
    _ => println("cratermark: unknown command '\{command}'\n\n\{usage()}")
  }
}
