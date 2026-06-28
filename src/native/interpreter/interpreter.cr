require "file_utils"
require "./nodes"
require "./parser"
require "./renderer"

module Native::Interpreter
  class Interpreter
    WATCH_INTERVAL = 0.15.seconds

    @source_file : String
    @renderer : Renderer
    @last_mtime : Time = Time::UNIX_EPOCH

    def initialize(@source_file : String)
      @renderer = Renderer.new
    end

    def run
      unless File.exists?(@source_file)
        STDERR.puts "[native.cr] Interpreter: file not found: #{@source_file}"
        exit(1)
      end

      puts "[native.cr] Interpreter starting"
      puts "[native.cr] Watching: #{@source_file}"
      puts "[native.cr] Press Escape or close the window to quit"
      puts ""

      app = parse_file
      @renderer.update_app(app)

      watcher_fiber = spawn do
        loop do
          begin
            current_mtime = File.info(@source_file).modification_time
            if current_mtime != @last_mtime
              @last_mtime = current_mtime
              puts "[native.cr] Reloading: #{@source_file}"
              reloaded = parse_file
              @renderer.update_app(reloaded)
            end
          rescue e
            puts "[native.cr] Watch error: #{e.message}"
          end
          sleep WATCH_INTERVAL
        end
      end

      _ = watcher_fiber

      @renderer.run
    end

    private def parse_file : AppNode
      source = File.read(@source_file)
      parser = Parser.new(source)
      app = parser.parse
      if err = app.error_message
        puts "[native.cr] Parse error: #{err}"
      else
        puts "[native.cr] Parsed #{@source_file}: #{count_nodes(app.root)} nodes"
      end
      app
    rescue e
      app = AppNode.new
      app.error_message = "Read error: #{e.message}"
      app
    end

    private def count_nodes(node : UINode?) : Int32
      return 0 unless node
      1 + node.children.sum { |c| count_nodes(c) }
    end
  end
end
