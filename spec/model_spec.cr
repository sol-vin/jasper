require "./spec_helper"

describe Jasper::DocDocument do
  it "parses YAML document structure correctly" do
    yaml = <<-YAML
    id: OVERVIEW
    title: System Architecture
    summary: Core guide to architecture.
    track: 01_getting_started
    overview: "Long overview text."
    related_sources:
      - "src/main.cr"
    sections:
      - id: topic_01_boundaries
        title: Boundaries
        summary: Layer separation.
        options:
          "--release": "Release build"
        examples:
          - "engine.run"
        pitfalls:
          - "Do not block thread"
        faqs:
          - q: "Is it fast?"
            a: "Yes"
    YAML

    doc = Jasper::DocDocument.from_yaml(yaml)
    doc.id.should eq("OVERVIEW")
    doc.title.should eq("System Architecture")
    doc.track.should eq("01_getting_started")
    doc.resolved_parent_module("MyShard::Docs").should eq("MyShard::Docs::A_GETTING_STARTED")
    doc.full_module_name("MyShard::Docs").should eq("MyShard::Docs::A_GETTING_STARTED::OVERVIEW")

    doc.sections.size.should eq(1)
    sec = doc.sections.first
    sec.id.should eq("topic_01_boundaries")
    sec.options.not_nil!["--release"].should eq("Release build")
    sec.examples.not_nil!.first.should eq("engine.run")
    sec.pitfalls.not_nil!.first.should eq("Do not block thread")
    sec.faqs.not_nil!.first["q"].should eq("Is it fast?")
  end
end
