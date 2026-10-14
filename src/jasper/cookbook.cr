require "json"
require "yaml"
require "./model"
require "./validator"

module Jasper
  module Cookbook
    MAX_WATCHDOG_BUDGET_SECONDS = 60

    # Tier 1: Pure Engine Value Type representing a shard's Two-Tier DSL & Hardening blueprint
    struct ShardPattern
      include JSON::Serializable
      include YAML::Serializable

      property shard_name : String
      property repository : String
      property doc_id : String
      property tier_one_engine : Array(String)
      property tier_two_dsl : Array(String)
      property hardening_gate : String
      property watchdog_budget_seconds : Int32

      def initialize(
        @shard_name : String,
        @repository : String,
        @doc_id : String,
        @tier_one_engine : Array(String) = [] of String,
        @tier_two_dsl : Array(String) = [] of String,
        @hardening_gate : String = "",
        @watchdog_budget_seconds : Int32 = MAX_WATCHDOG_BUDGET_SECONDS,
      )
      end

      def valid? : Bool
        !@shard_name.strip.empty? &&
          !@repository.strip.empty? &&
          !@doc_id.strip.empty? &&
          !@tier_one_engine.empty? &&
          !@tier_two_dsl.empty? &&
          !@hardening_gate.strip.empty? &&
          @watchdog_budget_seconds > 0 &&
          @watchdog_budget_seconds <= MAX_WATCHDOG_BUDGET_SECONDS
      end
    end

    # Tier 1: Core Cookbook Catalog Engine
    class Catalog
      include JSON::Serializable
      include YAML::Serializable

      property title : String
      property track_id : String
      property patterns : Array(ShardPattern)

      def initialize(
        @title : String = "Two-Tier Crystal DSL & Hardening Cookbook",
        @track_id : String = "05_hardening_cookbook",
        @patterns : Array(ShardPattern) = [] of ShardPattern,
      )
      end

      def register(pattern : ShardPattern) : self
        raise ArgumentError.new("Invalid ShardPattern for '#{pattern.shard_name}' (watchdog must be 1..#{MAX_WATCHDOG_BUDGET_SECONDS}s and tiers non-empty)") unless pattern.valid?
        @patterns.reject! { |p| p.shard_name == pattern.shard_name }
        @patterns << pattern
        self
      end

      def find(shard_name : String) : ShardPattern?
        @patterns.find { |p| p.shard_name == shard_name }
      end

      def shard_names : Array(String)
        @patterns.map(&.shard_name)
      end

      def valid? : Bool
        !@patterns.empty? && @patterns.all?(&.valid?)
      end

      # Loads and validates all YAML documents belonging to this cookbook track from a source directory
      def load_documents(source_dir : Path | String = "docs_src") : Array(DocDocument)
        track_path = Path.new(source_dir).join(@track_id)
        return [] of DocDocument unless Dir.exists?(track_path)

        clean_dir = track_path.to_s.tr("\\", "/")
        docs = [] of DocDocument
        Dir.glob("#{clean_dir}/*.yml").sort.each do |yfile|
          docs << DocDocument.from_yaml(File.read(yfile))
        end
        docs
      end

      def to_markdown_table : String
        String.build do |io|
          io.puts "# #{@title}"
          io.puts ""
          io.puts "| Shard | Repository | Doc ID | Tier 1 Engine | Tier 2 DSL | Hardening Gate | Watchdog |"
          io.puts "| :--- | :--- | :--- | :--- | :--- | :--- | :--- |"
          @patterns.each do |p|
            t1 = p.tier_one_engine.map { |x| "`#{x}`" }.join(", ")
            t2 = p.tier_two_dsl.map { |x| "`#{x}`" }.join(", ")
            io.puts "| **#{p.shard_name}** | `#{p.repository}` | `#{p.doc_id}` | #{t1} | #{t2} | #{p.hardening_gate} | `<= #{p.watchdog_budget_seconds}s` |"
          end
        end
      end
    end

    # Tier 2: Declarative Builder for individual shard patterns
    class PatternBuilder
      property shard_name : String
      property repository : String = ""
      property doc_id : String = ""
      property tier_one_engine : Array(String) = [] of String
      property tier_two_dsl : Array(String) = [] of String
      property hardening_gate : String = ""
      property watchdog_budget_seconds : Int32 = MAX_WATCHDOG_BUDGET_SECONDS

      def initialize(@shard_name : String)
      end

      def repository(repo : String) : self
        @repository = repo
        self
      end

      def doc_id(id : String) : self
        @doc_id = id
        self
      end

      def tier_one(*primitives : String) : self
        primitives.each { |p| @tier_one_engine << p unless @tier_one_engine.includes?(p) }
        self
      end

      def tier_two(*builders : String) : self
        builders.each { |b| @tier_two_dsl << b unless @tier_two_dsl.includes?(b) }
        self
      end

      def hardening_gate(gate : String) : self
        @hardening_gate = gate
        self
      end

      def watchdog_budget(seconds : Int32) : self
        @watchdog_budget_seconds = seconds
        self
      end

      def build : ShardPattern
        ShardPattern.new(
          shard_name: @shard_name,
          repository: @repository,
          doc_id: @doc_id,
          tier_one_engine: @tier_one_engine,
          tier_two_dsl: @tier_two_dsl,
          hardening_gate: @hardening_gate,
          watchdog_budget_seconds: @watchdog_budget_seconds
        )
      end
    end

    # Tier 2: Declarative Builder for the Multi-Shard Cookbook Catalog
    class CatalogBuilder
      getter catalog : Catalog

      def initialize(title : String = "Two-Tier Crystal DSL & Hardening Cookbook", track_id : String = "05_hardening_cookbook")
        @catalog = Catalog.new(title: title, track_id: track_id)
      end

      def track(id : String) : self
        @catalog.track_id = id
        self
      end

      def shard(name : String, &block : PatternBuilder -> Nil) : self
        builder = PatternBuilder.new(name)
        yield builder
        @catalog.register(builder.build)
        self
      end

      def build : Catalog
        @catalog
      end
    end

    # Returns the canonical Sol-Vin Multi-Shard Two-Tier DSL & Hardening Cookbook catalog
    def self.canonical_catalog : Catalog
      Jasper.define_cookbook("Two-Tier Crystal DSL & Hardening Cookbook") do |cb|
        cb.track "05_hardening_cookbook"

        cb.shard "carbon" do |s|
          s.repository "sol-vin/carbon"
          s.doc_id "CARBON_COOKBOOK"
          s.tier_one "Carbon::Version", "Carbon::VCS::Git", "Carbon::FileManager", "Carbon::CI::WorkflowStandardizer"
          s.tier_two "Carbon.ci", "Carbon.hooks", "Carbon.version!", "Carbon.bump!"
          s.hardening_gate "Squash-resilient monotonic commit-count check & standardized CI workflow gate"
          s.watchdog_budget 60
        end

        cb.shard "crowbar" do |s|
          s.repository "sol-vin/crowbar"
          s.doc_id "CROWBAR_COOKBOOK"
          s.tier_one "Crowbar::Core::CorpusRunner", "Crowbar::Core::CorpusSeed", "Crowbar::Minimizer::Reducer"
          s.tier_two "Crowbar.corpus_gate", "Crowbar.define", "scope", "preserve", "fixup"
          s.hardening_gate "Deterministic PRNG seed replay & delta-debugging crash minimization inside crystal spec"
          s.watchdog_budget 60
        end

        cb.shard "bakelite" do |s|
          s.repository "sol-vin/bakelite"
          s.doc_id "BAKELITE_COOKBOOK"
          s.tier_one "Bakelite::FS::Registry", "Bakelite::Container::Reader", "Bakelite::Container::Writer", "Bakelite::FileIO"
          s.tier_two "bake", "store", "bake_manifest", "volume", "Bakelite.verify_archive"
          s.hardening_gate "32-byte BKLEND trailer validation, per-chunk CRC32 & SHA-256 content addressing"
          s.watchdog_budget 60
        end

        cb.shard "opal" do |s|
          s.repository "sol-vin/opal"
          s.doc_id "OPAL_COOKBOOK"
          s.tier_one "Opal::UI::Buffer", "Opal::UI::DiffRenderer", "Opal::TEA::Model", "Opal::Terminal::ANSIParser"
          s.tier_two "Opal::UI.build", "Opal::UI.split_pane", "Opal::Input.remap", "Opal::CLI::App"
          s.hardening_gate "Headless Opal::Testing::Pilot frame assertions & Crowbar ANSIParser fuzz gate"
          s.watchdog_budget 60
        end
      end
    end
  end

  # Tier 2 Top-Level Entry Point for defining a Multi-Shard Cookbook Catalog
  def self.define_cookbook(
    title : String = "Two-Tier Crystal DSL & Hardening Cookbook",
    track_id : String = "05_hardening_cookbook",
    &block : Cookbook::CatalogBuilder -> Nil
  ) : Cookbook::Catalog
    builder = Cookbook::CatalogBuilder.new(title: title, track_id: track_id)
    yield builder
    builder.build
  end
end
