require "./spec_helper"

describe "Jasper DSL" do
  before_each do
    Jasper.clear_programmatic_documents
  end

  it "allows defining tracks and documents programmatically" do
    track = Jasper.define_track("01_guide", title: "User Guide") do |t|
      t.document("intro", title: "Introduction", summary: "Introductory guide.") do |d|
        d.overview("This is the overview.")
        d.related_source("src/lib.cr")

        d.section("setup", title: "Initial Setup") do |s|
          s.summary("How to setup.")
          s.content("Run shards install to get started.")
          s.option("--dev", "Development mode")
          s.example("MyLib.init")
          s.pitfall("Do not skip setup")
          s.faq("Is this necessary?", "Yes")
        end
      end
    end

    track.documents.size.should eq(1)
    doc = track.documents.first
    doc.id.should eq("intro")
    doc.title.should eq("Introduction")
    doc.sections.size.should eq(1)

    sec = doc.sections.first
    sec.id.should eq("setup")
    sec.title.should eq("Initial Setup")
    sec.summary.should eq("How to setup.")
    sec.options.not_nil!["--dev"].should eq("Development mode")

    Jasper.programmatic_documents.size.should eq(1)
  end

  it "allows programmatic configuration via Jasper.configure" do
    Jasper.configure do |c|
      c.namespace = "App::Docs"
      c.features.release_guard = false
    end

    Jasper.config.namespace.should eq("App::Docs")
    Jasper.config.features.release_guard.should be_false
  end
end
