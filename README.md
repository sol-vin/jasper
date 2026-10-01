# Jasper

**Modular Structured Guide, Book, and Documentation Compiler for Crystal Docs.**

Jasper allows any Crystal project to author rich, multi-track technical books, guides, and tutorials in clean YAML or via a fluent Crystal DSL, and compile them into native Crystal modules and methods with rich doc comments. When `crystal docs` runs, it indexes the entire guide hierarchy into the standard HTML documentation site.

---

## Features

- **Crystal Docs Integration**: Seamlessly integrates into `crystal docs` with in-page Method Summary tables of contents, deep links, and search indexing in `search-index.js`.
- **Zero Overhead in Production**: Wraps generated code in `{% unless flag?(:release) %}` so documentation classes are completely stripped from production release binaries.
- **Dual Authoring**: Author guides in structured YAML files under `docs_src/` or programmatically in Crystal code using the fluent `Jasper.define_track` DSL.
- **Table Transformation**: Automatically converts Markdown pipe tables (`| col |`) into standard HTML `<table>` blocks for flawless rendering across all Crystal doc formatters.
- **Summary Truncation Protection**: Intelligently formats method doc comment titles to prevent Crystal docs from truncating multi-word summaries at intermediate periods.
- **Extensible Plugin System**: Register custom section handlers (e.g. Mermaid diagrams, benchmark comparison tables) and markdown filter pipelines.
- **Full-Featured CLI**: Scaffold, create new topics, validate schemas, compile, and clean via `bin/jasper`.
- **Zero External Dependencies**: Pure Crystal standard library.

---

## Installation

Add `jasper` to your `shard.yml`:

```yaml
development_dependencies:
  jasper:
    github: sol-vin/jasper
    branch: main
```

Run `shards install`.

---

## Quick Start (CLI)

```bash
# 1. Scaffold jasper.yml and initial docs_src/ directory
jasper init --namespace "MyProject::Docs"

# 2. Add a new guide topic
jasper new 01_getting_started/02_quickstart --title "Quickstart Guide"

# 3. Validate your documentation files
jasper validate

# 4. Compile docs_src/ into Crystal doc classes
jasper build

# 5. Generate static HTML documentation
crystal docs
```

---

## Configuration (`jasper.yml`)

```yaml
namespace: "MyProject::Docs"
source_dir: "docs_src"
output_dir: "src/my_project/docs"
master_file: "src/my_project/docs.cr"

features:
  release_guard: true
  naming_style: "prefixed" # "prefixed" | "natural"
  prefix_format: "topic_%02d_"
  table_auto_html: true
  protect_summary: true
  summary_table: true
  master_index: true
  aliases:
    - "Docs"
    - "MyProject::Documentation"
  quick_start:
    title: "Project Commands"
    commands:
      - "shards install"
      - "crystal spec"
      - "crystal docs"
  search_index_file: "docs/search_index.json"
```

---

## Programmatic Crystal DSL

```crystal
require "jasper"

Jasper.define_track "01_getting_started", title: "Getting Started" do |track|
  track.document "architecture", title: "Architecture & Design", summary: "Core design patterns." do |doc|
    doc.overview "Detailed system overview."
    doc.related_source "src/main.cr"

    doc.section "boundaries", title: "System Boundaries" do |sec|
      sec.summary "Separation between layers."
      sec.content "Core engine primitives live under src/core."
      sec.option "--release", "Enables compiler optimizations"
      sec.example "MyEngine.run"
      sec.pitfall "Never mutate state across threads without mutexes"
      sec.faq "How do I extend this?", "Use the Jasper plugin system!"
    end
  end
end
```

---

## Extensible Plugins & Custom Section Handlers

```crystal
require "jasper"

class DiagramPlugin < Jasper::Plugin
  def setup(pipeline : Jasper::Pipeline) : Nil
    # Custom section handler for mermaid diagrams
    pipeline.register_section_handler("mermaid") do |io, data, pad|
      io.puts "#{pad}# #### Architecture Diagram"
      io.puts "#{pad}#"
      io.puts "#{pad}# ```mermaid"
      data.as_s.lines.each { |l| io.puts "#{pad}# #{l}".rstrip }
      io.puts "#{pad}# ```"
      io.puts "#{pad}#"
    end
  end
end

Jasper.register_plugin(DiagramPlugin.new)
```

---

## License

MIT License. Copyright (c) 2026 sol-vin.
