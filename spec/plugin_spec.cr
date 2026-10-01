require "./spec_helper"

class TestMermaidPlugin < Jasper::Plugin
  def setup(pipeline : Jasper::Pipeline) : Nil
    pipeline.register_section_handler("mermaid") do |io, data, pad|
      io.puts "#{pad}# ```mermaid"
      io.puts "#{pad}# #{data.as_s}"
      io.puts "#{pad}# ```"
    end

    pipeline.register_markdown_filter do |md|
      md.gsub(/\[ALERT\]/, "**ALERT:**")
    end
  end
end

describe "Jasper Plugins & Pipeline" do
  it "executes registered custom section handlers" do
    pipeline = Jasper::Pipeline.new
    plugin = TestMermaidPlugin.new
    plugin.setup(pipeline)

    pipeline.section_handlers.has_key?("mermaid").should be_true

    io = IO::Memory.new
    pipeline.section_handlers["mermaid"].call(io, YAML::Any.new("graph TD; A-->B;"), "  ")
    io.to_s.should contain("graph TD; A-->B;")
  end

  it "applies markdown filters in pipeline" do
    pipeline = Jasper::Pipeline.new
    plugin = TestMermaidPlugin.new
    plugin.setup(pipeline)

    output = pipeline.apply_markdown_filters("Be careful [ALERT] watch out!")
    output.should eq("Be careful **ALERT:** watch out!")
  end
end
