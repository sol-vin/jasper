require "./spec_helper"

describe Jasper::ComparisonRenderer do
  it "parses YAML comparisons and renders CommonMark-safe side-by-side HTML doc comments" do
    yaml = <<-YAML
    id: A_COMPARISONS
    title: "Side-by-Side Comparisons"
    summary: "Compare DSL and compiled targets."
    track: "01_guides"
    sections:
      - id: topic_01_demo
        title: "Class Lowering"
        summary: "Compiles Crystal classes to GDShader and GLSL."
        comparisons:
          - title: "Rim Class Comparison"
            description: "Compares `.crshader` source against **GDShader** and **GLSL**."
            columns:
              - label: "CRShader (.crshader)"
                lang: "crshader"
                badge: "SOURCE"
                code: |
                  class Rim
                    power : Float32

                    def eval(n : Vec3) : Float32
                      n.x ** @power
                    end
                  end
              - label: "Godot 4 (.gdshader)"
                lang: "gdshader"
                badge: "GDSHADER"
                code: |
                  struct Rim {
                    float power;
                  };

                  float Rim_eval(Rim _self, vec3 n) {
                    return pow(n.x, _self.power);
                  }
              - label: "Vulkan (.glsl)"
                lang: "glsl"
                badge: "GLSL 450"
                code: |
                  #version 450
                  struct Rim { float power; };
            notes:
              - "Unused methods are pruned by `TreeShaker`."
    YAML

    doc = Jasper::DocDocument.from_yaml(yaml)
    sec = doc.sections.first
    cmps = sec.comparisons.should_not be_nil
    cmps.size.should eq(1)
    cmps.first.columns.size.should eq(3)

    rendered = Jasper::ComparisonRenderer.render_to_doc_comments(cmps, indent_level: 2)
    rendered.should contain("#### Side-by-Side Output Comparison")
    rendered.should contain("class=\"jasper-comparison\"")
    rendered.should contain("jasper-badge-source")
    rendered.should contain("jasper-badge-gdshader")
    rendered.should contain("jasper-badge-glsl")
    rendered.should contain("<span class=\"k\">class</span> <span class=\"t\">Rim</span>")
    rendered.should contain("<span class=\"i\">#version 450</span>")
    rendered.should contain("<code>TreeShaker</code>")

    # Ensure zero blank doc-comment lines exist inside the <div class="jasper-comparison"> block
    lines = rendered.lines
    div_start = lines.index { |l| l.includes?("<div class=\"jasper-comparison\"") }.should_not be_nil
    div_end = lines.rindex { |l| l.includes?("</div>") }.should_not be_nil
    (div_start..div_end).each do |idx|
      after_hash = lines[idx].sub(/^\s*#\s?/, "")
      after_hash.empty?.should be_false
    end
  end

  it "supports programmatic DSL comparison blocks and validates column counts" do
    with_temp_dir do |dir|
      src_dir = dir.join("docs_src/01_guides")
      FileUtils.mkdir_p(src_dir)
      bad_yml = src_dir.join("01_bad.yml")
      File.write(bad_yml, <<-YAML)
      id: BAD_CMP
      title: "Bad"
      summary: "Summary."
      sections:
        - id: s1
          title: "Only One Column"
          summary: "Invalid."
          comparisons:
            - columns:
                - label: "Only One"
                  code: "x = 1"
      YAML

      res = Jasper::Validator.validate_dir(dir.join("docs_src"))
      res.valid?.should be_false
      res.errors.any?(&.includes?("at least 2 columns")).should be_true

      css_dir = dir.join("docs/css")
      FileUtils.mkdir_p(css_dir)
      File.write(css_dir.join("style.css"), "body { color: #333; }\n")

      Jasper::CssPatcher.patch(dir.join("docs")).should be_true
      File.read(css_dir.join("style.css")).should contain("/* jasper:comparisons */")
      # Idempotent on second call
      Jasper::CssPatcher.patch(dir.join("docs")).should be_false
    end
  end
end
