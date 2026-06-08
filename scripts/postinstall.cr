# scripts/postinstall.cr

require "http/client"
require "file_utils"
require "json"

puts "[native.cr] Post-install setup"

os = `uname -s`.chomp
lib_dir = "lib/native"
bin_dir = "bin"
home = ENV["HOME"]
local_bin = "#{home}/.local/bin"

FileUtils.mkdir_p(lib_dir)
FileUtils.mkdir_p(bin_dir)
FileUtils.mkdir_p(local_bin)

# Get latest version from GitHub
begin
  response = HTTP::Client.get("https://api.github.com/repos/slick-lab/native.cr/releases/latest")
  if response.status_code == 200
    data = JSON.parse(response.body)
    version = data["tag_name"].as_s
  else
    puts "[native.cr] Warning: Could not fetch latest version, using v0.0.98"
    version = "v0.0.98"
  end
rescue
  puts "[native.cr] Warning: Network error, using v0.0.98"
  version = "v0.0.98"
end

puts "[native.cr] Latest version: #{version}"

# Download prebuilt Android libraries only on non-macOS
if os != "Darwin"
  puts "[native.cr] Downloading prebuilt Android libraries..."

  begin
    response = HTTP::Client.get("https://github.com/slick-lab/native.cr/releases/download/#{version}/libnative_cr.so")
    if response.status_code == 200
      File.write("#{lib_dir}/libnative_cr.so", response.body)
    else
      puts "[native.cr] Error: Could not download libnative_cr.so (HTTP #{response.status_code})"
    end
  rescue ex
    puts "[native.cr] Error downloading libnative_cr.so: #{ex.message}"
  end

  begin
    response = HTTP::Client.get("https://github.com/slick-lab/native.cr/releases/download/#{version}/libnative_cr_engine.so")
    if response.status_code == 200
      File.write("#{lib_dir}/libnative_cr_engine.so", response.body)
    else
      puts "[native.cr] Error: Could not download libnative_cr_engine.so (HTTP #{response.status_code})"
    end
  rescue ex
    puts "[native.cr] Error downloading libnative_cr_engine.so: #{ex.message}"
  end

  if File.exists?("#{lib_dir}/libnative_cr.so") && File.exists?("#{lib_dir}/libnative_cr_engine.so")
    puts "[native.cr] Android libraries saved to #{lib_dir}/"
  else
    puts "[native.cr] Warning: Android libraries may be missing"
  end
else
  puts "[native.cr] macOS detected - skipping Android library download"
end

# Build CLI
puts "[native.cr] Building CLI..."
if system("crystal build src/native.cr -o #{bin_dir}/native.cr --release")
  puts "[native.cr] CLI built successfully"
else
  puts "[native.cr] Error: Failed to build CLI"
  exit 1
end

# Install CLI to user directory
FileUtils.cp("#{bin_dir}/native.cr", local_bin)

# Add to PATH if not already there
bashrc = "#{home}/.bashrc"
if File.exists?(bashrc)
  path_line = "export PATH=\"$PATH:#{local_bin}\""
  unless File.read(bashrc).includes?(path_line)
    File.open(bashrc, "a") do |file|
      file.puts ""
      file.puts "# Added by native.cr postinstall"
      file.puts path_line
    end
    puts "[native.cr] Added ~/.local/bin to PATH in ~/.bashrc"
  end
end

zshrc = "#{home}/.zshrc"
if File.exists?(zshrc)
  path_line = "export PATH=\"$PATH:#{local_bin}\""
  unless File.read(zshrc).includes?(path_line)
    File.open(zshrc, "a") do |file|
      file.puts ""
      file.puts "# Added by native.cr postinstall"
      file.puts path_line
    end
    puts "[native.cr] Added ~/.local/bin to PATH in ~/.zshrc"
  end
end

puts "[native.cr] Post-install complete"
puts "[native.cr] Run 'native.cr doctor' to verify setup"
