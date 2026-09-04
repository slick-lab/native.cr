require "json"
require "file_utils"
require "signal"
require "./native/app"
require "./native/cli/*"

# Engine must be loaded before framework (framework uses JNIHelpers)
{% if flag?(:native_android) %}
  require "./native/engine/android/*"
{% elsif flag?(:native_ios) %}
  require "./native/engine/ios/*"
{% end %}

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
# Navigation: load Screen before Navigator (Navigator references Screen type)
require "./native/framework/navigation/screen"
require "./native/framework/navigation/navigator"
require "./native/framework/navigation/toolbar"

module Native
  VERSION = "0.1.7"

  def self.run
    args = ARGV
    # Only treat --version as the command when it is the command —
    # `native.cr create my_app --version` used to print the version and
    # exit instead of creating anything.
    if args[0]? == "--version"
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
    when "sign"
      Native::CLI::SignCommand.new(args[1..-1]).run
    else
      puts "Unknown command: #{args[0]}"
    end
  end
end

Native.run
