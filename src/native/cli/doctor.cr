# src/native/cli/doctor.cr

require "semantic_version"
require "http/client"

module Native
  VERSION = "0.0.98"
end

module Native::CLI
  class DoctorCommand
    def initialize(args : Array(String))
    end

    def run
      puts "Native.cr Doctor"
      puts ""

      check_crystal
      check_android
      check_ios
      check_native_cr
      check_latest_version
    end

    private def check_crystal
      version = `crystal --version 2>/dev/null`.lines.first?.to_s.strip
      if version.empty?
        puts "[FAIL] Crystal not found"
      else
        puts "[OK] Crystal: #{version}"
      end
    end

    private def check_android
      sdk = ENV["ANDROID_HOME"]? || ENV["ANDROID_SDK_ROOT"]?
      if sdk.nil? || sdk.empty?
        puts "[FAIL] Android SDK not found (set ANDROID_HOME)"
        return
      end

      puts "[OK] Android SDK: #{sdk}"

      ndk_dir = Dir.glob("#{sdk}/ndk/*").first?
      if ndk_dir.nil?
        puts "[FAIL] Android NDK not found"
      else
        version = File.read("#{ndk_dir}/source.properties").lines.find(&.starts_with?("Pkg.Revision")).to_s.split("=").last?.to_s.strip
        puts "[OK] Android NDK: #{version}"
      end
    end

    private def check_ios
      xcode = `xcode-select -p 2>/dev/null`.to_s.strip
      if xcode.empty?
        puts "[FAIL] Xcode not found"
        return
      end

      puts "[OK] Xcode: #{xcode}"

      simulators = `xcrun simctl list devices available 2>/dev/null | grep -c "iPhone"`.to_s.strip
      puts "[OK] iOS simulators: #{simulators} available"
    end

    private def check_native_cr
      puts "[OK] Native.cr: #{Native::VERSION}"
    end

    private def check_latest_version
      puts ""
      puts "Checking for updates..."

      begin
        url = "https://api.github.com/repos/slick-lab/native.cr/releases/latest"
        response = HTTP::Client.get(url)

        if response.status_code == 200
          data = JSON.parse(response.body)
          latest_version = data["tag_name"].as_s
          current_version = Native::VERSION

          v_current = SemanticVersion.parse(current_version)
          v_latest = SemanticVersion.parse(latest_version)

          if v_current < v_latest
            puts "[WARN] New version available: #{latest_version}"
            puts "[WARN] Run 'shards update' to upgrade"
          elsif v_current == v_latest
            puts "[OK] Native.cr is up to date"
          else
            puts "[INFO] You are on a development version: #{current_version}"
          end
        else
          puts "[WARN] Could not check for updates (GitHub API returned #{response.status_code})"
        end
      rescue ex
        puts "[WARN] Failed to check for updates: #{ex.message}"
      end
    end
  end
end

if ARGV.size > 0 && ARGV[0] == "doctor"
  args = ARGV[1..-1] || [] of String
  cmd = Native::CLI::DoctorCommand.new(args)
  cmd.run
end
