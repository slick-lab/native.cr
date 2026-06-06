
require "json"
require "file_utils"
require "signal"

# Load all core modules
require "./native/math"
require "./native/core/*"

# Load all framework modules
require "./native/framework/*"

# Load all CLI modules
require "./native/cli/*"

# Load platform engines
{% if flag?(:android) %}
  require "./native/engine/android/*"
{% elsif flag?(:ios) %}
  require "./native/engine/ios/*"
{% end %}

module Native
  VERSION = "0.1.0"

  def self.run
    args = ARGV

    if args.empty?
      puts "Native.cr v#{VERSION}"
      puts ""
      puts "Usage: native.cr <command> [options]"
      puts ""
      puts "Commands:"
      puts "  create <name>     Create a new project"
      puts "  build <platform>  Build for android or ios"
      puts "  reload <file>     Start development with hot reload"
      puts "  doctor            Check toolchain installation"
      puts ""
      puts "Run 'native.cr <command> --help' for more information"
      return
    end

    case args[0]
    when "create"
      system("bash #{__DIR__}/../cli/create.sh #{args[1..-1].join(" ")}")
    when "build"
      Native::CLI::BuildCommand.new(args[1..-1]).run
    when "reload"
      Native::CLI::ReloadCommand.new(args[1..-1]).run
    when "doctor"
      Native::CLI::DoctorCommand.new(args[1..-1]).run
    else
      puts "Unknown command: #{args[0]}"
      puts "Run 'native.cr' without arguments for help"
    end
  end
end

Native.run
