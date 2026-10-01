require "./spec_helper"

describe Jasper::MarkdownConverter do
  it "converts markdown pipe tables to standard HTML tables" do
    markdown = <<-MD
    Some introductory text.

    | Option | Default | Description |
    | :--- | :--- | :--- |
    | --release | false | Optimizes output |
    | --verbose | false | Prints debug logs |

    Post table text.
    MD

    converted = Jasper::MarkdownConverter.to_doc_comments(markdown, indent_level: 0)
    converted.should contain("<table>")
    converted.should contain("<th>Option</th>")
    converted.should contain("<th>Default</th>")
    converted.should contain("<td>--release</td>")
    converted.should contain("<td>Optimizes output</td>")
    converted.should contain("</table>")
  end

  it "protects summary lines from intermediate dot truncation" do
    summary1 = Jasper::MarkdownConverter.format_summary_line("v1.2.3 Release", "A major release with new features.")
    summary1.should eq("# **v123 Release**: A major release with new features.")

    summary2 = Jasper::MarkdownConverter.format_summary_line("Standard Title", "No trailing dot in summary")
    summary2.should eq("# **Standard Title**: No trailing dot in summary.")
  end
end
