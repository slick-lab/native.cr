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
            current_mtime = File.info(file).modification_time

            if @last_mtimes[file]? != current_mtime
              changed_files << file
              @last_mtimes[file] = current_mtime
            end
          end
        end

        changed_files.each { |f| @callback.call(f) } if changed_files.any?
        changed_files.any?
      end

      private def scan_and_register
        @paths.each do |path|
          Dir.glob("#{path}/**/*.cr") do |file|
            @last_mtimes[file] = File.info(file).modification_time
          end
        end
      end
    end

    class Manager
      getter config : Config
      @current_process : ::Process?
      @state : JSON::Serializable?

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
        puts "[native.cr] Using #{ENV["CRYSTAL_WORKERS"] || "1"} CPU cores"
        puts "[native.cr] Cache directory: .native_cache/compiler"
        puts ""

        begin
          load_saved_state
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

      def stop
        if proc = @current_process
          return if proc.terminated?

          begin
            proc.terminate
            proc.wait
          rescue e
            puts "[native.cr] Error stopping process: #{e.message}"
          end
        end

        @current_process = nil
      end

      private def fast_restart_desktop
        puts "[native.cr] Fast restart..."
        begin
          capture_state_desktop
          stop
          build_and_run_desktop
        rescue e
          puts "[native.cr] Error during fast restart: #{e.message}"
        end
      end

      private def capture_state_desktop
        if proc = @current_process
          if !proc.terminated?
            proc.terminate
            sleep 0.2.seconds
          end
        end
      end

      private def load_saved_state
        if File.exists?(@config.state_file)
          begin
            json = File.read(@config.state_file)
            if json && json.size > 0
              puts "[native.cr] Loaded saved state"
            end
          rescue e
            puts "[native.cr] Warning: Could not load state file: #{e.message}"
          end
        end
      end

      private def build_and_run_desktop
        begin
          compile_desktop
          run_desktop
        rescue e
          puts "[native.cr] Error in build_and_run_desktop: #{e.message}"
        end
      end

      private def compile_desktop
        puts "[native.cr] Building desktop preview..."
        puts "[native.cr] Entry point: #{@config.entry_point}"

        unless File.exists?(@config.entry_point)
          raise CompileError.new("Entry point not found: #{@config.entry_point}")
        end

        bootstrap = File.join(File.dirname(@config.build_output), "desktop_bootstrap.cr")

        File.write(bootstrap, <<-CR
          require "#{File.expand_path(@config.entry_point)}"
          require "native/engine/desktop/show"
        CR
        )

        cmd = "crystal build #{bootstrap} -o #{@config.build_output}_desktop --error-trace"
        cmd += " --release" if @config.release

        begin
          start_time = Time.utc
          output = `#{cmd} 2>&1`
          elapsed = (Time.utc - start_time).total_seconds

          if $?.success?
            puts "[native.cr] Desktop build successful (%.2fs)" % elapsed
          else
            puts "[native.cr] Desktop build failed:"
            puts output
            raise CompileError.new("Desktop build failed")
          end
        rescue e
          puts "[native.cr] Error during desktop compilation: #{e.message}"
          raise CompileError.new("Desktop compilation error: #{e.message}")
        ensure
          File.delete(bootstrap) if File.exists?(bootstrap)
        end
      end

      private def run_desktop
        begin
          @current_process = ::Process.new(
            "#{@config.build_output}_desktop",
            shell: true
          )

          if proc = @current_process
            puts "[native.cr] Desktop preview running (PID: #{proc.pid})"

            spawn do
              begin
                proc.wait
                puts "[native.cr] Desktop preview exited"
              rescue e
                puts "[native.cr] Error waiting for desktop process: #{e.message}"
              ensure
                @current_process = nil
              end
            end
          else
            raise ProcessError.new("Failed to start desktop preview")
          end
        rescue e
          puts "[native.cr] Error starting desktop preview: #{e.message}"
          raise ProcessError.new("Failed to start desktop process: #{e.message}")
        end
      end
    end
  end
end
