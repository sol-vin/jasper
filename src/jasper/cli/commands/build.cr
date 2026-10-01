require "file_utils"
require "../terminal"

module Jasper
  module CLI
    module Commands
      class Validate
        def self.run(args : Array(String)) : Int32
          config = Config.find
          res = Validator.validate_dir(config.source_dir)

          res.warnings.each do |w|
            Terminal.warn(w)
          end

          if res.valid?
            Terminal.success("Validation passed! All documentation schemas are valid in '#{config.source_dir}'.")
            0
          else
            res.errors.each do |e|
              Terminal.error(e)
            end
            Terminal.error("Validation failed with #{res.errors.size} error(s).")
            1
          end
        end
      end

      class Build
        def self.run(args : Array(String)) : Int32
          config = Config.find

          # Parse optional overrides
          args.each do |arg|
            if arg.starts_with?("--namespace=")
              config.namespace = arg.split("=", 2)[1]
            elsif arg.starts_with?("--src=")
              config.source_dir = arg.split("=", 2)[1]
            elsif arg.starts_with?("--out=")
              config.output_dir = arg.split("=", 2)[1]
            elsif arg.starts_with?("--master=")
              config.master_file = arg.split("=", 2)[1]
            elsif arg == "--no-release-guard"
              config.features.release_guard = false
            elsif arg == "--release-guard"
              config.features.release_guard = true
            end
          end

          Terminal.info("Compiling docs from '#{config.source_dir}' -> '#{config.output_dir}'...")

          generator = Generator.new(config)
          if generator.run
            Terminal.success("Successfully generated documentation for '#{config.namespace}'!")
            Terminal.success("Master index: #{config.master_file}")
            0
          else
            Terminal.error("No valid documentation files found in '#{config.source_dir}' or via DSL.")
            1
          end
        end
      end

      class Clean
        def self.run(args : Array(String)) : Int32
          config = Config.find
          out_dir = Path.new(config.output_dir)
          master_file = Path.new(config.master_file)

          cleaned = 0
          if Dir.exists?(out_dir)
            FileUtils.rm_rf(out_dir)
            Terminal.success("Removed generated directory #{out_dir}")
            cleaned += 1
          end

          if File.exists?(master_file)
            File.delete(master_file)
            Terminal.success("Removed master docs file #{master_file}")
            cleaned += 1
          end

          if cleaned == 0
            Terminal.info("No generated documentation artifacts to clean.")
          else
            Terminal.success("Clean complete.")
          end
          0
        end
      end
    end
  end
end
