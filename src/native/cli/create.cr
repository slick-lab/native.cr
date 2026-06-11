# src/native/cli/create.cr

require "./android"
require "./ios"

module Native::CLI
  class CreateCommand
    @project_name : String = ""
    @path : String = ""
    @platform : String = "both"
    @template : String = "app"

    def initialize(args : Array(String))
      parse_args(args)
    end

    def parse_args(args : Array(String))
      i = 0
      while i < args.size
        case args[i]
        when "-p", "--path"
          @path = args[i + 1] if i + 1 < args.size
          i += 2
        when "--android"
          @platform = "android"
          i += 1
        when "--ios"
          @platform = "ios"
          i += 1
        when "-t", "--template"
          @template = args[i + 1] if i + 1 < args.size
          i += 2
        when "-h", "--help"
          show_help
          exit(0)
        else
          if @project_name.empty?
            @project_name = args[i]
          end
          i += 1
        end
      end

      if @project_name.empty?
        puts "Error: Project name required"
        show_help
        exit(1)
      end

      if @path.empty?
        @path = @project_name
      end
    end

    def show_help
      puts <<-HELP
      Usage: native.cr create [OPTIONS] PROJECT_NAME

      Create a new native.cr project.

      Options:
        -p, --path DIR       Project directory path [default: ./PROJECT_NAME]
        --android            Generate Android only project
        --ios                Generate iOS only project
        -t, --template TYPE  Template type [app, game, library] [default: app]
        -h, --help           Show this help

      Examples:
        native.cr create my_app
        native.cr create my_app --android
        native.cr create my_app --ios
      HELP
    end

    def run
      puts "[native.cr] Creating project: #{@project_name}"
      puts "[native.cr] Location: #{@path}"
      puts "[native.cr] Platform: #{@platform}"
      puts ""

      Dir.mkdir_p(@path)
      Dir.mkdir_p("#{@path}/src")
      Dir.mkdir_p("#{@path}/assets")

      create_main_cr
      create_shard_yml

      if @platform == "android" || @platform == "both"
        AndroidGenerator.new(@project_name, @path).generate
      end

      if @platform == "ios" || @platform == "both"
        IOSGenerator.new(@project_name, @path).generate
      end

      puts ""
      puts "[native.cr] Project created successfully!"
      puts ""
      puts "Next steps:"
      puts "  cd #{@path}"
      puts "  native.cr build #{@platform == "both" ? "android" : @platform}"
      puts ""

      if @platform == "android" || @platform == "both"
        puts "Android:"
        puts "  cd #{@path}/android && ./gradlew assembleDebug"
        puts "  APK: #{@path}/android/app/build/outputs/apk/debug/"
        puts ""
      end

      if @platform == "ios" || @platform == "both"
        puts "iOS:"
        puts "  open #{@path}/ios/#{@project_name}.xcodeproj"
        puts "  Build with Xcode"
        puts ""
      end
    end

    private def create_main_cr
      if @template == "game"
        create_game_template
      else
        create_app_template
      end
    end

    private def create_app_template
      File.write("#{@path}/src/main.cr", <<-CR
        require "native"

        include Native

        class MyApp < Native::App
          @[Preserve]
          property count : Int32 = 0

          def setup : Nil
            @label = Text.new
            @label.text = "Tap: 0"
            @label.text_size = 24

            button = Button.new
            button.text = "Tap Me"
            button.width = 120
            button.height = 44
            button.on_click = ->{ increment }

            column = Column.new
            column.spacing = 20
            column.add_child(@label)
            column.add_child(button)

            @root = column
          end

          def increment : Nil
            @count += 1
            @label.text = "Tap: \#{@count}"
          end
        end

        Native::App.start(MyApp)
      CR
      )
    end

    private def create_game_template
      File.write("#{@path}/src/main.cr", <<-CR
        require "native"

        include Native

        class MyGame < Native::App
          include Native::GameLoop::GameLoopDSL

          @player_x : Float64 = 0.0
          @player_y : Float64 = 0.0
          @player_size : Int32 = 50
          @score : Int32 = 0

          def setup : Nil
            set_background_color(50, 50, 80)
            game_loop(target_fps: 60, mode: Native::GameLoop::LoopMode::Adaptive)
          end

          def game_start : Nil
            Native::Dialog.toast("Game Started!")
          end

          def game_update(delta_time : Float64) : Nil
          end

          def game_fixed_update(delta_time : Float64) : Nil
          end

          def game_render(alpha : Float64) : Nil
            draw_rect(renderer, @player_x.to_i, @player_y.to_i, @player_size, @player_size, 255, 100, 100, 255)
            draw_text(renderer, "Score: \#{@score}", 20, 60, 24, 255, 255, 255)
          end

          def on_touch_began(x : Float32, y : Float32) : Nil
            @player_x = x.to_f64 - @player_size // 2
            @player_y = y.to_f64 - @player_size // 2
            @score += 1
            Native::Platform::HapticFeedback.light
          end
        end

        Native::App.start(MyGame)
      CR
      )
    end

    private def create_shard_yml
      version = `crystal --version 2>/dev/null`.lines.first?.to_s.strip
      File.write("#{@path}/shard.yml", <<-YAML
        name: #{@project_name}
        version: 0.1.0

        authors:
          - Your Name <you@example.com>

        dependencies:
          native:
            github: slick-lab/native.cr
            version: ~> 0.1.0

        crystal: ">= #{version}"

        license: MIT
      YAML
      )
    end
  end
end

if ARGV.size > 0 && ARGV[0] == "create"
  args = ARGV[1..-1] || [] of String
  cmd = Native::CLI::CreateCommand.new(args)
  cmd.run
end
