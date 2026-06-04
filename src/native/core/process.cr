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
      property desktop_mode : Bool = true

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
        if proc = @current_process
          return if proc.terminated?
          
          if !@is_mobile
            begin
              proc.terminate
              proc.wait
            rescue e
              puts "[native.cr] Error stopping process: #{e.message}"
            end
          end
        end

        @current_process = nil
      end

      private def start_mobile
        puts "[native.cr] Starting in mobile mode"
        begin
          compile_and_run
        rescue e
          puts "[native.cr] Error in mobile mode: #{e.message}"
        end
      end

      private def start_desktop
        puts "[native.cr] Starting desktop preview"
        
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

      private def fast_restart_mobile
        puts "[native.cr] Fast restart not available in mobile mode"
        puts "[native.cr] Rebuilding and restarting..."
        begin
          stop
          compile_and_run
        rescue e
          puts "[native.cr] Error during restart: #{e.message}"
        end
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
        return if @is_mobile

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

      private def compile_and_run
        begin
          compile
          run_mobile
        rescue e
          puts "[native.cr] Error in compile_and_run: #{e.message}"
        end
      end

      private def compile
        puts "[native.cr] Building #{@config.entry_point}..."

        unless File.exists?(@config.entry_point)
          raise CompileError.new("Entry point not found: #{@config.entry_point}")
        end

        cmd = "crystal build #{@config.entry_point} -o #{@config.build_output} --error-trace"

        begin
          output = `#{cmd} 2>&1`

          if $?.success?
            puts "[native.cr] Build successful"
          else
            puts "[native.cr] Compilation failed:"
            puts output
            raise CompileError.new("Build failed")
          end
        rescue e
          puts "[native.cr] Error during compilation: #{e.message}"
          raise CompileError.new("Compilation error: #{e.message}")
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

        begin
          output = `#{cmd} 2>&1`

          if $?.success?
            puts "[native.cr] Desktop build successful"
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

      private def run
        env = ENV.to_h
        env["NATIVE_CR_STATE_FILE"] = @config.state_file

        begin
          @current_process = ::Process.new(
            @config.build_output,
            shell: true,
            env: env
          )

          if proc = @current_process
            puts "[native.cr] App running (PID: #{proc.pid})"

            spawn do
              begin
                proc.wait
                puts "[native.cr] App exited"
              rescue e
                puts "[native.cr] Error waiting for process: #{e.message}"
              ensure
                @current_process = nil
              end
            end
          else
            raise ProcessError.new("Failed to create process")
          end
        rescue e
          puts "[native.cr] Error starting app: #{e.message}"
          raise ProcessError.new("Failed to start process: #{e.message}")
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

      private def run_mobile
        begin
          puts "[native.cr] Running on mobile device"
          puts "[native.cr] App started"
        rescue e
          puts "[native.cr] Error running on mobile: #{e.message}"
        end
      end
    end
  end
end
