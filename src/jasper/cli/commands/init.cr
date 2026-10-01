require "file_utils"
require "../terminal"

module Jasper
  module CLI
    module Commands
      class Init
        def self.run(args : Array(String)) : Int32
          namespace = "Docs"
          source_dir = "docs_src"
          output_dir = "src/docs"
          master_file = "src/docs.cr"

          i = 0
          while i < args.size
            arg = args[i]
            if arg.starts_with?("--namespace=")
              namespace = arg.split("=", 2)[1]
            elsif arg == "-n" && i + 1 < args.size
              namespace = args[i + 1]
              i += 1
            elsif arg.starts_with?("--src=")
              source_dir = arg.split("=", 2)[1]
            elsif arg.starts_with?("--out=")
              output_dir = arg.split("=", 2)[1]
            end
            i += 1
          end

          config_file = Path.new("jasper.yml")
          if File.exists?(config_file)
            Terminal.warn("Configuration file '#{config_file}' already exists. Skipping config scaffold.")
          else
            config = Config.new(
              namespace: namespace,
              source_dir: source_dir,
              output_dir: output_dir,
              master_file: master_file
            )
            config.set_quick_start("#{namespace.split("::").first} Commands", ["shards install", "crystal spec", "crystal docs"])
            config.save(config_file)
            Terminal.success("Created #{config_file}")
          end

          track_dir = Path.new(source_dir, "01_getting_started")
          sample_file = track_dir.join("01_overview.yml")
          if File.exists?(sample_file)
            Terminal.warn("Sample document '#{sample_file}' already exists.")
          else
            FileUtils.mkdir_p(track_dir)
            sample_content = <<-YAML
id: OVERVIEW
title: Getting Started & System Overview
summary: Complete introduction to the architecture and core concepts.
track: 01_getting_started
overview: |
  Welcome to the documentation guide. This project utilizes Jasper to author
  structured guides and compile them into native Crystal API documentation.

related_sources:
  - "shard.yml"
  - "src/"

sections:
  - id: topic_01_introduction
    title: Introduction & Architecture
    summary: Fundamental architectural principles and layout.
    content: |
      This section introduces the foundational concepts of the codebase.

      | Component | Location | Role |
      | :--- | :--- | :--- |
      | Core | `src/` | Main application logic |
      | Specs | `spec/` | Test suites |
      | Docs | `docs_src/` | Jasper source guides |

    options:
      "--release": "Enables release optimizations."
      "--verbose": "Enables verbose logging."

    examples:
      - |
        ```crystal
        # Basic usage example
        puts "Hello from Jasper-documented shard!"
        ```

    pitfalls:
      - "Always keep docs_src updated when modifying public APIs."

    faqs:
      - q: "How do I build the documentation site?"
        a: "Run 'jasper build' followed by 'crystal docs'."
YAML
            File.write(sample_file, sample_content)
            Terminal.success("Created starter documentation guide at #{sample_file}")
          end

          Terminal.success("Jasper initialized successfully!")
          puts "\nNext steps:"
          puts "  1. Edit #{sample_file} or add new YAML files in #{source_dir}/"
          puts "  2. Run 'jasper build' to compile docs into #{output_dir}/"
          puts "  3. Run 'crystal docs' to generate the static HTML documentation site\n"
          0
        end
      end

      class New
        def self.run(args : Array(String)) : Int32
          if args.empty? || args[0].starts_with?("-")
            Terminal.error("Usage: jasper new <track>/<topic> [--title=...] [--summary=...]")
            return 1
          end

          target = args[0]
          title = ""
          summary = ""

          args[1..-1].each do |arg|
            if arg.starts_with?("--title=")
              title = arg.split("=", 2)[1]
            elsif arg.starts_with?("--summary=")
              summary = arg.split("=", 2)[1]
            end
          end

          parts = target.split('/')
          if parts.size < 2
            Terminal.error("Target must be in the format <track>/<topic> (e.g. 02_guides/01_memory_safety)")
            return 1
          end

          track = parts[0]
          topic_slug = parts[1].sub(/\.ya?ml\z/, "")
          doc_id = topic_slug.sub(/^\d+_/, "").upcase

          title = doc_id.gsub("_", " ").capitalize if title.empty?
          summary = "Documentation guide for #{title}." if summary.empty?

          config = Config.find
          dest_dir = Path.new(config.source_dir, track)
          dest_file = dest_dir.join("#{topic_slug}.yml")

          if File.exists?(dest_file)
            Terminal.error("File '#{dest_file}' already exists!")
            return 1
          end

          FileUtils.mkdir_p(dest_dir)

          template = <<-YAML
id: #{doc_id}
title: #{title}
summary: #{summary}
track: #{track}
overview: |
  Overview of #{title}. Describe high-level design, context, and usage.

related_sources:
  - "src/"

sections:
  - id: topic_01_core_concepts
    title: Core Concepts
    summary: Primary concepts and conventions for #{title}.
    content: |
      Detailed guide content goes here. You can use standard Markdown, code blocks,
      and tables.

    examples:
      - |
        ```crystal
        # Code example
        ```

    pitfalls:
      - "Note any critical warnings or common developer mistakes here."

    faqs:
      - q: "Common question about this feature?"
        a: "Concise answer explaining the recommended approach."
YAML

          File.write(dest_file, template)
          Terminal.success("Created new topic file at #{dest_file}")
          0
        end
      end

      class List
        def self.run(args : Array(String)) : Int32
          config = Config.find
          src = Path.new(config.source_dir)

          unless Dir.exists?(src)
            Terminal.warn("Source directory '#{src}' does not exist.")
            return 0
          end

          pattern = src.join("**/*.yml").to_s.tr("\\", "/")
          files = Dir.glob(pattern).sort

          if files.empty?
            Terminal.info("No YAML documentation files found in #{src}/")
            return 0
          end

          puts "\n#{Terminal.bold(":: Documentation Tracks & Topics in #{src}/ ::")}\n"

          current_track = ""
          files.each do |f|
            rel = Path.new(f).relative_to(src)
            track_name = rel.dirname.to_s
            if track_name != current_track
              current_track = track_name
              puts "  #{Terminal.cyan("📁 #{track_name}")}"
            end

            begin
              doc = DocDocument.from_yaml(File.read(f))
              puts "    #{Terminal.green("📄 #{doc.id}")} — #{Terminal.bold(doc.title)}"
              puts "       #{Terminal.dim(doc.summary)}"
              doc.sections.each do |sec|
                puts "       └─ #{Terminal.dim(".#{sec.id}")}: #{sec.title}"
              end
            rescue
              puts "    #{Terminal.red("📄 #{rel.basename} (syntax error)")}"
            end
          end
          puts
          0
        end
      end
    end
  end
end
