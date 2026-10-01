require "json"

module Jasper
  class Indexer
    struct SectionEntry
      include JSON::Serializable

      property id : String
      property title : String
      property summary : String
      property anchor : String
      property options : Array(String)
      property topics : Array(String)

      def initialize(
        @id : String,
        @title : String,
        @summary : String,
        @anchor : String,
        @options : Array(String) = [] of String,
        @topics : Array(String) = [] of String
      )
      end
    end

    struct DocumentEntry
      include JSON::Serializable

      property id : String
      property title : String
      property summary : String
      property track : String
      property module_name : String
      property sections : Array(SectionEntry)

      def initialize(
        @id : String,
        @title : String,
        @summary : String,
        @track : String,
        @module_name : String,
        @sections : Array(SectionEntry) = [] of SectionEntry
      )
      end
    end

    struct Index
      include JSON::Serializable

      property version : String = "1.0"
      property generated_at : String
      property documents : Array(DocumentEntry)

      def initialize(@documents : Array(DocumentEntry) = [] of DocumentEntry)
        @generated_at = Time.utc.to_s("%Y-%m-%dT%H:%M:%SZ")
      end
    end

    def self.build_index(docs : Array(DocDocument), default_root : String = "Docs") : Index
      entries = [] of DocumentEntry

      docs.each do |doc|
        sec_entries = [] of SectionEntry
        doc.sections.each do |sec|
          opts = sec.options ? sec.options.not_nil!.keys : [] of String
          tpcs = sec.topics || sec.items || [] of String
          sec_entries << SectionEntry.new(
            id: sec.id,
            title: sec.title,
            summary: sec.summary,
            anchor: ".#{sec.id}",
            options: opts,
            topics: tpcs
          )
        end

        entries << DocumentEntry.new(
          id: doc.id,
          title: doc.title,
          summary: doc.summary,
          track: doc.track || "general",
          module_name: doc.full_module_name(default_root),
          sections: sec_entries
        )
      end

      Index.new(entries)
    end

    def self.export_json(docs : Array(DocDocument), path : Path | String, default_root : String = "Docs") : Nil
      idx = build_index(docs, default_root)
      File.write(path, idx.to_pretty_json)
    end
  end
end
