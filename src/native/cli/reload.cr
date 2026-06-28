# src/native/cli/reload.cr

require "../core/process"

module Native::CLI
  class ReloadCommand
    INTERPRETER_BIN    = ".build/native_cr_interpreter"
    INTERPRETER_SRC    = "src/native_interpreter_main.cr"
    IMGUI_BUILD_SCRIPT = "src/native/interpreter/imgui/build.sh"
    IMGUI_LIB          = "vendor/imgui/lib/libimgui_native.a"

    @entry_point : String = "src/main.cr"
    @use_interpreter : Bool = true

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
        when "--compile", "--no-interpreter"
          @use_interpreter = false
          i += 1
        else
          @entry_point = args[i] if !args[i].starts_with?('-') && i == 0
          i += 1
        end
      end
    end

    def run
      if !File.exists?(@entry_point)
        puts "Error: Entry point not found: #{@entry_point}"
        return
      end

      if @use_interpreter
        run_interpreter
      else
        run_compiler_based
      end
    end

    private def run_interpreter
      puts "[native.cr] Starting interpreter-based hot reload"
      puts "[native.cr] No compilation needed — instant reload on save"
      puts ""

      ensure_imgui_built
      ensure_interpreter_built

      ::Process.exec(INTERPRETER_BIN, args: [@entry_point])
    end

    private def ensure_imgui_built
      return if File.exists?(IMGUI_LIB)

      puts "[native.cr] Building Dear ImGui library (first time only)..."
      `chmod +x #{IMGUI_BUILD_SCRIPT}`
      ok = system("bash #{IMGUI_BUILD_SCRIPT}")
      unless ok
        puts "[native.cr] Warning: ImGui build failed. Falling back to compile mode."
        run_compiler_based
        exit
      end
      puts ""
    end

    private def ensure_interpreter_built
      return if File.exists?(INTERPRETER_BIN) && !interpreter_sources_newer?

      puts "[native.cr] Building interpreter (one-time setup)..."
      start = Time.monotonic

      Dir.mkdir_p(".build")
      ok = system(
        "crystal build #{INTERPRETER_SRC} -o #{INTERPRETER_BIN} " \
        "--error-trace 2>&1"
      )

      elapsed = (Time.monotonic - start).total_seconds
      if ok
        puts "[native.cr] Interpreter built in %.1fs" % elapsed
      else
        puts "[native.cr] Interpreter build failed. Falling back to compile mode."
        run_compiler_based
        exit
      end
      puts ""
    end

    private def interpreter_sources_newer? : Bool
      return false unless File.exists?(INTERPRETER_BIN)
      bin_time = File.info(INTERPRETER_BIN).modification_time
      paths = ["src/native/interpreter", INTERPRETER_SRC]
      paths.any? do |path|
        if Dir.exists?(path)
          Dir.glob("#{path}/**/*.cr").any? do |f|
            File.info(f).modification_time > bin_time
          end
        elsif File.exists?(path)
          File.info(path).modification_time > bin_time
        else
          false
        end
      end
    rescue
      false
    end

    private def run_compiler_based
      puts "[native.cr] Falling back to compile-based hot reload"
      config = Native::Core::Process::Config.new
      config.entry_point = @entry_point
      manager = Native::Core::Process::Manager.new(config)
      manager.start
    end
  end
end
