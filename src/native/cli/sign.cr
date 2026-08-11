# src/native/cli/sign.cr

module Native::CLI
  class SignCommand
    @keystore : String = ""
    @apk : String = ""
    @alias : String = "androiddebugkey"
    @storepass : String = "android"
    @keypass : String = "android"
    @output : String = ""

    def initialize(args : Array(String))
      parse(args)
    end

    def parse(args : Array(String))
      i = 0
      while i < args.size
        case args[i]
        when "-k", "--keystore"
          @keystore = args[i + 1] if i + 1 < args.size
          i += 2
        when "-a", "--alias"
          @alias = args[i + 1] if i + 1 < args.size
          i += 2
        when "-s", "--storepass"
          @storepass = args[i + 1] if i + 1 < args.size
          i += 2
        when "-p", "--keypass"
          @keypass = args[i + 1] if i + 1 < args.size
          i += 2
        when "-o", "--output"
          @output = args[i + 1] if i + 1 < args.size
          i += 2
        when "-h", "--help"
          show_help
          exit(0)
        else
          # Assume it's the APK path
          @apk = args[i] if @apk.empty?
          i += 1
        end
      end

      if @apk.empty?
        puts "[native.cr] Error: APK path required"
        show_help
        exit(1)
      end

      if @output.empty?
        @output = @apk
      end
    end

    def show_help
      puts <<-HELP
      Usage: native.cr sign [OPTIONS] <APK_PATH>

      Sign an APK using apksigner (from Android SDK).

      Options:
        -k, --keystore PATH   Path to keystore file (required)
        -a, --alias ALIAS     Key alias [default: androiddebugkey]
        -s, --storepass PASS  Keystore password [default: android]
        -p, --keypass PASS    Key password [default: android]
        -o, --output PATH     Output path [default: overwrite original]
        -h, --help            Show this help

      Examples:
        native.cr sign -k debug.keystore app-debug.apk
        native.cr sign -k release.keystore -a myalias app-release.apk
        native.cr sign -k release.keystore app-release.apk -o app-signed.apk
      HELP
    end

    def run
      puts "[native.cr] Signing APK: #{@apk}"
      puts "[native.cr] Keystore: #{@keystore}"
      puts "[native.cr] Alias: #{@alias}"
      puts ""

      unless File.exists?(@keystore)
        puts "[native.cr] Error: Keystore file not found: #{@keystore}"
        exit(1)
      end

      unless File.exists?(@apk)
        puts "[native.cr] Error: APK file not found: #{@apk}"
        exit(1)
      end

      sign_apk
    end

    private def sign_apk
      # Locate apksigner from Android SDK
      apksigner_path = find_apksigner

      unless apksigner_path
        puts "[native.cr] Error: apksigner not found in Android SDK"
        puts "[native.cr] Make sure ANDROID_HOME or ANDROID_SDK_ROOT is set"
        exit(1)
      end

      cmd = [
        apksigner_path,
        "sign",
        "--ks", @keystore,
        "--ks-key-alias", @alias,
        "--ks-pass", "pass:#{@storepass}",
        "--key-pass", "pass:#{@keypass}",
        "--out", @output,
        @apk,
      ]

      puts "[native.cr] Running: #{cmd.join(" ")}"
      puts ""

      output = `#{cmd.join(" ")} 2>&1`

      if $?.success?
        puts "[native.cr] APK signed successfully!"
        puts "[native.cr] Output: #{@output}"
      else
        puts "[native.cr] Signing failed:"
        puts output
        exit(1)
      end
    end

    private def find_apksigner : String?
      # Check common locations
      sdk_path = ENV["ANDROID_HOME"]? || ENV["ANDROID_SDK_ROOT"]?

      if sdk_path
        apksigner = "#{sdk_path}/build-tools/34.0.0/apksigner"
        return apksigner if File.exists?(apksigner)

        # Try to find the latest build-tools version
        build_tools_dir = "#{sdk_path}/build-tools"
        if Dir.exists?(build_tools_dir)
          versions = Dir.glob("#{build_tools_dir}/*").sort_by { |dir| File.basename(dir) }.reverse!
          versions.each do |version_dir|
            apksigner = "#{version_dir}/apksigner"
            return apksigner if File.exists?(apksigner)
          end
        end
      end

      # Check PATH as fallback
      if `which apksigner 2>/dev/null`.chomp != ""
        return "apksigner"
      end

      nil
    end
  end
end

# Add to the CLI entry point
if ARGV.size > 0 && ARGV[0] == "sign"
  args = ARGV[1..-1] || [] of String
  cmd = Native::CLI::SignCommand.new(args)
  cmd.run
end
