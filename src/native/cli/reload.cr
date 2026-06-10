# src/native/cli/reload.cr

require "../core/process"

module Native::CLI
  class ReloadCommand
    @entry_point : String = "src/main.cr"

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
        else
          i += 1
        end
      end
    end

    def run
      if !File.exists?(@entry_point)
        puts "Error: Entry point not found: #{@entry_point}"
        return
      end

      config = Native::Core::Process::Config.new
      config.entry_point = @entry_point

      manager = Native::Core::Process::Manager.new(config)
      manager.start
    end
  end
end
