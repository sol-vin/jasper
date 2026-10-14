require "./spec_helper"

describe Jasper::Cookbook do
  describe "Tier 1: Core Engine (ShardPattern & Catalog)" do
    it "validates shard patterns and enforces the <= 60s watchdog law" do
      valid_pattern = Jasper::Cookbook::ShardPattern.new(
        shard_name: "crowbar",
        repository: "sol-vin/crowbar",
        doc_id: "CROWBAR_COOKBOOK",
        tier_one_engine: ["Crowbar::Core::CorpusRunner"],
        tier_two_dsl: ["Crowbar.corpus_gate"],
        hardening_gate: "Deterministic seed replay",
        watchdog_budget_seconds: 60
      )
      valid_pattern.valid?.should be_true

      invalid_watchdog = Jasper::Cookbook::ShardPattern.new(
        shard_name: "crowbar",
        repository: "sol-vin/crowbar",
        doc_id: "CROWBAR_COOKBOOK",
        tier_one_engine: ["Crowbar::Core::CorpusRunner"],
        tier_two_dsl: ["Crowbar.corpus_gate"],
        hardening_gate: "Deterministic seed replay",
        watchdog_budget_seconds: 120
      )
      invalid_watchdog.valid?.should be_false

      catalog = Jasper::Cookbook::Catalog.new
      catalog.register(valid_pattern)
      catalog.valid?.should be_true

      expect_raises(ArgumentError) do
        catalog.register(invalid_watchdog)
      end
    end
  end

  describe "Tier 2: Declarative Cookbook Builder & Multi-Shard Track" do
    it "builds the canonical multi-shard cookbook across carbon, crowbar, bakelite, and opal" do
      catalog = Jasper::Cookbook.canonical_catalog
      catalog.valid?.should be_true
      catalog.shard_names.should eq(["carbon", "crowbar", "bakelite", "opal"])

      carbon = catalog.find("carbon").not_nil!
      carbon.repository.should eq("sol-vin/carbon")
      carbon.tier_two_dsl.should contain("Carbon.ci")
      carbon.tier_two_dsl.should contain("Carbon.version!")

      crowbar = catalog.find("crowbar").not_nil!
      crowbar.tier_one_engine.should contain("Crowbar::Core::CorpusRunner")
      crowbar.tier_two_dsl.should contain("Crowbar.corpus_gate")

      bakelite = catalog.find("bakelite").not_nil!
      bakelite.tier_two_dsl.should contain("Bakelite.verify_archive")
      bakelite.tier_two_dsl.should contain("bake_manifest")

      opal = catalog.find("opal").not_nil!
      opal.tier_one_engine.should contain("Opal::UI::Buffer")
      opal.tier_two_dsl.should contain("Opal::UI.split_pane")

      md = catalog.to_markdown_table
      md.should contain("Two-Tier Crystal DSL & Hardening Cookbook")
      md.should contain("**carbon**")
      md.should contain("**crowbar**")
      md.should contain("**bakelite**")
      md.should contain("**opal**")
    end

    it "validates and compiles the 05_hardening_cookbook YAML track in docs_src/" do
      repo_docs_src = File.expand_path("../docs_src", __DIR__)
      val_res = Jasper::Validator.validate_dir(repo_docs_src)
      val_res.valid?.should be_true
      val_res.errors.should be_empty

      catalog = Jasper::Cookbook.canonical_catalog
      cookbook_docs = catalog.load_documents(repo_docs_src)
      cookbook_docs.size.should eq(5)
      doc_ids = cookbook_docs.map(&.id)
      doc_ids.should contain("COOKBOOK_OVERVIEW")
      doc_ids.should contain("CARBON_COOKBOOK")
      doc_ids.should contain("CROWBAR_COOKBOOK")
      doc_ids.should contain("BAKELITE_COOKBOOK")
      doc_ids.should contain("OPAL_COOKBOOK")

      with_temp_dir do |dir|
        out_dir = dir.join("src/docs")
        master_file = dir.join("src/docs.cr")

        config = Jasper::Config.new(
          namespace: "Docs",
          source_dir: repo_docs_src,
          output_dir: out_dir.to_s,
          master_file: master_file.to_s
        )

        Jasper::Generator.new(config).run.should be_true
        File.exists?(master_file).should be_true
        master_content = File.read(master_file)
        master_content.should contain("E_HARDENING_COOKBOOK")
        master_content.should contain("COOKBOOK_OVERVIEW")
        master_content.should contain("CARBON_COOKBOOK")
        master_content.should contain("CROWBAR_COOKBOOK")
        master_content.should contain("BAKELITE_COOKBOOK")
        master_content.should contain("OPAL_COOKBOOK")
      end
    end
  end
end
