require "./spec_helper"

describe Jasper::Validator do
  it "passes on clean documentation directories" do
    with_temp_dir do |dir|
      track_dir = dir.join("01_guide")
      FileUtils.mkdir_p(track_dir)
      File.write(track_dir.join("01_test.yml"), <<-YAML
      id: TEST_DOC
      title: Test Document
      summary: Valid summary text.
      sections:
        - id: topic_01_sec
          title: Section Title
          summary: Valid section summary.
      YAML
      )

      res = Jasper::Validator.validate_dir(dir)
      res.valid?.should be_true
      res.errors.should be_empty
    end
  end

  it "detects blank IDs and duplicate IDs" do
    with_temp_dir do |dir|
      track_dir = dir.join("01_guide")
      FileUtils.mkdir_p(track_dir)
      File.write(track_dir.join("01_bad.yml"), <<-YAML
      id: ""
      title: Bad Doc
      summary: Missing ID.
      sections:
        - id: sec1
          title: Sec 1
          summary: Sum 1
      YAML
      )
      File.write(track_dir.join("02_dup.yml"), <<-YAML
      id: DUP
      title: Dup 1
      summary: Sum
      sections:
        - id: sec1
          title: Sec 1
          summary: Sum 1
      YAML
      )
      File.write(track_dir.join("03_dup.yml"), <<-YAML
      id: DUP
      title: Dup 2
      summary: Sum
      sections:
        - id: sec1
          title: Sec 1
          summary: Sum 1
      YAML
      )

      res = Jasper::Validator.validate_dir(dir)
      res.valid?.should be_false
      res.errors.any? { |e| e.includes?("Document 'id' cannot be blank") }.should be_true
      res.errors.any? { |e| e.includes?("Duplicate document id 'DUP'") }.should be_true
    end
  end
end
