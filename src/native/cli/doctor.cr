# src/native/cli/doctor.cr

module Native::CLI
  class DoctorCommand
    def initialize(args : Array(String))
      @online = args.includes?("--online")
    end

    def run
      puts "Native.cr Doctor"
      puts ""

      check_crystal
      check_android
      check_ios
      check_native_cr

      if @online
        check_latest_version
      else
        puts ""
        puts "Run with --online to check for latest version"
      end
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
        response = `curl -s --connect-timeout 5 https://api.github.com/repos/slick-lab/native.cr/releases/latest 2>/dev/null`

        if response.empty?
          puts "[WARN] Cannot check latest version (offline or GitHub unreachable)"
          return
        end

        match = response.match(/"tag_name"\s*:\s*"([^"]+)"/)
        if match
          latest = match[1]
          current = Native::VERSION

          if latest == current
            puts "[OK] You are on the latest version: #{current}"
          else
            puts "[INFO] Latest version: #{latest} (you have #{current})"
            puts "[INFO] Run: native.cr update"
          end
        else
          puts "[WARN] Could not parse latest version"
        end
      rescue
        puts "[WARN] Cannot check latest version (network error)"
      end
    end
  end
end

if ARGV.size > 0 && ARGV[0] == "doctor"
  args = ARGV[1..-1] || [] of String
  cmd = Native::CLI::DoctorCommand.new(args)
  cmd.run
end
