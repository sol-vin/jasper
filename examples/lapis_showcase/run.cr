require "../../src/jasper"

puts "=== Jasper Lapis 5-Minute Showcase Guide Compiler ==="

manifest_dir = __DIR__
config = Jasper::Config.find(manifest_dir)
config.source_dir = File.join(manifest_dir, config.source_dir)
config.output_dir = File.join(manifest_dir, config.output_dir)
config.master_file = File.join(manifest_dir, config.master_file)

generator = Jasper::Generator.new(config)
if generator.run
  puts "✔ Successfully compiled showcase documentation for '#{config.namespace}' to #{config.master_file}!"
else
  puts "✖ Failed to compile documentation."
  exit 1
end
