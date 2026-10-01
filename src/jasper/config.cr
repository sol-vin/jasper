require "yaml"
require "json"

module Jasper
  class Config
    include YAML::Serializable
    include JSON::Serializable

    class QuickStart
      include YAML::Serializable
      include JSON::Serializable

      property title : String = "Quick-Start Commands"
      property commands : Array(String) = [] of String

      def initialize(@title : String = "Quick-Start Commands", @commands : Array(String) = [] of String)
      end
    end

    class Features
      include YAML::Serializable
      include JSON::Serializable

      property release_guard : Bool = true
      property naming_style : String = "prefixed" # "prefixed" | "natural"
      property prefix_format : String = "topic_%02d_"
      property table_auto_html : Bool = true
      property protect_summary : Bool = true
      property summary_table : Bool = true
      property master_index : Bool = true
      property aliases : Array(String) = [] of String
      property quick_start : QuickStart? = nil
      property search_index_file : String? = nil

      def initialize(
        @release_guard : Bool = true,
        @naming_style : String = "prefixed",
        @prefix_format : String = "topic_%02d_",
        @table_auto_html : Bool = true,
        @protect_summary : Bool = true,
        @summary_table : Bool = true,
        @master_index : Bool = true,
        @aliases : Array(String) = [] of String,
        @quick_start : QuickStart? = nil,
        @search_index_file : String? = nil
      )
      end
    end

    property namespace : String = "Docs"
    property source_dir : String = "docs_src"
    property output_dir : String = "src/docs"
    property master_file : String = "src/docs.cr"
    property features : Features = Features.new

    def initialize(
      @namespace : String = "Docs",
      @source_dir : String = "docs_src",
      @output_dir : String = "src/docs",
      @master_file : String = "src/docs.cr",
      @features : Features = Features.new
    )
    end

    def self.load(path : Path | String) : Config
      content = File.read(path)
      from_yaml(content)
    end

    def self.load?(path : Path | String) : Config?
      return nil unless File.exists?(path)
      load(path)
    rescue
      nil
    end

    def self.find(root : Path | String = ".") : Config
      root_path = Path.new(root)
      ["jasper.yml", "jasper.yaml", ".jasper.yml", ".jasper.yaml"].each do |name|
        candidate = root_path.join(name)
        if File.exists?(candidate)
          return load(candidate)
        end
      end
      new
    end

    def save(path : Path | String) : Nil
      File.write(path, to_yaml)
    end

    def add_alias(alias_name : String) : self
      @features.aliases << alias_name unless @features.aliases.includes?(alias_name)
      self
    end

    def set_quick_start(title : String, commands : Array(String)) : self
      @features.quick_start = QuickStart.new(title, commands)
      self
    end
  end
end
