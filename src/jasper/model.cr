require "yaml"
require "json"

module Jasper
  class ComparisonColumn
    include YAML::Serializable
    include JSON::Serializable

    property label : String
    property code : String
    property lang : String = "crystal"
    property badge : String? = nil

    def initialize(
      @label : String,
      @code : String,
      @lang : String = "crystal",
      @badge : String? = nil,
    )
    end
  end

  class ComparisonBlock
    include YAML::Serializable
    include JSON::Serializable

    property title : String? = nil
    property description : String? = nil
    property columns : Array(ComparisonColumn) = [] of ComparisonColumn
    property notes : Array(String)? = nil

    def initialize(
      @columns : Array(ComparisonColumn) = [] of ComparisonColumn,
      @title : String? = nil,
      @description : String? = nil,
      @notes : Array(String)? = nil,
    )
    end
  end

  class DocSection
    include YAML::Serializable
    include JSON::Serializable

    property id : String
    property title : String
    property summary : String
    property type : String? = nil
    property content : String? = nil
    property options : Hash(String, String)? = nil
    property examples : Array(String)? = nil
    property comparisons : Array(ComparisonBlock)? = nil
    property pitfalls : Array(String)? = nil
    property faqs : Array(Hash(String, String))? = nil
    property topics : Array(String)? = nil
    property items : Array(String)? = nil
    property return_value : Array(String)? = nil
    property metadata : Hash(String, String)? = nil
    property custom_data : Hash(String, YAML::Any)? = nil

    def initialize(
      @id : String,
      @title : String,
      @summary : String,
      @type : String? = nil,
      @content : String? = nil,
      @options : Hash(String, String)? = nil,
      @examples : Array(String)? = nil,
      @comparisons : Array(ComparisonBlock)? = nil,
      @pitfalls : Array(String)? = nil,
      @faqs : Array(Hash(String, String))? = nil,
      @topics : Array(String)? = nil,
      @items : Array(String)? = nil,
      @return_value : Array(String)? = nil,
      @metadata : Hash(String, String)? = nil,
      @custom_data : Hash(String, YAML::Any)? = nil,
    )
    end
  end

  class DocDocument
    include YAML::Serializable
    include JSON::Serializable

    property id : String
    property title : String
    property summary : String
    property track : String? = nil
    property root_module : String? = nil
    property parent_module : String? = nil
    property overview : String? = nil
    property related_sources : Array(String)? = nil
    property sections : Array(DocSection) = [] of DocSection

    def initialize(
      @id : String,
      @title : String,
      @summary : String,
      @track : String? = nil,
      @root_module : String? = nil,
      @parent_module : String? = nil,
      @overview : String? = nil,
      @related_sources : Array(String)? = nil,
      @sections : Array(DocSection) = [] of DocSection,
    )
    end

    def resolved_parent_module(default_root : String = "Docs") : String
      if pm = @parent_module
        pm
      elsif t = @track
        root = @root_module || default_root
        if m = t.match(/\A(\d+)_(.+)\z/)
          num = m[1].to_i? || 1
          char = ('A'.ord + (num - 1)).chr
          "#{root}::#{char}_#{m[2].upcase}"
        else
          "#{root}::#{t.upcase}"
        end
      else
        root = @root_module || default_root
        "#{root}::GENERAL"
      end
    end

    def full_module_name(default_root : String = "Docs") : String
      "#{resolved_parent_module(default_root)}::#{id}"
    end
  end

  class DocTrack
    property id : String
    property title : String
    property documents : Array(DocDocument) = [] of DocDocument

    def initialize(@id : String, @title : String = "")
      if @title.empty?
        @title = @id.sub(/^\d+_/, "").gsub(/[-_]/, " ").capitalize
      end
    end
  end
end
