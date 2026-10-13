require "json"
require "yaml"
require "file_utils"
require "./config"
require "./indexer"
require "./model"

module Jasper
  # Represents metadata for an individual indexed Crystal shard
  struct ShardDocMetadata
    include JSON::Serializable

    property name : String
    property version : String
    property description : String
    property path : String
    property doc_count : Int32
    property documents : Array(Indexer::DocumentEntry)

    def initialize(
      @name : String,
      @version : String,
      @description : String,
      @path : String,
      @doc_count : Int32,
      @documents : Array(Indexer::DocumentEntry) = [] of Indexer::DocumentEntry
    )
    end
  end

  # Master cross-shard documentation catalog for the organization
  struct OrganizationIndex
    include JSON::Serializable

    property title : String
    property generated_at : Time
    property total_shards : Int32
    property total_docs : Int32
    property shards : Array(ShardDocMetadata)

    def initialize(
      @title : String,
      @generated_at : Time,
      @total_shards : Int32,
      @total_docs : Int32,
      @shards : Array(ShardDocMetadata) = [] of ShardDocMetadata
    )
    end

    def to_markdown_summary : String
      String.build do |io|
        io.puts "# #{@title}"
        io.puts ""
        io.puts "Generated at: `#{@generated_at.to_s}` across **#{@total_shards}** shards with **#{@total_docs}** total documentation topics."
        io.puts ""
        io.puts "| Shard | Version | Topics | Description |"
        io.puts "| :--- | :--- | :--- | :--- |"
        @shards.each do |s|
          io.puts "| **#{s.name}** | `v#{s.version}` | #{s.doc_count} | #{s.description.strip} |"
        end
      end
    end
  end

  # Tier 1: Core Multi-Shard Indexer Engine
  class MultiShardIndexer
    property search_paths : Array(String)
    property title : String

    def initialize(@search_paths : Array(String) = [] of String, @title : String = "Sol-Vin Organization Master Documentation Index")
    end

    def add_path(path : String) : self
      @search_paths << path unless @search_paths.includes?(path)
      self
    end

    # Scans candidate paths for shard.yml and jasper.yml and indexes documentation
    def build_index : OrganizationIndex
      shard_entries = [] of ShardDocMetadata

      @search_paths.each do |dir|
        next unless Dir.exists?(dir)

        shard_yml = File.join(dir, "shard.yml")
        jasper_yml = File.join(dir, "jasper.yml")

        # Must have shard.yml or jasper.yml
        next unless File.exists?(shard_yml) || File.exists?(jasper_yml)

        shard_name = File.basename(File.expand_path(dir))
        shard_version = "0.1.0"
        shard_desc = "No description provided."

        if File.exists?(shard_yml)
          begin
            raw_shard = YAML.parse(File.read(shard_yml))
            shard_name = raw_shard["name"]?.try(&.as_s) || shard_name
            shard_version = raw_shard["version"]?.try(&.as_s) || shard_version
            shard_desc = raw_shard["description"]?.try(&.as_s) || shard_desc
          rescue
            # Fall back to defaults
          end
        end

        config = Config.find(dir)
        source_dir = File.join(dir, config.source_dir)

        documents = [] of DocDocument
        if Dir.exists?(source_dir)
          clean_src = source_dir.tr("\\", "/")
          Dir.glob("#{clean_src}/**/*.yml").sort.each do |yfile|
            begin
              documents << DocDocument.from_yaml(File.read(yfile))
            rescue
            end
          end
        end

        index_entries = Indexer.build_index(documents, config.namespace).documents

        shard_entries << ShardDocMetadata.new(
          name: shard_name,
          version: shard_version,
          description: shard_desc.lines.first?.try(&.strip) || "",
          path: dir,
          doc_count: index_entries.size,
          documents: index_entries
        )
      end

      OrganizationIndex.new(
        title: @title,
        generated_at: Time.utc,
        total_shards: shard_entries.size,
        total_docs: shard_entries.sum(&.doc_count),
        shards: shard_entries
      )
    end
  end

  # Tier 2: Declarative Builder DSL
  def self.index_shards(paths : Array(String), title : String = "Sol-Vin Organization Master Documentation Index", &block : MultiShardIndexer -> Nil) : OrganizationIndex
    indexer = MultiShardIndexer.new(paths, title: title)
    yield indexer
    indexer.build_index
  end
end
