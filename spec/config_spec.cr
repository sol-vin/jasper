require "./spec_helper"

describe Jasper::Config do
  it "initializes with default values" do
    config = Jasper::Config.new
    config.namespace.should eq("Docs")
    config.source_dir.should eq("docs_src")
    config.output_dir.should eq("src/docs")
    config.master_file.should eq("src/docs.cr")
    config.features.release_guard.should be_true
    config.features.naming_style.should eq("prefixed")
    config.features.table_auto_html.should be_true
    config.features.protect_summary.should be_true
    config.features.summary_table.should be_true
    config.features.master_index.should be_true
  end

  it "serializes and deserializes from YAML" do
    yaml = <<-YAML
    namespace: "MyShard::Docs"
    source_dir: "custom_docs"
    output_dir: "src/generated"
    master_file: "src/master.cr"
    features:
      release_guard: false
      naming_style: "natural"
      aliases:
        - "Docs"
        - "Guide"
    YAML

    config = Jasper::Config.from_yaml(yaml)
    config.namespace.should eq("MyShard::Docs")
    config.source_dir.should eq("custom_docs")
    config.features.release_guard.should be_false
    config.features.naming_style.should eq("natural")
    config.features.aliases.should eq(["Docs", "Guide"])
  end

  it "supports fluent builder helpers" do
    config = Jasper::Config.new
    config.add_alias("MyDocs").add_alias("Help")
    config.features.aliases.should eq(["MyDocs", "Help"])

    config.set_quick_start("Starter Commands", ["shards install", "make"])
    config.features.quick_start.not_nil!.title.should eq("Starter Commands")
    config.features.quick_start.not_nil!.commands.should eq(["shards install", "make"])
  end
end
