require "html"

module Jasper
  module ComparisonRenderer
    KEYWORDS = Set{
      # Crystal & CRShader DSL
      "class", "struct", "module", "def", "end", "do", "if", "elsif", "else", "unless",
      "while", "until", "case", "when", "then", "return", "break", "next", "include",
      "require", "macro", "property", "getter", "setter", "record", "self", "super",
      "shader_type", "shader", "render_mode", "uniform", "instance_uniform", "global_uniform",
      "group", "subgroup", "uniform_group", "uniform_subgroup", "sampler", "varying",
      "flat_varying", "smooth_varying", "stage", "feature", "when_feature", "unless_feature",
      "shader_trait", "use_trait", "on_vertex", "on_fragment", "on_light", "on_pixel",
      "gradient", "curve", "emit_target", "output_target", "generate_node", "compositor_effect",
      "compositor_pass", "process_pixel", "access", "compute_kernel", "kernel_1d", "kernel_2d",
      "particle_simulation", "step_particles", "local_size", "buffer", "storage_buffer",
      "push_constant", "push_constants", "shared", "image2d", "storage_image", "field",
      "sprite_effect", "screen_effect", "ui_effect", "surface_material", "inspect", "node",

      # GDShader & GLSL 450
      "group_uniforms", "instance", "global", "const", "in", "out", "inout", "flat", "smooth",
      "layout", "readonly", "writeonly", "restrict", "precision", "lowp", "mediump", "highp",
      "for", "switch", "default", "continue", "discard",
    }

    SHADER_TYPES = Set{
      "float", "int", "uint", "bool", "void",
      "vec2", "vec3", "vec4", "ivec2", "ivec3", "ivec4", "uvec2", "uvec3", "uvec4",
      "bvec2", "bvec3", "bvec4", "mat2", "mat3", "mat4",
      "sampler2D", "sampler3D", "samplerCube", "sampler2DArray", "sampler2DShadow",
      "isampler2D", "usampler2D", "image2D", "iimage2D", "uimage2D", "image3D",
      "Float32", "Float64", "Int32", "Int64", "UInt8", "UInt32", "Bool", "Void", "Nil", "String",
      "Vec2", "Vec3", "Vec4", "IVec2", "IVec3", "IVec4", "UVec2", "UVec3", "UVec4",
      "Mat2", "Mat3", "Mat4", "Color", "Vector2", "Vector3", "Vector4",
      "Sampler2D", "Sampler3D", "SamplerCube", "PackedColorArray", "ColorPalette",
      "InOut", "Out", "Array", "Bytes",
    }

    BOOL_AND_BUILTINS = Set{
      "true", "false", "nil",
      "UV", "UV2", "SCREEN_UV", "FRAGCOORD", "TIME", "PI", "TAU",
      "VERTEX", "POSITION", "NORMAL", "TANGENT", "BINORMAL", "VIEW",
      "COLOR", "TEXTURE", "TEXTURE_PIXEL_SIZE", "SCREEN_PIXEL_SIZE", "VIEWPORT_SIZE",
      "ALBEDO", "ALPHA", "ROUGHNESS", "METALLIC", "SPECULAR", "EMISSION",
      "MODEL_MATRIX", "VIEW_MATRIX", "PROJECTION_MATRIX", "INV_VIEW_MATRIX", "INV_PROJECTION_MATRIX",
      "LIGHT", "LIGHT_COLOR", "ATTENUATION", "DIFFUSE_LIGHT", "SPECULAR_LIGHT",
      "gl_GlobalInvocationID", "gl_LocalInvocationID", "gl_WorkGroupID", "gl_WorkGroupSize",
    }

    # Renders an array of ComparisonBlocks into indented Crystal doc comment lines.
    # Every line inside `<div class="jasper-comparison">...</div>` is guaranteed non-blank
    # so CommonMark / Markd Type-6 HTML blocks never terminate prematurely on empty code lines.
    def self.render_to_doc_comments(blocks : Array(ComparisonBlock), indent_level : Int32 = 4) : String
      m_pad = "#{"  " * indent_level}#"
      String.build do |io|
        io.puts "#{m_pad} #### Side-by-Side Output Comparison"
        io.puts m_pad

        blocks.each_with_index do |block, b_idx|
          io.puts m_pad if b_idx > 0
          html = render_block_html(block)
          html.each_line(chomp: true) do |line|
            safe_line = line.strip.empty? ? "<span></span>" : line
            io.puts "#{m_pad} #{safe_line}"
          end
        end
      end.rstrip
    end

    def self.render_block_html(block : ComparisonBlock) : String
      col_count = Math.max(block.columns.size, 1)
      min_col_px = col_count >= 3 ? 280 : 320

      String.build do |io|
        io.puts %(<div class="jasper-comparison" style="width:100%;max-width:100%;margin:16px 0 24px;box-sizing:border-box;">)

        if (title = block.title) || (desc = block.description)
          io.puts %(  <div class="jasper-comparison-header" style="margin-bottom:10px;">)
          if title = block.title
            io.puts %(    <div class="jasper-comparison-title" style="font-weight:700;font-size:15px;margin-bottom:3px;">#{HTML.escape(title)}</div>)
          end
          if desc = block.description
            io.puts %(    <div class="jasper-comparison-desc" style="font-size:13.5px;opacity:0.86;line-height:1.45;">#{format_inline_code(desc)}</div>)
          end
          io.puts %(  </div>)
        end

        io.puts %(  <div class="jasper-comparison-grid" style="display:grid;grid-template-columns:repeat(auto-fit,minmax(#{min_col_px}px,1fr));gap:12px;align-items:stretch;width:100%;">)

        block.columns.each do |col|
          badge_text = col.badge || default_badge_for(col.lang)
          badge_cls = badge_class_for(badge_text, col.lang)
          lang_norm = normalize_lang(col.lang)
          highlighted = highlight_code(col.code.rstrip, lang_norm)

          io.puts %(    <div class="jasper-comparison-col" style="display:flex;flex-direction:column;min-width:0;border:1px solid rgba(128,128,128,0.28);border-radius:6px;overflow:hidden;">)
          io.puts %(      <div class="jasper-comparison-col-header" style="display:flex;align-items:center;justify-content:space-between;gap:8px;padding:7px 12px;font-size:12.5px;font-weight:600;border-bottom:1px solid rgba(128,128,128,0.22);background:rgba(127,127,127,0.08);">)
          io.puts %(        <span class="jasper-comparison-label">#{HTML.escape(col.label)}</span>)
          io.puts %(        <span class="jasper-badge #{badge_cls}" style="font-size:10.5px;font-weight:700;padding:2px 6px;border-radius:4px;letter-spacing:0.04em;white-space:nowrap;">#{HTML.escape(badge_text)}</span>)
          io.puts %(      </div>)
          io.print %(      <pre style="flex:1;margin:0;padding:12px 14px;border:0;border-radius:0;overflow-x:auto;text-align:left;font-size:12.8px;line-height:1.45;tab-size:2;"><code class="language-#{lang_norm}">)

          code_lines = highlighted.split('\n')
          code_lines.each_with_index do |cline, lidx|
            io << '\n' if lidx > 0
            io << (cline.empty? ? "<span></span>" : cline)
          end
          io.puts %(</code></pre>)
          io.puts %(    </div>)
        end

        io.puts %(  </div>)

        if (notes = block.notes) && !notes.empty?
          io.puts %(  <ul class="jasper-comparison-notes" style="margin:9px 0 0;padding-left:20px;max-width:100%;font-size:13px;line-height:1.45;">)
          notes.each do |note|
            io.puts %(    <li style="max-width:100%;margin:2px 0;">#{format_inline_code(note)}</li>)
          end
          io.puts %(  </ul>)
        end

        io.puts %(</div>)
      end.rstrip
    end

    def self.format_inline_code(text : String) : String
      escaped = HTML.escape(text)
        .gsub("{%", "&#123;%")
        .gsub("%}", "%&#125;")
        .gsub("{{", "&#123;&#123;")
        .gsub("}}", "&#125;&#125;")
      escaped
        .gsub(/`([^`]+)`/, "<code>\\1</code>")
        .gsub(/\*\*([^*]+)\*\*/, "<strong>\\1</strong>")
    end

    def self.normalize_lang(lang : String) : String
      case lang.strip.downcase
      when "crshader", "cr", "crystal"
        "crystal"
      when "gdshader", "gdshaderinc", "godot"
        "gdshader"
      when "glsl", "compute"
        "glsl"
      else
        lang.strip.downcase.gsub(/[^a-z0-9_-]/, "")
      end
    end

    def self.default_badge_for(lang : String) : String
      case lang.strip.downcase
      when "crshader"    then "SOURCE"
      when "crystal"     then "CRYSTAL"
      when "gdshader"    then "GDSHADER"
      when "gdshaderinc" then "GDSHADERINC"
      when "glsl"        then "GLSL 450"
      else                    lang.upcase
      end
    end

    def self.badge_class_for(badge : String, lang : String) : String
      up = "#{badge} #{lang}".upcase
      if up.includes?("GDSHADERINC") || up.includes?("HEADER")
        "jasper-badge-inc"
      elsif up.includes?("RELEASE") || up.includes?("VARIANT")
        "jasper-badge-release"
      elsif up.includes?("NODE")
        "jasper-badge-node"
      elsif up.includes?("GLSL") || up.includes?("COMPUTE") || up.includes?("COMPOSITOR")
        "jasper-badge-glsl"
      elsif up.includes?("GDSHADER")
        "jasper-badge-gdshader"
      else
        "jasper-badge-source"
      end
    end

    # Single-pass lexical highlighter producing Crystal Docs native token spans (.c, .k, .t, .m, .n, .s, .o, .i).
    def self.highlight_code(raw : String, lang : String = "crystal") : String
      code = raw.gsub("\r\n", "\n").gsub('\t', "  ")
      is_crystal = (lang == "crystal")
      chars = code.chars
      len = chars.size
      i = 0

      String.build(code.bytesize * 2) do |io|
        while i < len
          ch = chars[i]

          # 1. C-style block comment /* ... */
          if ch == '/' && (i + 1 < len) && chars[i + 1] == '*'
            start = i
            i += 2
            while i < len && !(chars[i] == '*' && (i + 1 < len) && chars[i + 1] == '/')
              i += 1
            end
            i += 2 if i < len
            emit_multiline_span(io, "c", code[start...i])
            next
          end

          # 2. C-style line comment // ...
          if ch == '/' && (i + 1 < len) && chars[i + 1] == '/'
            start = i
            while i < len && chars[i] != '\n'
              i += 1
            end
            io << %(<span class="c">) << HTML.escape(code[start...i]) << %(</span>)
            next
          end

          # 3. Preprocessor (#version, #ifndef, #define, #endif, #include, #[compute]) vs Crystal # comment
          if ch == '#'
            start = i
            if !is_crystal || code[i..].starts_with?("#include") || code[i..].starts_with?("#define") ||
               code[i..].starts_with?("#ifdef") || code[i..].starts_with?("#ifndef") ||
               code[i..].starts_with?("#endif") || code[i..].starts_with?("#version") || code[i..].starts_with?("#[")
              while i < len && chars[i] != '\n'
                i += 1
              end
              io << %(<span class="i">) << HTML.escape(code[start...i]) << %(</span>)
            else
              while i < len && chars[i] != '\n'
                i += 1
              end
              io << %(<span class="c">) << HTML.escape(code[start...i]) << %(</span>)
            end
            next
          end

          # 4. Crystal macro delimiters {% ... %} or {{ ... }}
          # Escape `{` and `}` as HTML entities so files wrapped in `{% unless flag?(:release) %}`
          # never trigger Crystal's outer macro lexer on doc-comment lines!
          if ch == '{' && (i + 1 < len) && (chars[i + 1] == '%' || chars[i + 1] == '{')
            closing = chars[i + 1] == '%' ? "%}" : "}}"
            start = i
            i += 2
            while i < len && !code[i..].starts_with?(closing)
              i += 1
            end
            i += 2 if i < len
            escaped_macro = HTML.escape(code[start...i])
              .gsub("{%", "&#123;%")
              .gsub("%}", "%&#125;")
              .gsub("{{", "&#123;&#123;")
              .gsub("}}", "&#125;&#125;")
            lines = escaped_macro.split('\n')
            lines.each_with_index do |part, idx|
              io << '\n' if idx > 0
              io << %(<span class="i">) << part << %(</span>) unless part.empty?
            end
            next
          end

          # 5. String literal "..."
          if ch == '"'
            start = i
            i += 1
            while i < len && chars[i] != '"'
              i += 1 if chars[i] == '\\' && (i + 1 < len)
              i += 1
            end
            i += 1 if i < len
            emit_multiline_span(io, "s", code[start...i])
            next
          end

          # 6. Crystal annotation @[...] or instance/class var @foo
          if ch == '@'
            start = i
            if (i + 1 < len) && chars[i + 1] == '['
              depth = 0
              i += 1
              while i < len
                depth += 1 if chars[i] == '['
                if chars[i] == ']'
                  depth -= 1
                  i += 1
                  break if depth <= 0
                  next
                end
                i += 1
              end
              io << %(<span class="i">) << HTML.escape(code[start...i]) << %(</span>)
              next
            elsif (i + 1 < len) && ident_start?(chars[i + 1])
              i += 1
              while i < len && ident_part?(chars[i])
                i += 1
              end
              io << %(<span class="i">) << HTML.escape(code[start...i]) << %(</span>)
              next
            end
          end

          # 7. Crystal symbol :foo (not :: namespace separator and not `x : Type` spacing)
          if is_crystal && ch == ':' && (i + 1 < len) && ident_start?(chars[i + 1]) && !(i > 0 && chars[i - 1] == ':')
            start = i
            i += 1
            while i < len && (ident_part?(chars[i]) || chars[i] == '?' || chars[i] == '!')
              i += 1
            end
            io << %(<span class="i">) << HTML.escape(code[start...i]) << %(</span>)
            next
          end

          # 8. Numeric literal
          if ch.ascii_number?
            start = i
            i += 1
            while i < len && (chars[i].ascii_alphanumeric? || chars[i] == '_' || (chars[i] == '.' && (i + 1 < len) && chars[i + 1].ascii_number?))
              i += 1
            end
            io << %(<span class="n">) << HTML.escape(code[start...i]) << %(</span>)
            next
          end

          # 9. Identifier / Keyword / Type / Method
          if ident_start?(ch)
            prev_non_space = i > 0 ? chars[i - 1] : '\0'
            start = i
            i += 1
            while i < len && ident_part?(chars[i])
              i += 1
            end
            if is_crystal && i < len && (chars[i] == '?' || chars[i] == '!')
              i += 1
            end
            word = code[start...i]
            next_ch = i < len ? chars[i] : '\0'

            cls = if KEYWORDS.includes?(word)
                    "k"
                  elsif SHADER_TYPES.includes?(word) || (word[0].ascii_uppercase? && word.each_char.any?(&.ascii_lowercase?))
                    "t"
                  elsif BOOL_AND_BUILTINS.includes?(word) || (word.size >= 2 && word.each_char.all? { |c| c.ascii_uppercase? || c.ascii_number? || c == '_' })
                    "n"
                  elsif next_ch == '(' || prev_non_space == '.'
                    "m"
                  else
                    nil
                  end

            if cls
              io << %(<span class="#{cls}">) << HTML.escape(word) << %(</span>)
            else
              io << HTML.escape(word)
            end
            next
          end

          # 10. Operators
          if "=+-*/%&|^!<>?".includes?(ch)
            start = i
            i += 1
            while i < len && "=+-*/%&|^!<>".includes?(chars[i])
              # Do not consume start of /* or // comment!
              break if chars[i] == '/' && (i + 1 < len) && (chars[i + 1] == '/' || chars[i + 1] == '*')
              i += 1
            end
            io << %(<span class="o">) << HTML.escape(code[start...i]) << %(</span>)
            next
          end

          # 11. Default character
          case ch
          when '&' then io << "&amp;"
          when '<' then io << "&lt;"
          when '>' then io << "&gt;"
          else          io << ch
          end
          i += 1
        end
      end
    end

    private def self.emit_multiline_span(io : IO, cls : String, segment : String) : Nil
      lines = segment.split('\n')
      lines.each_with_index do |part, idx|
        io << '\n' if idx > 0
        io << %(<span class="#{cls}">) << HTML.escape(part) << %(</span>) unless part.empty?
      end
    end

    private def self.ident_start?(c : Char) : Bool
      c.ascii_letter? || c == '_'
    end

    private def self.ident_part?(c : Char) : Bool
      c.ascii_alphanumeric? || c == '_'
    end
  end

  module CssPatcher
    MARKER = "/* jasper:comparisons */"

    STYLESHEET = <<-CSS

    /* jasper:comparisons */
    .main-content .jasper-comparison {
      width: 100%;
      max-width: 100%;
      margin: 18px 0 28px;
      box-sizing: border-box;
    }

    .main-content .jasper-comparison-header {
      margin-bottom: 10px;
    }

    .main-content .jasper-comparison-title {
      font-weight: 700;
      font-size: 15.5px;
      color: #2E1052;
      margin-bottom: 3px;
    }

    .main-content .jasper-comparison-desc {
      font-size: 13.5px;
      color: #555555;
      max-width: 78em;
    }

    .main-content .jasper-comparison-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(290px, 1fr));
      gap: 14px;
      align-items: stretch;
      width: 100%;
    }

    .main-content .jasper-comparison-col {
      display: flex;
      flex-direction: column;
      min-width: 0;
      background: #fdfdfd;
      border: 1px solid #e2dfea;
      border-radius: 6px;
      overflow: hidden;
      box-shadow: 0 1px 3px rgba(46, 16, 82, 0.05);
    }

    .main-content .jasper-comparison-col-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 8px;
      padding: 7px 12px;
      background: #f4f1f8;
      border-bottom: 1px solid #e2dfea;
      font-size: 12.5px;
      font-weight: 600;
      color: #3a2359;
    }

    .main-content .jasper-comparison-col pre {
      flex: 1;
      margin: 0;
      padding: 12px 14px;
      border: 0;
      border-radius: 0;
      background: transparent;
      font-size: 12.8px;
      line-height: 1.45;
      text-align: left;
      overflow-x: auto;
      tab-size: 2;
    }

    .main-content .jasper-badge {
      font-family: Menlo, Monaco, Consolas, monospace;
      font-size: 10.5px;
      font-weight: 700;
      padding: 2px 7px;
      border-radius: 4px;
      letter-spacing: 0.04em;
    }

    .main-content .jasper-badge-source {
      background: #ede4fa;
      color: #47266E;
      border: 1px solid #cdb6ee;
    }

    .main-content .jasper-badge-gdshader {
      background: #e0f2fe;
      color: #075985;
      border: 1px solid #bae6fd;
    }

    .main-content .jasper-badge-glsl {
      background: #ffedd5;
      color: #9a3412;
      border: 1px solid #fed7aa;
    }

    .main-content .jasper-badge-inc {
      background: #ccfbf1;
      color: #115e59;
      border: 1px solid #99f6e4;
    }

    .main-content .jasper-badge-release {
      background: #dcfce7;
      color: #166534;
      border: 1px solid #bbf7d0;
    }

    .main-content .jasper-badge-node {
      background: #fae8ff;
      color: #86198f;
      border: 1px solid #f5d0fe;
    }

    .main-content .jasper-comparison-notes,
    .main-content .jasper-comparison-notes li {
      max-width: 82em;
    }

    @media (prefers-color-scheme: dark) {
      .main-content .jasper-comparison-title {
        color: #e2d4f8;
      }

      .main-content .jasper-comparison-desc {
        color: #b8b8c2;
      }

      .main-content .jasper-comparison-col {
        background: #202024;
        border-color: #383842;
        box-shadow: 0 2px 6px rgba(0, 0, 0, 0.28);
      }

      .main-content .jasper-comparison-col-header {
        background: #2a2733;
        border-bottom-color: #383842;
        color: #eae4f4;
      }

      .main-content .jasper-badge-source {
        background: #3b2659;
        color: #eadcfd;
        border-color: #6b499e;
      }

      .main-content .jasper-badge-gdshader {
        background: #133852;
        color: #bae6fd;
        border-color: #1e567c;
      }

      .main-content .jasper-badge-glsl {
        background: #4d2410;
        color: #fed7aa;
        border-color: #7c3a19;
      }

      .main-content .jasper-badge-inc {
        background: #13403c;
        color: #99f6e4;
        border-color: #1d635d;
      }

      .main-content .jasper-badge-release {
        background: #143d24;
        color: #bbf7d0;
        border-color: #21633b;
      }

      .main-content .jasper-badge-node {
        background: #44194a;
        color: #f5d0fe;
        border-color: #702a78;
      }
    }
    CSS

    def self.patch(docs_dir : Path | String) : Bool
      css_file = Path.new(docs_dir).join("css/style.css")
      return false unless File.exists?(css_file)

      existing = File.read(css_file)
      return false if existing.includes?(MARKER)

      File.write(css_file, existing.rstrip + "\n" + STYLESHEET + "\n")
      true
    end
  end
end
