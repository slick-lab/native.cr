require "json"
require "file_utils"
require "signal"
require "./native/app"
require "./native/cli/*"
require "./native/framework/*"
require "./native/framework/ui/view"
require "./native/framework/ui/text_view"
require "./native/framework/ui/icon"
require "./native/framework/ui/button"
require "./native/framework/ui/card_view"
require "./native/framework/ui/checkbox"
require "./native/framework/ui/edit_text"
require "./native/framework/ui/image_view"
require "./native/framework/ui/linear_layout"
require "./native/framework/ui/progress_bar"
require "./native/framework/ui/recycler_view"
require "./native/framework/ui/scroll_view"
require "./native/framework/ui/seek_bar"
require "./native/framework/ui/radiobutton"
require "./native/framework/ui/spinner"
require "./native/framework/ui/switch"
require "./native/framework/ui/web_view"
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
    if args.includes?("--version")
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
      Native::CLI::CreateCommand.new(args[1..-1]).run
    when "build"
      Native::CLI::BuildCommand.new(args[1..-1]).run
    when "reload"
      Native::CLI::ReloadCommand.new(args[1..-1]).run
    when "doctor"
      Native::CLI::DoctorCommand.new(args[1..-1]).run
    else
      puts "Unknown command: #{args[0]}"
    end
  end
end

Native.run
