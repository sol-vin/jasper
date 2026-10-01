module Jasper
  class SectionBuilder
    getter section : DocSection

    def initialize(id : String, title : String)
      @section = DocSection.new(id: id, title: title, summary: "")
    end

    def summary(text : String) : Nil
      @section.summary = text
    end

    def content(text : String) : Nil
      @section.content = text
    end

    def option(flag : String, description : String) : Nil
      opts = @section.options ||= Hash(String, String).new
      opts[flag] = description
    end

    def example(code : String) : Nil
      exs = @section.examples ||= [] of String
      exs << code
    end

    def pitfall(warning : String) : Nil
      pfs = @section.pitfalls ||= [] of String
      pfs << warning
    end

    def faq(question : String, answer : String) : Nil
      faqs = @section.faqs ||= [] of Hash(String, String)
      faqs << {"q" => question, "a" => answer}
    end

    def topic(item : String) : Nil
      tpcs = @section.topics ||= [] of String
      tpcs << item
    end

    def item(text : String) : Nil
      items = @section.items ||= [] of String
      items << text
    end

    def custom(key : String, value : YAML::Any) : Nil
      custom_data = @section.custom_data ||= Hash(String, YAML::Any).new
      custom_data[key] = value
    end
  end

  class DocumentBuilder
    getter document : DocDocument

    def initialize(id : String, title : String, summary : String, track : String? = nil)
      @document = DocDocument.new(
        id: id,
        title: title,
        summary: summary,
        track: track,
        sections: [] of DocSection
      )
    end

    def overview(text : String) : Nil
      @document.overview = text
    end

    def related_source(source : String) : Nil
      sources = @document.related_sources ||= [] of String
      sources << source
    end

    def root_module(mod : String) : Nil
      @document.root_module = mod
    end

    def parent_module(mod : String) : Nil
      @document.parent_module = mod
    end

    def section(id : String, title : String, &block : SectionBuilder -> Nil) : Nil
      builder = SectionBuilder.new(id, title)
      block.call(builder)
      @document.sections << builder.section
    end
  end

  class TrackBuilder
    getter track_id : String
    getter title : String
    getter documents : Array(DocDocument) = [] of DocDocument

    def initialize(@track_id : String, @title : String = "")
    end

    def document(id : String, title : String, summary : String, &block : DocumentBuilder -> Nil) : Nil
      builder = DocumentBuilder.new(id, title, summary, track: @track_id)
      block.call(builder)
      @documents << builder.document
      Jasper.add_programmatic_document(builder.document)
    end
  end

  # Module-level state & DSL
  @@config = Config.new
  @@pipeline = Pipeline.new
  @@registered_plugins = [] of Plugin
  @@programmatic_documents = [] of DocDocument

  def self.config : Config
    @@config
  end

  def self.config=(c : Config)
    @@config = c
  end

  def self.pipeline : Pipeline
    @@pipeline
  end

  def self.configure(&block : Config -> Nil) : Nil
    block.call(@@config)
  end

  def self.register_plugin(plugin : Plugin) : Nil
    @@registered_plugins << plugin
    plugin.setup(@@pipeline)
  end

  def self.register_section_handler(name : String, &handler : IO, YAML::Any, String -> Nil) : Nil
    @@pipeline.register_section_handler(name, &handler)
  end

  def self.register_markdown_filter(&filter : String -> String) : Nil
    @@pipeline.register_markdown_filter(&filter)
  end

  def self.before_build(&hook : Pipeline::Context -> Nil) : Nil
    @@pipeline.before_build(&hook)
  end

  def self.after_build(&hook : Pipeline::Context -> Nil) : Nil
    @@pipeline.after_build(&hook)
  end

  def self.on_document(&hook : DocDocument, Pipeline::Context -> Nil) : Nil
    @@pipeline.on_document(&hook)
  end

  def self.programmatic_documents : Array(DocDocument)
    @@programmatic_documents
  end

  def self.add_programmatic_document(doc : DocDocument) : Nil
    @@programmatic_documents << doc
  end

  def self.clear_programmatic_documents : Nil
    @@programmatic_documents.clear
  end

  def self.define_track(track_id : String, title : String = "", &block : TrackBuilder -> Nil) : TrackBuilder
    builder = TrackBuilder.new(track_id, title)
    block.call(builder)
    builder
  end
end
