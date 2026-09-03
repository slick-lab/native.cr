require "./android"
require "./ios"

module Native::CLI
  # Pure helpers for the create command, kept module-level so specs can
  # exercise them without running the generator.
  module CreateUtil
    # Project names become a directory path and show up in generated files —
    # reject anything that could escape the target directory or break the
    # generated Crystal code.
    def self.valid_project_name?(name : String) : Bool
      !name.empty? && name.match(/\A[a-zA-Z][a-zA-Z0-9_-]*\z/) != nil
    end

    def self.known_template?(name : String) : Bool
      {"app", "game"}.includes?(name)
    end

    # `crystal --version` prints "Crystal 1.20.0 [c7d6de74b] (2026-04-16)" —
    # the generated shard.yml needs just the number. Returns nil when no
    # version can be found.
    def self.extract_crystal_version(raw : String) : String?
      raw.match(/Crystal\s+(\d+\.\d+\.\d+)/).try &.[1]
    end
  end

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
          else
            # Unknown extra arguments used to be swallowed silently.
            puts "[native.cr] Warning: ignoring unexpected argument '#{args[i]}'"
          end
          i += 1
        end
      end

      if @project_name.empty?
        puts "Error: Project name required"
        show_help
        exit(1)
      end

      unless CreateUtil.valid_project_name?(@project_name)
        puts "Error: Invalid project name '#{@project_name}'"
        puts "Use letters, digits, '-' and '_' only (must start with a letter) —"
        puts "the name becomes a directory and a Crystal module-safe identifier."
        exit(1)
      end

      unless CreateUtil.known_template?(@template)
        puts "Error: Unknown template '#{@template}' (available: app, game)"
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

      # Refuse to clobber an existing project instead of silently
      # overwriting its files.
      if Dir.exists?(@path) && (File.exists?("#{@path}/shard.yml") || File.exists?("#{@path}/src/main.cr"))
        puts "[native.cr] Error: #{@path} already contains a project (shard.yml or src/main.cr found)."
        puts "[native.cr] Remove it or pass a different -p/--path."
        exit(1)
      end

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
      puts "  shards install"
      puts "  native.cr build #{@platform == "both" ? "android" : @platform}"
      puts ""
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

        class MyApp < Native::App
          def setup : Nil
            label = Native::UI::TextView.new("Hello from native.cr!")
            label.text_size = 24
            label.center

            # Set up your UI here — create views, set callbacks, etc.
            # Example: add a button with a click handler
            #
            #   button = Native::UI::Button.new("Tap Me")
            #   button.width = 200
            #   button.height = 60
            #   button.on_click { puts "Tapped!" }
            #
            # Available UI components:
            #   Native::UI::TextView, Button, EditText, ImageView
            #   CheckBox, RadioButton, Switch, Spinner, ScrollView
            #   LinearLayout, CardView, RecyclerView, WebView
            #
            # Access native platform APIs:
            #   Native::Platform.screen_width
            #   Native::Network.get("https://api.example.com")
            #   Native::Storage::Preferences.new("my_prefs")
          end

          def on_touch_began(x : Float32, y : Float32) : Nil
            # Handle touch input
          end

          def on_key_pressed(key : Int32) : Nil
            # Handle keyboard input
          end
        end

        Native::App.registered_subclass = MyApp
      CR
      )
    end

    private def create_game_template
      File.write("#{@path}/src/main.cr", <<-CR
        require "native"

        class MyGame < Native::App
          include Native::GameLoop::GameLoopDSL

          @player_x : Float64 = 100.0
          @player_y : Float64 = 100.0
          @score : Int32 = 0

          def setup : Nil
            game_loop(target_fps: 60, mode: Native::GameLoop::LoopMode::Adaptive)
          end

          def game_start : Nil
            puts "Game started!"
          end

          def game_update(delta_time : Float64) : Nil
            # Update game logic each frame
          end

          def game_fixed_update(delta_time : Float64) : Nil
            # Fixed-timestep physics goes here
          end

          def game_render(alpha : Float64) : Nil
            # Rendering is handled by the framework on mobile.
            # Use the Native::Math module for vectors, rects, etc.
          end

          def on_touch_began(x : Float32, y : Float32) : Nil
            @player_x = x.to_f64
            @player_y = y.to_f64
            @score += 1
            puts "Score: \#{@score}"
          end
        end

        Native::App.registered_subclass = MyGame
      CR
      )
    end

    private def create_shard_yml
      # `crystal --version` prints "Crystal 1.20.0 [c7d6de74b] (...)" — the
      # raw first line used to be written as the constraint verbatim,
      # producing an invalid `crystal: ">= Crystal 1.20.0 [...]"`.
      version = CreateUtil.extract_crystal_version(
        `crystal --version 2>/dev/null`
      )
      crystal_constraint = version ? ">= #{version}" : nil

      content = <<-YAML
        name: #{@project_name}
        version: 0.1.0

        authors:
          - Your Name <you@example.com>

        dependencies:
          native:
            github: slick-lab/native.cr

        license: MIT
      YAML

      if crystal_constraint
        content = content.sub("license: MIT", "crystal: \"#{crystal_constraint}\"\n\nlicense: MIT")
      end

      File.write("#{@path}/shard.yml", content)
    end
  end
end
