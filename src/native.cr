require "json"
require "file_utils"
require "signal"

require "./native/framework/*"
require "./native/framework/ui/*"
require "./native/framework/animation/*"
require "./native/framework/dialog/*"
require "./native/framework/media/*"
require "./native/framework/navigation/*"

{% if flag?(:android) %}
  require "./native/engine/android/*"
{% elsif flag?(:ios) %}
  require "./native/engine/ios/*"
{% end %}

module Native
  VERSION = "0.1.0"

  def self.run
    args = ARGV
    if args.include?("--version")
      puts "Native #{VERSION}"
      exit(0)
    elsif args.empty?
      puts "[native.cr] commands"
      puts "native.cr create <name>  Create a new project"
      puts "native.cr build         Build the project"
      puts "native.cr reload <file> start development with fast reload"
      puts "native.cr doctor check toolchain installation"
      return
    end

    case args[0]
    when "create"
      require "./native/cli/create"
    when "build"
      require "./native/cli/build"
    when "reload"
      require "./native/cli/reload"
    when "doctor"
      require "./native/cli/doctor"
    else
      puts "Unknown command: #{args[0]}"
    end
  end
end

  Native.run
