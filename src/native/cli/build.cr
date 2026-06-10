# src/native/cli/build.cr

require "./apk"
require "./ipa"

module Native::CLI
  class BuildCommand
    @entry_point : String = "src/main.cr"
    @platform : String = "android"
    @output : String = "./build"
    @release : Bool = false
    @clean : Bool = false

    def initialize(args : Array(String))
      parse_args(args)
    end

    def parse_args(args : Array(String))
      i = 0
      while i < args.size
        case args[i]
        when "-e", "--entry"
          @entry_point = args[i + 1] if i + 1 < args.size
          i += 2
        when "-o", "--output"
          @output = args[i + 1] if i + 1 < args.size
          i += 2
        when "--release"
          @release = true
          i += 1
        when "--clean"
          @clean = true
          i += 1
        when "android", "ios"
          @platform = args[i]
          i += 1
        when "-h", "--help"
          show_help
          exit(0)
        else
          if File.exists?(args[i])
            @entry_point = args[i]
          end
          i += 1
        end
      end
    end

    def show_help
      puts <<-HELP
      Usage: native.cr build [OPTIONS] [PLATFORM]

      Build native.cr app for Android or iOS.

      Options:
        -e, --entry FILE     Entry point file [default: src/main.cr]
        -o, --output DIR     Output directory [default: ./build]
        --release            Build in release mode (optimized)
        --clean              Clean build directory before building
        -h, --help           Show this help

      Platforms:
        android              Build APK for Android
        ios                  Build IPA for iOS (requires Mac and Xcode)

      Examples:
        native.cr build android
        native.cr build android --release
        native.cr build ios
      HELP
    end

    def run
      if @platform == "ios"
        if !System.platform?("darwin")
          puts "[native.cr] Error: iOS builds can only be performed on macOS."
          puts "[native.cr] To build for iOS, you need a Mac with Xcode installed."
          exit(1)
        end
        build_ios
      else
        build_android
      end
    end

    private def build_android
      puts "[native.cr] Building for Android"
      puts "[native.cr] Entry point: #{@entry_point}"
      puts "[native.cr] Output: #{@output}"
      puts "[native.cr] Release mode: #{@release ? "yes" : "no"}"
      puts ""

      if @clean && Dir.exists?(@output)
        FileUtils.rm_rf(@output)
        puts "[native.cr] Cleaned output directory"
      end

      Dir.mkdir_p(@output)

      ndk = ENV["ANDROID_NDK"]?
      unless ndk && Dir.exists?(ndk)
        puts "[native.cr] Error: ANDROID_NDK not set"
        puts "[native.cr] Install Android NDK and set ANDROID_NDK environment variable"
        exit(1)
      end

      android_project = find_android_project
      unless android_project
        puts "[native.cr] Error: Android project not found."
        puts "[native.cr] Run 'native.cr create my_app --android' first."
        exit(1)
      end

      lib_dir = "lib/native"

      unless File.exists?("#{lib_dir}/libnative_cr_engine.so")
        puts "[native.cr] Error: Prebuilt engine library not found."
        puts "[native.cr] Run 'shards install' first to download libnative_cr_engine.so"
        exit(1)
      end

      unless File.exists?("#{lib_dir}/libnative_cr_android.jar")
        puts "[native.cr] Error: Prebuilt Java library not found."
        puts "[native.cr] Run 'shards install' first to download libnative_cr_android.jar"
        exit(1)
      end

      toolchain = "#{ndk}/toolchains/llvm/prebuilt/linux-x86_64"
      clang = "#{toolchain}/bin/aarch64-linux-android24-clang"

      unless File.exists?(clang)
        puts "[native.cr] Error: NDK toolchain not found at #{toolchain}"
        exit(1)
      end

      lib_dir_out = "#{@output}/lib/arm64-v8a"
      Dir.mkdir_p(lib_dir_out)

      FileUtils.cp("#{lib_dir}/libnative_cr_engine.so", lib_dir_out)

      puts "[native.cr] Compiling user code with framework..."
      user_o = "#{@output}/user_code.o"
      cmd = "crystal build #{@entry_point} -D android --target aarch64-linux-android --cross-compile -o #{user_o}"
      cmd += " --release" if @release
      output = `#{cmd} 2>&1`

      unless $?.success?
        puts "[native.cr] Compilation failed:"
        puts output
        exit(1)
      end

      puts "[native.cr] Linking final library..."
      final_so = "#{@output}/lib/arm64-v8a/libuser_app.so"
      link_cmd = "#{clang} -shared -fPIC -o #{final_so} #{user_o} #{lib_dir_out}/libnative_cr_engine.so"
      link_output = `#{link_cmd} 2>&1`

      unless $?.success?
        puts "[native.cr] Linking failed:"
        puts link_output
        exit(1)
      end

      jni_dir = "#{android_project}/app/src/main/jniLibs/arm64-v8a"
      libs_dir = "#{android_project}/app/libs"
      Dir.mkdir_p(jni_dir)
      Dir.mkdir_p(libs_dir)

      FileUtils.cp(final_so, "#{jni_dir}/libuser_app.so")
      FileUtils.cp("#{lib_dir_out}/libnative_cr_engine.so", jni_dir)
      FileUtils.cp("#{lib_dir}/libnative_cr_android.jar", libs_dir)

      apk_path = Native::CLI::Apk.build(android_project, @release)

      if apk_path
        puts "\n[native.cr] Build complete! APK: #{apk_path}"
      else
        puts "[native.cr] APK build failed"
        exit(1)
      end
    end

    private def build_ios
      puts "[native.cr] Building for iOS"
      puts "[native.cr] Entry point: #{@entry_point}"
      puts "[native.cr] Output: #{@output}"
      puts "[native.cr] Release mode: #{@release ? "yes" : "no"}"
      puts ""

      if @clean && Dir.exists?(@output)
        FileUtils.rm_rf(@output)
        puts "[native.cr] Cleaned output directory"
      end

      Dir.mkdir_p(@output)

      ios_project = find_ios_project
      unless ios_project
        puts "[native.cr] Error: iOS project not found."
        puts "[native.cr] Run 'native.cr create my_app --ios' first."
        exit(1)
      end

      lib_dir = "lib/native"

      unless File.exists?("#{lib_dir}/libnative_cr_engine.a")
        puts "[native.cr] Error: Prebuilt engine library not found."
        puts "[native.cr] Run 'shards install' first to download libnative_cr_engine.a"
        exit(1)
      end

      frameworks_dir = "#{ios_project}/Frameworks"
      Dir.mkdir_p(frameworks_dir)
      FileUtils.cp("#{lib_dir}/libnative_cr_engine.a", frameworks_dir)

      puts "[native.cr] Compiling user code with framework..."
      user_o = "#{@output}/user_code.o"
      cmd = "crystal build #{@entry_point} -D ios --target aarch64-apple-darwin --cross-compile -o #{user_o}"
      cmd += " --release" if @release
      output = `#{cmd} 2>&1`

      unless $?.success?
        puts "[native.cr] Compilation failed:"
        puts output
        exit(1)
      end

      puts "[native.cr] Creating static library..."
      final_a = "#{@output}/libuser_app.a"
      `ar rcs #{final_a} #{user_o}`

      FileUtils.cp(final_a, frameworks_dir)

      ipa_path = Native::CLI::Ipa.build(ios_project, @release)

      if ipa_path
        puts "\n[native.cr] Build complete! IPA: #{ipa_path}"
      else
        puts "[native.cr] IPA build failed"
        exit(1)
      end
    end

    private def find_android_project : String?
      ["android", "../android", "./android"].each do |path|
        return path if Dir.exists?(path) && File.exists?("#{path}/app/build.gradle")
      end
      nil
    end

    private def find_ios_project : String?
      ["ios", "../ios", "./ios"].each do |path|
        return path if Dir.exists?(path) && Dir.glob("#{path}/*.xcodeproj").any?
      end
      nil
    end
  end
end

if ARGV.size > 0 && ARGV[0] == "build"
  args = ARGV[1..-1] || [] of String
  cmd = Native::CLI::BuildCommand.new(args)
  cmd.run
end
