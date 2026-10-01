module Jasper
  class Pipeline
    class Context
      property config : Config
      property documents : Array(DocDocument) = [] of DocDocument
      property metadata : Hash(String, String) = Hash(String, String).new

      def initialize(@config : Config)
      end
    end

    alias SectionHandler = Proc(IO, YAML::Any, String, Nil)
    alias MarkdownFilter = Proc(String, String)
    alias HookCallback = Proc(Context, Nil)
    alias DocumentCallback = Proc(DocDocument, Context, Nil)

    getter section_handlers = Hash(String, SectionHandler).new
    getter markdown_filters = [] of MarkdownFilter
    getter before_build_hooks = [] of HookCallback
    getter after_build_hooks = [] of HookCallback
    getter on_document_hooks = [] of DocumentCallback

    def register_section_handler(name : String, &handler : IO, YAML::Any, String -> Nil) : Nil
      @section_handlers[name] = handler
    end

    def register_markdown_filter(&filter : String -> String) : Nil
      @markdown_filters << filter
    end

    def before_build(&hook : Context -> Nil) : Nil
      @before_build_hooks << hook
    end

    def after_build(&hook : Context -> Nil) : Nil
      @after_build_hooks << hook
    end

    def on_document(&hook : DocDocument, Context -> Nil) : Nil
      @on_document_hooks << hook
    end

    def apply_markdown_filters(text : String) : String
      current = text
      @markdown_filters.each do |filter|
        current = filter.call(current)
      end
      current
    end

    def trigger_before_build(ctx : Context) : Nil
      @before_build_hooks.each(&.call(ctx))
    end

    def trigger_after_build(ctx : Context) : Nil
      @after_build_hooks.each(&.call(ctx))
    end

    def trigger_on_document(doc : DocDocument, ctx : Context) : Nil
      @on_document_hooks.each(&.call(doc, ctx))
    end
  end
end
