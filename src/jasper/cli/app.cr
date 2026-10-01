require "../../jasper"
require "./terminal"
require "./commands/init"
require "./commands/build"

module Jasper
  module CLI
    class App
      def self.run(args : Array(String) = ARGV) : Int32
        if args.empty? || args[0] == "-h" || args[0] == "--help" || args[0] == "help"
          print_help
          return 0
        end

        subcommand = args[0]
        sub_args = args[1..-1]

        case subcommand
        when "-v", "--version", "version"
          puts "Jasper version #{Jasper::VERSION} (Crystal #{Crystal::VERSION})"
          0
        when "init"
          Commands::Init.run(sub_args)
        when "build", "generate"
          Commands::Build.run(sub_args)
        when "new", "create"
          Commands::New.run(sub_args)
        when "validate", "check"
          Commands::Validate.run(sub_args)
        when "list", "ls"
          Commands::List.run(sub_args)
        when "clean", "purge"
          Commands::Clean.run(sub_args)
        else
          Terminal.error("Unknown command '#{subcommand}'. Run 'jasper --help' for available commands.")
          1
        end
      end

      def self.print_help : Nil
        Terminal.banner
        puts <<-HELP
Usage:
  jasper <command> [options]

Core Commands:
  init                     Scaffold jasper.yml and initial docs_src/ directory
  build, generate          Compile YAML and DSL documentation into Crystal doc classes
  new, create <track/doc>  Create a new documentation topic file with boilerplate
  validate, check          Lint and validate YAML schema and table structures
  list, ls                 Display interactive or tree view of tracks and topics
  clean, purge             Remove generated documentation artifacts
  version, -v              Display Jasper toolchain version
  help, -h                 Show this help screen

Options:
  -n, --namespace=NAME     Target Crystal root module namespace (e.g. MyShard::Docs)
  --src=DIR                Source directory containing YAML guides (default: docs_src)
  --out=DIR                Output directory for generated .cr files (default: src/docs)
  --master=FILE            Master documentation index file (default: src/docs.cr)
  --[no-]release-guard     Toggle {% unless flag?(:release) %} compilation guard

Examples:
  jasper init --namespace "MyEngine::Docs"
  jasper new 01_getting_started/02_quickstart --title "Quickstart Guide"
  jasper validate
  jasper build
  crystal docs
HELP
      end
    end
  end
end
