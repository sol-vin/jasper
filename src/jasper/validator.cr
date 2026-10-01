module Jasper
  class Validator
    class Result
      property errors : Array(String) = [] of String
      property warnings : Array(String) = [] of String

      def valid? : Bool
        @errors.empty?
      end
    end

    def self.validate_dir(source_dir : Path | String) : Result
      res = Result.new
      src = Path.new(source_dir)
      unless Dir.exists?(src)
        res.errors << "Source directory '#{source_dir}' does not exist."
        return res
      end

      pattern = src.join("**/*.yml").to_s.tr("\\", "/")
      files = Dir.glob(pattern).sort

      if files.empty?
        res.warnings << "No YAML documentation files found in '#{source_dir}'."
        return res
      end

      seen_ids = Hash(String, String).new

      files.each do |file|
        validate_file(file, res, seen_ids)
      end

      res
    end

    def self.validate_file(file_path : String, res : Result, seen_ids : Hash(String, String) = Hash(String, String).new) : Nil
      rel_path = file_path
      content = File.read(file_path)
      doc = begin
        DocDocument.from_yaml(content)
      rescue ex
        res.errors << "#{rel_path}: YAML parse error: #{ex.message}"
        return
      end

      if doc.id.strip.empty?
        res.errors << "#{rel_path}: Document 'id' cannot be blank."
      elsif seen_ids.has_key?(doc.id)
        res.errors << "#{rel_path}: Duplicate document id '#{doc.id}' (already defined in #{seen_ids[doc.id]})."
      else
        seen_ids[doc.id] = rel_path
      end

      if doc.title.strip.empty?
        res.errors << "#{rel_path}: Document 'title' cannot be blank."
      end

      if doc.summary.strip.empty?
        res.errors << "#{rel_path}: Document 'summary' cannot be blank."
      end

      if doc.sections.empty?
        res.warnings << "#{rel_path}: Document has no sections defined."
      end

      sec_ids = Set(String).new
      doc.sections.each_with_index do |sec, idx|
        if sec.id.strip.empty?
          res.errors << "#{rel_path}: Section ##{idx + 1} has an empty 'id'."
        elsif sec_ids.includes?(sec.id)
          res.errors << "#{rel_path}: Duplicate section id '#{sec.id}' in document '#{doc.id}'."
        else
          sec_ids << sec.id
        end

        if sec.title.strip.empty?
          res.errors << "#{rel_path}: Section '#{sec.id}' has an empty 'title'."
        end

        if sec.summary.strip.empty?
          res.warnings << "#{rel_path}: Section '#{sec.id}' has an empty 'summary'."
        end
      end
    end
  end
end
