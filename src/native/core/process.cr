# native/cr/src/core/process.cr
# Manages the app process, file watching, and fast restarts with state preservation

require "file_utils"
require "json"
require "process"

module NativeCR
  module Process
    # Error types
    class ProcessError < Exception; end
    class CompileError < Exception; end
    
    # Configuration for the process manager
    struct Config
      property entry_point : String = "main.cr"
      property watch_paths : Array(String) = ["./src"]
      property build_output : String = "./.native_cache/app"
      property state_file : String = "./.native_cache/state.json"
      property compile_timeout : Time::Span = 30.seconds
      
      def initialize
      end
    end
    
    # File watcher that triggers on changes
    class Watcher
      @last_mtimes = {} of String => Time
      @callback : String -> Nil
      
      def initialize(paths : Array(String), &callback : String -> Nil)
        @callback = callback
        @paths = paths
        scan_and_register
      end
      
      # Check for file changes
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
      
      # Initial scan
      private def scan_and_register
        @paths.each do |path|
          Dir.glob("#{path}/**/*.cr") do |file|
            @last_mtimes[file] = File.info(file).modification_time
          end
        end
      end
    end
    
    # The main process manager
    class Manager
      getter config : Config
      @current_process : ::Process?
      @state : JSON::Serializable?
      
      def initialize(@config : Config = Config.new)
        # Create cache directory
        Dir.mkdir_p(File.dirname(@config.build_output))
        Dir.mkdir_p(File.dirname(@config.state_file))
      end
      
      # Start the app with state preservation
      def start
        # Load saved state if exists
        load_saved_state
        
        # Initial build and run
        build_and_run
        
        # Start watcher
        watcher = Watcher.new(@config.watch_paths) do |changed_file|
          puts "[native.cr] Changed: #{changed_file}"
          fast_restart
        end
        
        # Main loop
        loop do
          watcher.check
          sleep 0.1.seconds
        end
      end
      
      # Fast restart — recompile and restart with state preserved
      def fast_restart
        puts "[native.cr] Fast restart..."
        
        # Capture current state before killing
        capture_state
        
        # Kill current process
        stop
        
        # Rebuild and run
        build_and_run
      end
      
      # Stop the current process
      def stop
        if @current_process && !@current_process.terminated?
          @current_process.terminate
          @current_process.wait
        end
        @current_process = nil
      end
      
      private def capture_state
        # Send SIGUSR1 to request state serialization
        # The app will write state to @config.state_file
        if @current_process && !@current_process.terminated?
          @current_process.signal(::Process::Signal::USR1)
          # Give it a moment to write the file
          sleep 0.2.seconds
        end
      end
      
      private def load_saved_state
        if File.exists?(@config.state_file)
          begin
            json = File.read(@config.state_file)
            # State will be loaded by the app on startup
            puts "[native.cr] Loaded saved state"
          rescue
            # No valid state file
          end
        end
      end
      
      private def build_and_run
        # Compile the app
        compile
        
        # Run the compiled binary
        run
      end
      
      private def compile
        puts "[native.cr] Building #{@config.entry_point}..."
        
        # Crystal build command
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
        # Run the compiled app, passing state file location via env var
        env = ENV.to_h
        env["NATIVE_CR_STATE_FILE"] = @config.state_file
        
        @current_process = ::Process.new(
          @config.build_output,
          shell: true,
          env: env,
          output: true,
          error: true
        )
        
        puts "[native.cr] App running (PID: #{@current_process.pid})"
        
        # Spawn a fiber to handle process exit
        spawn do
          @current_process.try(&.wait)
          puts "[native.cr] App exited"
        end
      end
    end
  end
end
