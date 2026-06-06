# src/native/cli/build.cr

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

      Build native.cr app for Android or iOS.

      Options:
        -e, --entry FILE     Entry point file [default: src/main.cr]
        -o, --output DIR     Output directory [default: ./build]
        --release            Build in release mode (optimized)
        --clean              Clean build directory before building
        -h, --help           Show this help

      Platforms:
        android              Build for Android (ARM64)
        ios                  Build for iOS (ARM64)

      Examples:
        native.cr build android
        native.cr build ios src/main.cr
        native.cr build android --release
      HELP
    end

    def run
      puts "[native.cr] Building for #{@platform}"
      puts "[native.cr] Entry point: #{@entry_point}"
      puts "[native.cr] Output: #{@output}"
      puts ""

      if @clean && Dir.exists?(@output)
        FileUtils.rm_rf(@output)
        puts "[native.cr] Cleaned output directory"
      end

      Dir.mkdir_p(@output)

      case @platform
      when "android"
        build_android
      when "ios"
        build_ios
      else
        puts "[native.cr] Error: Unknown platform '#{@platform}'"
        exit(1)
      end
    end

    private def build_android
      # Check for Android NDK
      ndk = ENV["ANDROID_NDK"]?
      unless ndk && Dir.exists?(ndk)
        puts "[native.cr] Error: ANDROID_NDK environment variable not set"
        puts "[native.cr] Install Android NDK and set ANDROID_NDK to its path"
        puts "[native.cr] Example: export ANDROID_NDK=/path/to/ndk"
        exit(1)
      end

      # Check for prebuilt libraries from postinstall
      lib_dir = "lib/native"
      engine_so = "#{lib_dir}/libnative_cr_engine.so"
      crystal_so = "#{lib_dir}/libnative_cr.so"

      unless File.exists?(engine_so) && File.exists?(crystal_so)
        puts "[native.cr] Error: Prebuilt Android libraries not found"
        puts "[native.cr] Run 'shards install' first to download them"
        exit(1)
      end

      puts "[native.cr] Found prebuilt libraries in #{lib_dir}/"
      puts "[native.cr] Using NDK at: #{ndk}"

      # Setup NDK toolchain
      toolchain = "#{ndk}/toolchains/llvm/prebuilt/linux-x86_64"
      clang = "#{toolchain}/bin/aarch64-linux-android24-clang"

      unless File.exists?(clang)
        puts "[native.cr] Error: NDK toolchain not found at #{toolchain}"
        exit(1)
      end

      # Create output directories
      lib_dir_out = "#{@output}/lib/arm64-v8a"
      Dir.mkdir_p(lib_dir_out)

      # Copy prebuilt libraries to output
      FileUtils.cp(engine_so, lib_dir_out)
      FileUtils.cp(crystal_so, lib_dir_out)
      puts "[native.cr] Copied prebuilt libraries to #{lib_dir_out}"

      # Compile user's Crystal code to object file
      puts "[native.cr] Compiling user code..."
      user_o = "#{@output}/user_code.o"
      cmd = "crystal build #{@entry_point} -D android --target aarch64-linux-android -c -o #{user_o}"
      output = `#{cmd} 2>&1`

      unless $?.success?
        puts "[native.cr] Compilation failed:"
        puts output
        exit(1)
      end

      # Link user code with prebuilt libraries
      puts "[native.cr] Linking final library..."
      final_so = "#{@output}/lib/arm64-v8a/libuser_app.so"
      link_cmd = "#{clang} -shared -fPIC -o #{final_so} #{user_o} #{lib_dir_out}/libnative_cr_engine.so #{lib_dir_out}/libnative_cr.so"

      link_output = `#{link_cmd} 2>&1`
      unless $?.success?
        puts "[native.cr] Linking failed:"
        puts link_output
        exit(1)
      end

      # Copy to Android project if exists
      android_project = find_android_project
      if android_project
        jni_dir = "#{android_project}/app/src/main/jniLibs/arm64-v8a"
        Dir.mkdir_p(jni_dir)
        FileUtils.cp(final_so, "#{jni_dir}/libnative_cr.so")
        FileUtils.cp(engine_so, jni_dir)
        FileUtils.cp(crystal_so, jni_dir)
        puts "[native.cr] Copied libraries to Android project: #{jni_dir}"

        # Build APK with Gradle
        puts "[native.cr] Building APK with Gradle..."
        Dir.cd(android_project) do
          gradle_cmd = @release ? "./gradlew assembleRelease" : "./gradlew assembleDebug"
          system(gradle_cmd)
        end
        puts "[native.cr] APK created at #{android_project}/app/build/outputs/apk/"
      else
        puts ""
        puts "[native.cr] Android build complete"
        puts "[native.cr] Library: #{final_so}"
        puts ""
        puts "Next steps:"
        puts "  1. Copy #{@output}/lib/arm64-v8a/*.so to your Android project's jniLibs/arm64-v8a/"
        puts "  2. Build your APK with Android Studio or Gradle"
      end
    end

    private def build_ios
      framework_dir = "#{@output}/NativeCr.framework"
      Dir.mkdir_p(framework_dir)
      Dir.mkdir_p("#{framework_dir}/Headers")

      cmd = "crystal build #{@entry_point} -D ios --target aarch64-apple-ios"
      cmd += " --release" if @release
      cmd += " --link-flags=\"-static\""
      cmd += " -o #{framework_dir}/NativeCr"

      puts "[native.cr] Compiling Crystal for iOS..."
      output = `#{cmd} 2>&1`

      if $?.success?
        puts "[native.cr] Compilation successful"
      else
        puts "[native.cr] Compilation failed:"
        puts output
        exit(1)
      end

      create_ios_module_map(framework_dir)

      puts ""
      puts "[native.cr] iOS build complete"
      puts "[native.cr] Framework: #{framework_dir}"
      puts ""
      puts "Next steps:"
      puts "  1. Drag #{framework_dir} into your Xcode project"
      puts "  2. Build your IPA with Xcode"
    end

    private def find_android_project : String?
      ["android", "../android", "./android"].each do |path|
        if Dir.exists?(path) && File.exists?("#{path}/app/build.gradle")
          return path
        end
      end
      nil
    end

    private def create_ios_module_map(framework_dir : String)
      module_map = <<-MODULE
      framework module NativeCr {
        umbrella header "NativeCr.h"
        export *
        module * { export * }
      }
      MODULE

      File.write("#{framework_dir}/module.modulemap", module_map)
      
      header = <<-HEADER
      #import <Foundation/Foundation.h>
      extern void native_cr_main(void);
      HEADER
      
      File.write("#{framework_dir}/Headers/NativeCr.h", header)
    end
  end
end

if ARGV.size > 0 && ARGV[0] == "build"
  args = ARGV[1..-1] || [] of String
  cmd = Native::CLI::BuildCommand.new(args)
  cmd.run
end
