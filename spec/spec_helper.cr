require "spec"
require "file_utils"
require "../src/jasper"

def with_temp_dir(&block : Path -> Nil)
  dir = Path.new(Dir.tempdir, "jasper_test_#{Time.utc.to_unix_ms}_#{rand(1000..9999)}")
  FileUtils.mkdir_p(dir)
  begin
    block.call(dir)
  ensure
    FileUtils.rm_rf(dir) if Dir.exists?(dir)
  end
end
