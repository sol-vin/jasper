module Jasper
  module MarkdownConverter
    # Converts markdown text into Crystal Docs-compliant doc comments,
    # converting pipe tables to HTML tables and indenting lines.
    def self.to_doc_comments(markdown : String, indent_level : Int32 = 0, convert_tables : Bool = true) : String
      lines = markdown.lines
      result = [] of String
      indent = "  " * indent_level

      i = 0
      while i < lines.size
        line = lines[i]

        # Detect Markdown Pipe Table
        if convert_tables && pipe_table_row?(line) && (i + 1 < lines.size) && pipe_table_separator?(lines[i + 1])
          table_lines = [] of String
          while i < lines.size && pipe_table_row?(lines[i])
            table_lines << lines[i]
            i += 1
          end
          html_table = convert_pipe_table_to_html(table_lines)
          html_table.lines.each do |tline|
            result << "#{indent}# #{tline}".rstrip
          end
          next
        end

        # Regular line
        result << "#{indent}# #{line}".rstrip
        i += 1
      end

      result.join("\n")
    end

    # Checks if a line looks like a markdown table row (e.g. | col1 | col2 |)
    def self.pipe_table_row?(line : String) : Bool
      trimmed = line.strip
      trimmed.starts_with?("|") && trimmed.ends_with?("|") && trimmed.count("|") >= 2
    end

    # Checks if a line is a markdown table separator (e.g. | :--- | :--- |)
    def self.pipe_table_separator?(line : String) : Bool
      trimmed = line.strip
      return false unless pipe_table_row?(trimmed)
      inner = trimmed[1...-1]
      parts = inner.split("|")
      parts.all? { |p| p.strip.matches?(/\A:?-+:?\z/) }
    end

    # Converts a list of pipe table lines to an HTML <table> string
    def self.convert_pipe_table_to_html(lines : Array(String)) : String
      return "" if lines.empty?

      headers = split_table_row(lines[0])
      rows = [] of Array(String)

      (2...lines.size).each do |idx|
        rows << split_table_row(lines[idx])
      end

      String.build do |io|
        io.puts "<table>"
        io.puts "  <thead>"
        io.puts "    <tr>"
        headers.each do |h|
          io.puts "      <th>#{h.strip}</th>"
        end
        io.puts "    </tr>"
        io.puts "  </thead>"
        io.puts "  <tbody>"
        rows.each do |r|
          io.puts "    <tr>"
          r.each_with_index do |cell, idx|
            content = cell.strip
            io.puts "      <td>#{content}</td>"
          end
          io.puts "    </tr>"
        end
        io.puts "  </tbody>"
        io.puts "</table>"
      end
    end

    private def self.split_table_row(line : String) : Array(String)
      trimmed = line.strip
      trimmed = trimmed[1..-1] if trimmed.starts_with?("|")
      trimmed = trimmed[0...-1] if trimmed.ends_with?("|")
      trimmed.split("|")
    end

    # Formats a 1-sentence method doc comment summary without internal periods
    # in the title, protecting Crystal docs method summaries from truncation.
    def self.format_summary_line(title : String, summary : String, protect : Bool = true) : String
      clean_title = protect ? title.gsub(".", "") : title
      clean_summary = summary.strip
      clean_summary = clean_summary.ends_with?(".") ? clean_summary : "#{clean_summary}."
      "# **#{clean_title}**: #{clean_summary}"
    end
  end
end
