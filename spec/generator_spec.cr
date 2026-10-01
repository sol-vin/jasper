require "./spec_helper"

describe Jasper::Generator do
  it "generates Crystal documentation files and master index" do
    with_temp_dir do |dir|
      src_dir = dir.join("docs_src/01_intro")
      out_dir = dir.join("src/my_app/docs")
      master_file = dir.join("src/my_app/docs.cr")

      FileUtils.mkdir_p(src_dir)
      File.write(src_dir.join("01_hello.yml"), <<-YAML
      id: HELLO
      title: Hello World
      summary: Introduction to Hello World.
      track: 01_intro
      overview: "General overview"
      sections:
        - id: topic_01_greeting
          title: Greeting Function
          summary: Explains how to greet.
          content: "Use the greet method."
      YAML
      )

      config = Jasper::Config.new(
        namespace: "MyApp::Docs",
        source_dir: dir.join("docs_src").to_s,
        output_dir: out_dir.to_s,
        master_file: master_file.to_s
      )
      config.add_alias("Docs")
      config.set_quick_start("Quick Test", ["shards install"])

      success = Jasper::Generator.new(config).run
      success.should be_true

      # Verify submodule file exists and has release guard
      submodule_file = out_dir.join("a_intro/hello.cr")
      File.exists?(submodule_file).should be_true
      content = File.read(submodule_file)
      content.should contain("{% unless flag?(:release) %}")
      content.should contain("module MyApp")
      content.should contain("module Docs")
      content.should contain("module A_INTRO")
      content.should contain("module HELLO")
      content.should contain("def self.topic_01_greeting : Nil; end")

      # Verify master docs file
      File.exists?(master_file).should be_true
      master_content = File.read(master_file)
      master_content.should contain("MyApp::Docs Documentation System")
      master_content.should contain("alias Docs = ::MyApp::Docs")
      master_content.should contain("require \"./docs/a_intro/hello\"")
      master_content.should contain("def self.topic_01_quick_start : Nil; end")
    end
  end
end
