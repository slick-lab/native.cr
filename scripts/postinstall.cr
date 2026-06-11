# scripts/postinstall.cr

require "http/client"
require "file_utils"
require "json"
require "crypto/subtle"

def get_os : String
  os = `uname -s`.chomp.downcase
  case os
  when "linux" then "linux"
  when "darwin" then "darwin"
  else "unknown"
  end
end

def get_arch : String
  arch = `uname -m`.chomp.downcase
  case arch
  when "x86_64", "amd64" then "x86_64"
  when "aarch64", "arm64" then "arm64"
  else "x86_64"
  end
end

def get_latest_version : String
  response = HTTP::Client.get("https://api.github.com/repos/slick-lab/native.cr/releases/latest")
  if response.status_code == 200
    data = JSON.parse(response.body)
    data["tag_name"].as_s
  else
    puts "[native.cr] Warning: Could not fetch latest version, using v0.1.0"
    "v0.1.0"
  end
rescue
  "v0.1.0"
end

def download_file(url : String, output_path : String) : Bool
  response = HTTP::Client.get(url)
  if response.status_code == 200
    File.write(output_path, response.body)
    true
  else
    false
  end
end

def add_to_path(dir : String) : Nil
  shell_config = nil

  # Detect which shell config file to use
  if File.exists?(File.join(ENV["HOME"], ".bashrc"))
    shell_config = File.join(ENV["HOME"], ".bashrc")
  elsif File.exists?(File.join(ENV["HOME"], ".bash_profile"))
    shell_config = File.join(ENV["HOME"], ".bash_profile")
  elsif File.exists?(File.join(ENV["HOME"], ".zshrc"))
    shell_config = File.join(ENV["HOME"], ".zshrc")
  end

  if shell_config
    path_line = "export PATH=\"$PATH:#{dir}\""
    current_content = File.read(shell_config)

    unless current_content.includes?(dir)
      File.open(shell_config, "a") do |file|
        file.puts ""
        file.puts "# Added by native.cr postinstall"
        file.puts path_line
      end
      puts "[native.cr] Added #{dir} to PATH in #{shell_config}"
      puts "[native.cr] Run 'source #{shell_config}' or restart your terminal"
    else
      puts "[native.cr] PATH already configured in #{shell_config}"
    end
  else
    puts "[native.cr] Could not detect shell config. Please add this to your shell config:"
    puts "[native.cr] export PATH=\"$PATH:#{dir}\""
  end
end

puts "[native.cr] Post-install setup"
puts "[native.cr] Detected OS: #{get_os}, Arch: #{get_arch}"
puts ""

version = get_latest_version
puts "[native.cr] Latest version: #{version}"

# Determine install directory
home = ENV["HOME"]
if Dir.exists?("/usr/local/bin") && File.writable?("/usr/local/bin")
  install_dir = "/usr/local/bin"
  use_sudo = false
elsif Dir.exists?(File.join(home, ".local/bin"))
  install_dir = File.join(home, ".local/bin")
  use_sudo = false
else
  install_dir = File.join(Dir.current, "bin")
  use_sudo = false
end

Dir.mkdir_p(install_dir)

# Download pre-built binary for CLI
os = get_os
arch = get_arch
binary_name = "native.cr-#{os}-#{arch}"
binary_url = "https://github.com/slick-lab/native.cr/releases/download/#{version}/#{binary_name}"
output_path = File.join(install_dir, "native.cr")

puts "[native.cr] Downloading CLI binary from: #{binary_url}"
puts "[native.cr] Installing to: #{output_path}"

if download_file(binary_url, output_path)
  File.chmod(output_path, 0o755)
  puts "[native.cr] CLI installed successfully"

  # Add to PATH if needed
  if install_dir == File.join(Dir.current, "bin")
    add_to_path(install_dir)
  elsif install_dir == "/usr/local/bin"
    puts "[native.cr] CLI installed to /usr/local/bin (already in PATH)"
  elsif install_dir == File.join(home, ".local/bin")
    puts "[native.cr] CLI installed to ~/.local/bin"
    add_to_path(install_dir)
  end
else
  puts "[native.cr] Failed to download pre-built binary. Falling back to building from source..."
  puts "[native.cr] Building CLI from source..."
  system("shards build --release")
  FileUtils.cp("bin/native.cr", output_path)
  File.chmod(output_path, 0o755)
  puts "[native.cr] CLI built and installed to #{output_path}"
  add_to_path(install_dir) if install_dir == File.join(Dir.current, "bin")
end


lib_dir = File.join(Dir.current, "lib", "native")
Dir.mkdir_p(lib_dir)

android_engine_url = "https://github.com/slick-lab/native.cr/releases/download/#{version}/libnative_cr_engine.so"
android_jar_url = "https://github.com/slick-lab/native.cr/releases/download/#{version}/libnative_cr_android.jar"
android_engine_path = File.join(lib_dir, "libnative_cr_engine.so")
android_jar_path = File.join(lib_dir, "libnative_cr_android.jar")

puts ""
puts "[native.cr] Downloading Android prebuilt libraries..."

if download_file(android_engine_url, android_engine_path)
  puts "[native.cr] Downloaded libnative_cr_engine.so"
else
  puts "[native.cr] Warning: Could not download libnative_cr_engine.so"
end

if download_file(android_jar_url, android_jar_path)
  puts "[native.cr] Downloaded libnative_cr_android.jar"
else
  puts "[native.cr] Warning: Could not download libnative_cr_android.jar"
end


if get_os == "darwin"
  ios_engine_url = "https://github.com/slick-lab/native.cr/releases/download/#{version}/libnative_cr_engine.a"
  ios_lib_url = "https://github.com/slick-lab/native.cr/releases/download/#{version}/libnative_cr_ios.a"
  ios_engine_path = File.join(lib_dir, "libnative_cr_engine.a")
  ios_lib_path = File.join(lib_dir, "libnative_cr_ios.a")

  puts ""
  puts "[native.cr] Downloading iOS prebuilt libraries..."

  if download_file(ios_engine_url, ios_engine_path)
    puts "[native.cr] Downloaded libnative_cr_engine.a"
  else
    puts "[native.cr] Warning: Could not download libnative_cr_engine.a"
  end

  if download_file(ios_lib_url, ios_lib_path)
    puts "[native.cr] Downloaded libnative_cr_ios.a"
  else
    puts "[native.cr] Warning: Could not download libnative_cr_ios.a"
  end
end


desktop_lib_url = "https://github.com/slick-lab/native.cr/releases/download/#{version}/libnative_cr_desktop.so"
desktop_lib_path = File.join(lib_dir, "libnative_cr_desktop.so")

puts ""
puts "[native.cr] Downloading desktop preview library..."

if download_file(desktop_lib_url, desktop_lib_path)
  puts "[native.cr] Downloaded libnative_cr_desktop.so"
else
  puts "[native.cr] Warning: Could not download libnative_cr_desktop.so"
end

puts ""
puts "[native.cr] Post-install complete!"
puts ""


if system("which native.cr > /dev/null 2>&1")
  puts "[native.cr] ✓ native.cr is available in your PATH"
  puts "[native.cr] Run 'native.cr doctor' to verify your setup"
else
  puts "[native.cr] ⚠ native.cr installed but not in PATH"
  puts "[native.cr] Run this command to add it: export PATH=\"$PATH:#{install_dir}\""
end