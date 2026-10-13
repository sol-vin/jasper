require "./spec_helper"

describe Jasper::MultiShardIndexer do
  it "indexes multi-shard documentation projects and compiles organization index" do
    # Use repo root as sample shard
    root_dir = File.expand_path("..", __DIR__)

    indexer = Jasper::MultiShardIndexer.new([root_dir], title: "Test Org Docs")
    org_index = indexer.build_index

    org_index.title.should eq("Test Org Docs")
    org_index.total_shards.should eq(1)
    org_index.shards.first.name.should eq("jasper")
    org_index.shards.first.version.should eq("0.1.0")

    summary = org_index.to_markdown_summary
    summary.should contain("# Test Org Docs")
    summary.should contain("jasper")
  end

  it "supports the declarative Jasper.index_shards DSL" do
    root_dir = File.expand_path("..", __DIR__)

    org_index = Jasper.index_shards([root_dir]) do |idx|
      idx.title = "Custom Org"
    end

    org_index.title.should eq("Custom Org")
    org_index.total_shards.should eq(1)
  end
end
