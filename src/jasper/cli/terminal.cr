module Jasper
  module CLI
    module Terminal
      def self.colored(code : Int32, text : String) : String
        "\e[#{code}m#{text}\e[0m"
      end

      def self.bold(text : String) : String
        colored(1, text)
      end

      def self.dim(text : String) : String
        colored(2, text)
      end

      def self.green(text : String) : String
        colored(32, text)
      end

      def self.yellow(text : String) : String
        colored(33, text)
      end

      def self.red(text : String) : String
        colored(31, text)
      end

      def self.cyan(text : String) : String
        colored(36, text)
      end

      def self.magenta(text : String) : String
        colored(35, text)
      end

      def self.success(msg : String) : Nil
        puts "  #{green("✔")} #{msg}"
      end

      def self.warn(msg : String) : Nil
        puts "  #{yellow("⚠")} #{msg}"
      end

      def self.error(msg : String) : Nil
        puts "  #{red("✖")} #{msg}"
      end

      def self.info(msg : String) : Nil
        puts "  #{cyan("ℹ")} #{msg}"
      end

      def self.banner : Nil
        puts "#{magenta("=== Jasper: Modular Documentation Compiler for Crystal ===\n")}"
      end
    end
  end
end
