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
      HELP
    end

    def run
      puts "[native.cr] Building for #{@platform}"
      puts "[native.cr] Entry point: #{@entry_point}"
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
      lib_dir = "#{@output}/lib/arm64-v8a"
      Dir.mkdir_p(lib_dir)

      cmd = "crystal build #{@entry_point} -D android --target aarch64-linux-android"
      cmd += " --release" if @release
      cmd += " --link-flags=\"-shared\""
      cmd += " -o #{lib_dir}/libnative_cr.so"

      puts "[native.cr] Compiling Crystal to Android ARM64..."
      output = `#{cmd} 2>&1`

      if $?.success?
        puts "[native.cr] Compilation successful"
      else
        puts "[native.cr] Compilation failed:"
        puts output
        exit(1)
      end

      puts ""
      puts "[native.cr] Android build complete"
      puts "[native.cr] Library: #{lib_dir}/libnative_cr.so"
      puts ""
      puts "Next steps:"
      puts "  1. Copy #{lib_dir}/libnative_cr.so to your Android project's jniLibs/arm64-v8a/"
      puts "  2. Build your APK with Android Studio or Gradle"
    end

    private def build_ios
      framework_dir = "#{@output}/NativeCr.framework"
      Dir.mkdir_p(framework_dir)
      Dir.mkdir_p("#{framework_dir}/Headers")

      cmd = "crystal build #{@entry_point} -D ios --target aarch64-apple-ios"
      cmd += " --release" if @release
      cmd += " --link-flags=\"-static\""
      cmd += " -o #{framework_dir}/NativeCr"

      puts "[native.cr] Compiling Crystal to iOS ARM64..."
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
