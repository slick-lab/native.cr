# src/native/core/process.cr

require "file_utils"
require "json"
require "process"
require "system"

module Native::Core
  module Process
    class ProcessError < Exception
    end

    class CompileError < Exception
    end

    struct Config
      property entry_point : String = "src/main.cr"
      property watch_paths : Array(String) = ["./src"]
      property build_output : String = "./.native_cache/app"
      property state_file : String = "./.native_cache/state.json"
      property compile_timeout : Time::Span = 30.seconds
      property release : Bool = false

      def initialize
      end
    end

    class Watcher
      @last_mtimes = {} of String => Time
      @callback : String -> Nil

      def initialize(paths : Array(String), &callback : String -> Nil)
        @callback = callback
        @paths = paths
        scan_and_register
      end

      def check
        changed_files = [] of String

        @paths.each do |path|
          Dir.glob("#{path}/**/*.cr") do |file|
            begin
              current_mtime = File.info(file).modification_time
              if @last_mtimes[file]? != current_mtime
                changed_files << file
                @last_mtimes[file] = current_mtime
              end
            rescue
            end
          end
        end

        changed_files.each { |f| @callback.call(f) } if changed_files.any?
        changed_files.any?
      end

      private def scan_and_register
        @paths.each do |path|
          next unless Dir.exists?(path)
          Dir.glob("#{path}/**/*.cr") do |file|
            begin
              @last_mtimes[file] = File.info(file).modification_time
            rescue
            end
          end
        end
      end
    end

    class Manager
      getter config : Config

      # Current running process — written only from the main fiber, read
      # by the monitor fiber. The generation counter lets the monitor fiber
      # know if a restart happened while it was blocked on proc.wait.
      @current_process : ::Process? = nil
      @generation : Int32 = 0

      def initialize(@config : Config = Config.new)
        Dir.mkdir_p(File.dirname(@config.build_output))
        Dir.mkdir_p(File.dirname(@config.state_file))

        cache_dir = File.join(Dir.current, ".native_cache/compiler")
        Dir.mkdir_p(cache_dir)
        ENV["CRYSTAL_CACHE_DIR"] = cache_dir

        cpu_count = System.cpu_count
        if cpu_count && cpu_count > 1
          ENV["CRYSTAL_WORKERS"] = cpu_count.to_s
        end
      end

      def start
        puts "[native.cr] Starting desktop preview"
        puts "[native.cr] Using #{ENV["CRYSTAL_WORKERS"]? || "1"} CPU cores"
        puts "[native.cr] Cache directory: .native_cache/compiler"
        puts ""

        begin
          build_and_run_desktop
        rescue e
          puts "[native.cr] Error during startup: #{e.message}"
          return
        end

        watcher = Watcher.new(@config.watch_paths) do |changed_file|
          puts "[native.cr] Changed: #{changed_file}"
          begin
            fast_restart_desktop
          rescue e
            puts "[native.cr] Error during restart: #{e.message}"
          end
        end

        loop do
          begin
            watcher.check
          rescue e
            puts "[native.cr] Error checking files: #{e.message}"
          end
          sleep 0.1.seconds
        end
      end

      def fast_restart
        fast_restart_desktop
      end

      # Stop the currently running preview process.
      # Sends SIGTERM (which triggers state-save in the app), waits for
      # the process to exit, then clears the reference.
      def stop
        proc = @current_process
        @current_process = nil # clear first so the monitor fiber does nothing
        return unless proc

        begin
          unless proc.terminated?
            proc.terminate
            # Give the process up to 1 s to save state and exit cleanly.
            deadline = Time.monotonic + 1.second
            while Time.monotonic < deadline && !proc.terminated?
              sleep 0.05.seconds
            end
            # If still alive, force-kill — "terminate" again would just
            # send a second SIGTERM, and a hung app ignoring SIGTERM used
            # to hang `native.cr reload` forever.
            proc.signal(Signal::KILL) unless proc.terminated?
          end
          proc.wait rescue nil
        rescue e
          puts "[native.cr] Warning stopping process: #{e.message}"
        end
      end

      private def fast_restart_desktop
        puts "[native.cr] Fast restart..."
        begin
          # Terminate the old process so it saves state (SIGTERM handler
          # in App calls save_state before exiting).
          stop
          build_and_run_desktop
        rescue e
          puts "[native.cr] Error during fast restart: #{e.message}"
        end
      end

      private def build_and_run_desktop
        compile_desktop
        run_desktop
      end

      private def compile_desktop
        puts "[native.cr] Building desktop preview..."
        puts "[native.cr] Entry point: #{@config.entry_point}"

        unless File.exists?(@config.entry_point)
          raise CompileError.new("Entry point not found: #{@config.entry_point}")
        end

        Dir.mkdir_p(File.dirname(@config.build_output))
        bootstrap = File.join(File.dirname(@config.build_output), "desktop_bootstrap.cr")

        # The bootstrap used to also require
        # `lib/native/src/native/engine/desktop/show` — a path that never
        # existed in the repo (and even the real engine/show.cr needs the
        # opt-in crsfml shard). The user's entry point already requires
        # "native", which loads the whole framework; the SFML preview
        # runner stays opt-in via `require "native/engine/show"`.
        entry_require = if @config.entry_point.starts_with?("/")
                          %Q(require "#{@config.entry_point}")
                        else
                          %Q(require "../#{@config.entry_point}")
                        end

        File.write(bootstrap, <<-CR
          #{entry_require}
        CR
        )

        binary = "#{@config.build_output}_desktop"
        crystal_args = ["build", bootstrap, "-o", binary, "--error-trace"]
        crystal_args << "--release" if @config.release

        begin
          start_time = Time.utc
          # Run without a shell: interpolated paths with spaces used to
          # break the backtick command line. (:: prefix — inside
          # Native::Core::Process, a bare `Process` resolves to this
          # module, not to ::Process.)
          compile_output = IO::Memory.new
          result = ::Process.run("crystal", args: crystal_args, output: compile_output, error: compile_output)
          elapsed = (Time.utc - start_time).total_seconds

          unless result.success?
            puts "[native.cr] Desktop build failed (#{elapsed.round(2)}s):"
            puts compile_output
            raise CompileError.new("Desktop build failed")
          end

          puts "[native.cr] Desktop build successful (%.2fs)" % elapsed
        ensure
          File.delete(bootstrap) if File.exists?(bootstrap)
        end
      end

      private def run_desktop
        binary = "#{@config.build_output}_desktop"
        unless File.exists?(binary)
          raise ProcessError.new("Binary not found: #{binary}")
        end

        # Pass the state file path so the app can save/restore state across
        # reloads. SIGTERM (sent by stop()) triggers save_state in App.
        state_file = File.expand_path(@config.state_file)
        env = {"NATIVE_CR_STATE_FILE" => state_file}

        proc = ::Process.new(binary, env: env, shell: false)
        @current_process = proc
        this_gen = @generation += 1
        puts "[native.cr] Desktop preview running (PID: #{proc.pid})"

        spawn do
          begin
            proc.wait
          rescue
          ensure
            # Only nil the reference if we're still the current generation
            # (i.e. no restart happened while we were waiting).
            if @generation == this_gen
              @current_process = nil
              puts "[native.cr] Desktop preview exited"
            end
          end
        end
      end
    end
  end
end
