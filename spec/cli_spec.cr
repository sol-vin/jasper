require "./spec_helper"
require "../src/jasper/cli/app"

describe Jasper::CLI::App do
  it "returns version information" do
    code = Jasper::CLI::App.run(["version"])
    code.should eq(0)
  end

  it "runs init, validate, build, list, and clean in a project directory" do
    with_temp_dir do |dir|
      old_pwd = Dir.current
      Dir.cd(dir)
      begin
        # 1. Init
        code = Jasper::CLI::App.run(["init", "--namespace=Smoke::Docs"])
        code.should eq(0)
        File.exists?("jasper.yml").should be_true
        File.exists?("docs_src/01_getting_started/01_overview.yml").should be_true

        # 2. Validate
        code = Jasper::CLI::App.run(["validate"])
        code.should eq(0)

        # 3. List
        code = Jasper::CLI::App.run(["list"])
        code.should eq(0)

        # 4. Build
        code = Jasper::CLI::App.run(["build"])
        code.should eq(0)
        File.exists?("src/docs.cr").should be_true
        File.exists?("src/docs/a_getting_started/overview.cr").should be_true

        # 5. Clean
        code = Jasper::CLI::App.run(["clean"])
        code.should eq(0)
        File.exists?("src/docs.cr").should be_false
        Dir.exists?("src/docs").should be_false
      ensure
        Dir.cd(old_pwd)
      end
    end
  end
end
