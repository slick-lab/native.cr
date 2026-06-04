# src/native/core/process.cr

require "file_utils"
require "json"
require "process"

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
      @is_mobile : Bool

      def initialize(@config : Config = Config.new)
        Dir.mkdir_p(File.dirname(@config.build_output))
        Dir.mkdir_p(File.dirname(@config.state_file))

        @is_mobile = {% if flag?(:android) || flag?(:ios) %}true{% else %}false{% end %}
      end

      def start
        if @is_mobile
          start_mobile
        else
          start_desktop
        end
      end

      def fast_restart
        if @is_mobile
          fast_restart_mobile
        else
          fast_restart_desktop
        end
      end

      def stop
        return unless @current_process && !@current_process.terminated?

        if !@is_mobile
          @current_process.terminate
          @current_process.wait
        end

        @current_process = nil
      end

      private def start_mobile
        puts "[native.cr] Starting in mobile mode"
        compile_and_run
      end

      private def start_desktop
        puts "[native.cr] Starting in desktop mode"
        load_saved_state
        build_and_run

        watcher = Watcher.new(@config.watch_paths) do |changed_file|
          puts "[native.cr] Changed: #{changed_file}"
          fast_restart_desktop
        end

        loop do
          watcher.check
          sleep 0.1.seconds
        end
      end

      private def fast_restart_mobile
        puts "[native.cr] Fast restart not available in mobile mode"
        puts "[native.cr] Rebuilding and restarting..."
        stop
        compile_and_run
      end

      private def fast_restart_desktop
        puts "[native.cr] Fast restart..."
        capture_state_desktop
        stop
        build_and_run
      end

      private def capture_state_desktop
        if @current_process && !@current_process.terminated?
          @current_process.signal(::Process::Signal::USR1)
          sleep 0.2.seconds
        end
      end

      private def load_saved_state
        return if @is_mobile

        if File.exists?(@config.state_file)
          begin
            json = File.read(@config.state_file)
            puts "[native.cr] Loaded saved state"
          rescue
          end
        end
      end

      private def build_and_run
        compile
        run
      end

      private def compile_and_run
        compile
        run_mobile
      end

      private def compile
        puts "[native.cr] Building #{@config.entry_point}..."

        cmd = "crystal build #{@config.entry_point} -o #{@config.build_output} --error-trace"

        output = `#{cmd} 2>&1`

        if $?.success?
          puts "[native.cr] Build successful"
        else
          puts "[native.cr] Compilation failed:"
          puts output
          raise CompileError.new("Build failed")
        end
      end

      private def run
        env = ENV.to_h
        env["NATIVE_CR_STATE_FILE"] = @config.state_file

        @current_process = ::Process.new(
          @config.build_output,
          shell: true,
          env: env
        )

        puts "[native.cr] App running (PID: #{@current_process.not_nil!.pid})"

        spawn do
          @current_process.try(&.wait)
          puts "[native.cr] App exited"
        end
      end

      private def run_mobile
        puts "[native.cr] Running on mobile device"
        puts "[native.cr] App started"
      end
    end
  end
end
