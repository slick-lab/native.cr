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
      puts "[native.cr] Building Android..."

      # Create output directories
      lib_dir = "#{@output}/lib/arm64-v8a"
      Dir.mkdir_p(lib_dir)

      # Find Android project
      android_project = find_android_project
      if android_project.nil?
        puts "[native.cr] Error: Android project not found"
        puts "[native.cr] Run 'native.cr create --android' first"
        exit(1)
      end

      # Compile Crystal to shared library
      cmd = "crystal build #{@entry_point} -D android --target aarch64-linux-android"
      cmd += " --release" if @release
      cmd += " --link-flags=\"-shared\""
      cmd += " -o #{lib_dir}/libnative_cr.so"

      puts "[native.cr] Compiling Crystal..."
      output = `#{cmd} 2>&1`

      if $?.success?
        puts "[native.cr] Crystal compilation successful"
      else
        puts "[native.cr] Compilation failed:"
        puts output
        exit(1)
      end

      # Copy library to Android project
      jni_dir = "#{android_project}/app/src/main/jniLibs/arm64-v8a"
      Dir.mkdir_p(jni_dir)
      FileUtils.cp("#{lib_dir}/libnative_cr.so", "#{jni_dir}/libnative_cr.so")
      puts "[native.cr] Copied library to Android project"

      # Run Gradle build
      puts "[native.cr] Building APK with Gradle..."
      gradle_cmd = "./gradlew assembleRelease"
      if !@release
        gradle_cmd = "./gradlew assembleDebug"
      end

      Dir.cd(android_project) do
        output = `#{gradle_cmd} 2>&1`
        if $?.success?
          puts "[native.cr] APK build successful"
        else
          puts "[native.cr] Gradle build failed:"
          puts output
          exit(1)
        end
      end

      # Find and copy APK
      apk_dir = if @release
                  "#{android_project}/app/build/outputs/apk/release"
                else
                  "#{android_project}/app/build/outputs/apk/debug"
                end

      apk_files = Dir.glob("#{apk_dir}/*.apk")
      if apk_files.any?
        FileUtils.cp(apk_files.first, "#{@output}/app.apk")
        puts "[native.cr] APK copied to #{@output}/app.apk"
      end

      puts ""
      puts "[native.cr] Android build complete"
      puts "[native.cr] APK: #{@output}/app.apk"
    end

    private def build_ios
      puts "[native.cr] Building iOS..."

      framework_dir = "#{@output}/NativeCr.framework"
      Dir.mkdir_p(framework_dir)
      Dir.mkdir_p("#{framework_dir}/Headers")

      # Compile Crystal to static library
      cmd = "crystal build #{@entry_point} -D ios --target aarch64-apple-ios"
      cmd += " --release" if @release
      cmd += " --link-flags=\"-static\""
      cmd += " -o #{framework_dir}/NativeCr"

      puts "[native.cr] Compiling Crystal..."
      output = `#{cmd} 2>&1`

      if $?.success?
        puts "[native.cr] Crystal compilation successful"
      else
        puts "[native.cr] Compilation failed:"
        puts output
        exit(1)
      end

      # Create module map
      module_map = <<-MODULE
      framework module NativeCr {
        umbrella header "NativeCr.h"
        export *
        module * { export * }
      }
      MODULE
      File.write("#{framework_dir}/module.modulemap", module_map)

      # Create header
      header = <<-HEADER
      #import <Foundation/Foundation.h>
      extern void native_cr_main(void);
      HEADER
      File.write("#{framework_dir}/Headers/NativeCr.h", header)

      puts ""
      puts "[native.cr] iOS build complete"
      puts "[native.cr] Framework: #{framework_dir}"
      puts "[native.cr] Add this framework to your Xcode project"
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
