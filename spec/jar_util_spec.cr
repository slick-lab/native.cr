# spec/jar_util_spec.cr
#
# Guards against the silent-corrupt-download class of bug fixed in the
# gradle-wrapper download: anything accepted as a jar must actually be
# a zip archive, never an HTML error page or a truncated transfer.

require "./spec_helper"

# Helper kept at file top level - defs cannot be declared inside a
# describe block on the crystal version used in CI.
private def write_temp(content : String | Bytes) : String
  path = File.tempname("jarutil", ".bin")
  File.write(path, content)
  path
end

describe Native::CLI::JarUtil do
  it "accepts a file that starts with the zip magic bytes" do
    path = write_temp(Bytes[0x50, 0x4B, 0x03, 0x04, 0x00, 0x14, 0x08, 0x00])
    begin
      Native::CLI::JarUtil.valid_jar?(path).should be_true
    ensure
      File.delete(path)
    end
  end

  it "accepts a file that is exactly the four magic bytes" do
    path = write_temp(Bytes[0x50, 0x4B, 0x03, 0x04])
    begin
      Native::CLI::JarUtil.valid_jar?(path).should be_true
    ensure
      File.delete(path)
    end
  end

  it "rejects an HTML error page, like a GitHub 404 response" do
    path = write_temp("<html>\n<head><title>Not Found</title></head>\n<body>404</body>\n</html>")
    begin
      Native::CLI::JarUtil.valid_jar?(path).should be_false
    ensure
      File.delete(path)
    end
  end

  it "rejects a truncated transfer that only kept part of the magic bytes" do
    path = write_temp(Bytes[0x50, 0x4B, 0x03])
    begin
      Native::CLI::JarUtil.valid_jar?(path).should be_false
    ensure
      File.delete(path)
    end
  end

  it "rejects a file with the wrong magic bytes" do
    path = write_temp(Bytes[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
    begin
      Native::CLI::JarUtil.valid_jar?(path).should be_false
    ensure
      File.delete(path)
    end
  end

  it "rejects an empty file" do
    path = write_temp("")
    begin
      Native::CLI::JarUtil.valid_jar?(path).should be_false
    ensure
      File.delete(path)
    end
  end

  it "rejects a plain text file" do
    path = write_temp("hello world")
    begin
      Native::CLI::JarUtil.valid_jar?(path).should be_false
    ensure
      File.delete(path)
    end
  end

  it "rejects a path that does not exist instead of raising" do
    missing = File.tempname("jarutil", ".missing")
    Native::CLI::JarUtil.valid_jar?(missing).should be_false
  end
end
