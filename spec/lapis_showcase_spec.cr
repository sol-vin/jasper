require "./spec_helper"

describe "Lapis 5-Minute Showcase Guide" do
  it "validates and compiles the Lapis showcase guide cleanly" do
    showcase_dir = File.expand_path("../examples/lapis_showcase", __DIR__)
    config = Jasper::Config.find(showcase_dir)
    config.source_dir = File.join(showcase_dir, config.source_dir)

    with_temp_dir do |dir|
      config.output_dir = dir.join("src/docs").to_s
      config.master_file = dir.join("src/docs.cr").to_s

      # Validate YAML schema
      val_res = Jasper::Validator.validate_dir(config.source_dir)
      val_res.valid?.should be_true
      val_res.errors.should be_empty

      # Run generator
      generator = Jasper::Generator.new(config)
      generator.run.should be_true

      File.exists?(config.master_file).should be_true
      content = File.read(config.master_file)
      content.should contain("Lapis::Quickstart")
      content.should contain("A_GETTING_STARTED")
      content.should contain("B_ADVANCED_PATTERNS")
    end
  end
end
