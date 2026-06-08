# src/native/cli/build.cr

require "./apk"

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
      Usage: native.cr build [OPTIONS] [PLATFORM] [ENTRY_FILE]

      Build native.cr app for Android.

      Options:
        -e, --entry FILE     Entry point file [default: src/main.cr]
        -o, --output DIR     Output directory [default: ./build]
        --release            Build in release mode (optimized, smaller binary)
        --clean              Clean build directory before building
        -h, --help           Show this help

      Examples:
        native.cr build android
        native.cr build android --release
        native.cr build android --clean
      HELP
    end

    def run
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

      build_android
    end

    private def build_android
      ndk = ENV["ANDROID_NDK"]?
      unless ndk && Dir.exists?(ndk)
        puts "[native.cr] Error: ANDROID_NDK environment variable not set"
        puts "[native.cr] Install Android NDK and set ANDROID_NDK to its path"
        exit(1)
      end

      android_project = find_android_project
      unless android_project
        puts "[native.cr] Error: Android project not found"
        puts ""
        puts "To fix this:"
        puts "  1. Run 'native.cr create my_app --android' to create a project"
        puts "  2. Then run 'native.cr build android' again"
        exit(1)
      end

      lib_dir = "lib/native"
      engine_so = "#{lib_dir}/libnative_cr_engine.so"
      crystal_so = "#{lib_dir}/libnative_cr.so"

      unless File.exists?(engine_so) && File.exists?(crystal_so)
        puts "[native.cr] Error: Prebuilt Android libraries not found"
        puts ""
        puts "To fix this:"
        puts "  1. Run 'shards install' to download prebuilt libraries"
        puts "  2. Then run 'native.cr build android' again"
        exit(1)
      end

      puts "[native.cr] Found prebuilt libraries in #{lib_dir}/"
      puts "[native.cr] Using NDK at: #{ndk}"
      puts "[native.cr] Android project: #{android_project}"

      toolchain = "#{ndk}/toolchains/llvm/prebuilt/linux-x86_64"
      clang = "#{toolchain}/bin/aarch64-linux-android24-clang"

      unless File.exists?(clang)
        puts "[native.cr] Error: NDK toolchain not found at #{toolchain}"
        exit(1)
      end

      lib_dir_out = "#{@output}/lib/arm64-v8a"
      Dir.mkdir_p(lib_dir_out)

      FileUtils.cp(engine_so, lib_dir_out)
      FileUtils.cp(crystal_so, lib_dir_out)

      puts "[native.cr] Compiling user code..."
      user_o = "#{@output}/user_code.o"
      cmd = "crystal build #{@entry_point} -D android --target aarch64-linux-android -c -o #{user_o}"
      cmd += " --release" if @release
      output = `#{cmd} 2>&1`

      unless $?.success?
        puts "[native.cr] Compilation failed:"
        puts output
        exit(1)
      end

      puts "[native.cr] Linking final library..."
      final_so = "#{@output}/lib/arm64-v8a/libuser_app.so"
      link_cmd = "#{clang} -shared -fPIC -o #{final_so} #{user_o} #{lib_dir_out}/libnative_cr_engine.so #{lib_dir_out}/libnative_cr.so"
      link_cmd += " -Oz" if @release

      link_output = `#{link_cmd} 2>&1`
      unless $?.success?
        puts "[native.cr] Linking failed:"
        puts link_output
        exit(1)
      end

      jni_dir = "#{android_project}/app/src/main/jniLibs/arm64-v8a"
      Dir.mkdir_p(jni_dir)

      FileUtils.cp(final_so, "#{jni_dir}/libuser_app.so")
      FileUtils.cp(engine_so, jni_dir)
      FileUtils.cp(crystal_so, jni_dir)

      puts "[native.cr] Copied libraries to #{jni_dir}"

      apk_path = Native::CLI::Apk.build(android_project, @release)

      if apk_path
        size = File.size(apk_path).to_f / (1024 * 1024)
        puts ""
        puts "[native.cr] Build complete!"
        puts "[native.cr] APK: #{apk_path} (%.2f MB)" % size
        puts ""
        puts "Install on device:"
        puts "  adb install #{apk_path}"
      else
        puts "[native.cr] APK build failed"
        exit(1)
      end
    end

    private def find_android_project : String?
      ["android", "../android", "./android"].each do |path|
        if Dir.exists?(path) && File.exists?("#{path}/app/build.gradle")
          return path
        end
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
