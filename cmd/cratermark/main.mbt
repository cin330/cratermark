///|
fn usage() -> String {
  let text =
    #|CraterMark - documentation graph and integrity analyzer
    #|
    #|Usage:
    #|  cratermark check <directory> [--format text|json|markdown|sarif] [--output file] [--entry file]
    #|  cratermark scan <directory> [--format text|json|markdown|sarif] [--output file] [--entry file]
    #|  cratermark graph <directory> [--format mermaid|dot|json]
    #|  cratermark affected <directory> <changed-file>
    #|  cratermark stats <directory>
    #|
    #|Compatibility and debugging:
    #|  cratermark parse <file>
    #|  cratermark render <file> [--format html|json|markdown]
    #|  cratermark fmt <file>
    #|  cratermark toc <file>
    #|
    #|Project commands scan a complete Markdown workspace, validate cross-file
    #|links, anchors and assets, detect unreachable documents, and build a graph.
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
fn command_index(args : Array[String]) -> Int {
  for index, value in args {
    if value == "check" ||
      value == "scan" ||
      value == "graph" ||
      value == "affected" ||
      value == "stats" ||
      value == "parse" ||
      value == "render" ||
      value == "fmt" ||
      value == "toc" {
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
fn render_project_report(
  report : @docgraph.GraphReport,
  format : String,
) -> String {
  match format {
    "text" => @docgraph.render_text(report)
    "json" => @docgraph.render_json_report(report)
    "markdown" | "md" => @docgraph.render_markdown_report(report)
    "sarif" => @docgraph.render_sarif(report)
    _ => "cratermark: unsupported report format '\{format}'\n"
  }
}

///|
fn emit_project_report(content : String, args : Array[String]) -> Bool {
  match option_value(args, "--output") {
    Some(path) => {
      if !write_source(path, content) {
        return false
      }
      println("wrote \{path}")
      true
    }
    None => {
      println(content)
      true
    }
  }
}

///|
fn run_project_command(
  command : String,
  root : String,
  args : Array[String],
  command_at : Int,
) -> Unit {
  let entry = option_value(args, "--entry")
  let workspace = match scan_workspace(root, entry) {
    Some(value) => value
    None => return
  }
  let report = @docgraph.analyze(workspace)
  match command {
    "check" | "scan" => {
      let format = option_value(args, "--format").unwrap_or("text")
      let emitted = emit_project_report(
        render_project_report(report, format),
        args,
      )
      if !emitted {
        @sys.exit(2)
      }
      if command == "check" && report.stats.errors > 0 {
        @sys.exit(1)
      }
    }
    "stats" => println(@docgraph.render_stats(report.stats))
    "graph" => {
      let format = option_value(args, "--format").unwrap_or("mermaid")
      match format {
        "mermaid" | "md" => println(@docgraph.render_mermaid(report))
        "dot" => println(@docgraph.render_dot(report))
        "json" => println(@docgraph.render_json_report(report))
        _ => println("cratermark: unsupported graph format '\{format}'")
      }
    }
    "affected" => {
      if command_at + 2 >= args.length() {
        println("cratermark: affected requires <directory> <changed-file>")
        return
      }
      let changed = args[command_at + 2]
      println(@docgraph.render_impact(@docgraph.affected(report, changed)))
    }
    _ => ()
  }
}

///|
fn run_compatibility_command(
  command : String,
  path : String,
  args : Array[String],
) -> Unit {
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
    "toc" => println(@analyzer.render_toc(document))
    _ => ()
  }
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
    println("cratermark: missing file or directory\n\n\{usage()}")
    return
  }
  let command = args[command_at]
  let path = args[command_at + 1]
  if command == "check" ||
    command == "scan" ||
    command == "graph" ||
    command == "affected" ||
    command == "stats" {
    run_project_command(command, path, args, command_at)
  } else {
    run_compatibility_command(command, path, args)
  }
}
