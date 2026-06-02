#!/usr/bin/env bash

# native.cr/cli/create.sh

set -e

COMMAND="create"
PROJECT_NAME=""
PROJECT_PATH=""
TEMPLATE_TYPE="app"

show_help() {
    echo "Usage: native.cr create [OPTIONS] PROJECT_NAME"
    echo ""
    echo "Create a new native.cr project"
    echo ""
    echo "Options:"
    echo "  -t, --template TYPE    Template type (app, game, library) [default: app]"
    echo "  -p, --path PATH        Project directory path [default: ./PROJECT_NAME]"
    echo "  -h, --help             Show this help"
    echo ""
    echo "Examples:"
    echo "  native.cr create my_app"
    echo "  native.cr create projects/my_app"
    echo "  native.cr create my_game -t game"
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--template)
                TEMPLATE_TYPE="$2"
                shift 2
                ;;
            -p|--path)
                PROJECT_PATH="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                if [[ -z "$PROJECT_NAME" ]]; then
                    PROJECT_NAME="$1"
                    shift
                else
                    echo "Unknown option: $1"
                    show_help
                    exit 1
                fi
                ;;
        esac
    done
    
    if [[ -z "$PROJECT_NAME" ]]; then
        echo "Error: Project name required"
        show_help
        exit 1
    fi
    
    if [[ -z "$PROJECT_PATH" ]]; then
        PROJECT_PATH="./$PROJECT_NAME"
    fi
}

create_project() {
    echo "Creating native.cr project: $PROJECT_NAME"
    echo "Location: $PROJECT_PATH"
    echo "Template: $TEMPLATE_TYPE"
    echo ""
    
    mkdir -p "$PROJECT_PATH"
    mkdir -p "$PROJECT_PATH/src"
    mkdir -p "$PROJECT_PATH/spec"
    mkdir -p "$PROJECT_PATH/assets"
    
    case "$TEMPLATE_TYPE" in
        app)
            create_app_template
            ;;
        game)
            create_game_template
            ;;
        library)
            create_library_template
            ;;
        *)
            echo "Unknown template: $TEMPLATE_TYPE"
            exit 1
            ;;
    esac
    
    create_shard_yml
    create_gitignore
    create_spec_helper
    
    if command -v git &> /dev/null; then
        cd "$PROJECT_PATH"
        git init
        git add .
        git commit -m "Initial commit: native.cr project"
        echo ""
        echo "Git repository initialized"
    fi
    
    echo ""
    echo "Project created successfully!"
    echo ""
    echo "Next steps:"
    echo "  cd $PROJECT_PATH"
    echo "  native.cr run"
    echo "  native.cr build android"
    echo "  native.cr build ios"
}

create_app_template() {
    cat > "$PROJECT_PATH/src/main.cr" << 'EOF'
# Hello World App for native.cr

require "native"

class HelloWorldApp < Native::App
  @[Preserve]
  property message : String = "Hello, World!"
  
  @[Preserve]
  property tap_count : Int32 = 0
  
  @label : UI::Text?
  @button : UI::Button?
  
  def setup
    set_background_color(240, 240, 245)
    
    @label = UI::Text.new
    @label.not_nil!.text = @message
    @label.not_nil!.text_size = 24
    @label.not_nil!.color = Styling::Color.from_hex(0x333333)
    
    @button = UI::Button.new
    @button.not_nil!.text = "Tap Me"
    @button.not_nil!.background_color = Styling::Color.from_hex(0x007AFF)
    @button.not_nil!.text_color = Styling::Color.white
    @button.not_nil!.corner_radius = Styling::CornerRadius.all(8)
    @button.not_nil!.width = 120
    @button.not_nil!.height = 44
    @button.not_nil!.on_click = ->{ on_button_tap }
    
    column = UI::Column.new
    column.spacing = 20
    column.add_child(@label.not_nil!)
    column.add_child(@button.not_nil!)
    
    container = UI::Container.new
    container.padding = Styling::EdgeInsets.all(20)
    container.add_child(column)
    
    @root = container
  end
  
  def on_button_tap
    @tap_count += 1
    @message = "Tapped \(@tap_count) time"
    @message += "s" if @tap_count != 1
    @label.not_nil!.text = @message
    
    if @tap_count % 5 == 0
      change_color(255, 100, 100)
      Native::Platform::HapticFeedback.light
      Native::Dialog.toast("You're on a roll!")
    else
      change_color(100, 200, 100)
    end
  end
  
  def draw
    @root.try &.draw(renderer)
  end
end

Native::App.start(HelloWorldApp)
EOF

    cat > "$PROJECT_PATH/assets/README.md" << 'EOF'
# Assets Directory

Place your images, sounds, and other assets here.

Supported formats:
- Images: PNG, JPG
- Audio: MP3, WAV, OGG
- Fonts: TTF, OTF
EOF
}

create_game_template() {
    cat > "$PROJECT_PATH/src/main.cr" << 'EOF'
# Game Template for native.cr

require "native"

class MyGame < Native::App
  include Native::GameLoop::GameLoopDSL
  
  @player_x : Float64 = 0.0
  @player_y : Float64 = 0.0
  @player_size : Int32 = 50
  @score : Int32 = 0
  
  def setup
    set_background_color(50, 50, 80)
    
    game_loop(target_fps: 60, mode: Native::GameLoop::LoopMode::Adaptive)
  end
  
  def game_start
    Native::Dialog.toast("Game Started!")
  end
  
  def game_update(delta_time : Float64)
    # Update game logic here
  end
  
  def game_fixed_update(delta_time : Float64)
    # Physics updates here
  end
  
  def game_render(alpha : Float64)
    draw_player
    draw_score
  end
  
  def on_touch_began(x : Float32, y : Float32)
    @player_x = x.to_f64 - @player_size // 2
    @player_y = y.to_f64 - @player_size // 2
    @score += 1
    Native::Platform::HapticFeedback.light
  end
  
  private def draw_player
    draw_rect(renderer, 
              @player_x.to_i, @player_y.to_i, 
              @player_size, @player_size,
              255, 100, 100, 255)
  end
  
  private def draw_score
    draw_text(renderer, "Score: #{@score}", 20, 60, 24, 255, 255, 255)
  end
end

Native::App.start(MyGame)
EOF
}

create_library_template() {
    cat > "$PROJECT_PATH/src/lib.cr" << 'EOF'
# Library Template for native.cr

module MyLibrary
  VERSION = "0.1.0"
  
  def self.hello : String
    "Hello from MyLibrary!"
  end
  
  def self.add(a : Int32, b : Int32) : Int32
    a + b
  end
  
  def self.greet(name : String) : String
    "Hello, #{name}!"
  end
end
EOF

    cat > "$PROJECT_PATH/src/main.cr" << 'EOF'
require "./lib"

puts MyLibrary.hello
puts MyLibrary.add(5, 3)
puts MyLibrary.greet("World")
EOF
}

create_shard_yml() {
    cat > "$PROJECT_PATH/shard.yml" << EOF
name: $PROJECT_NAME
version: 0.1.0

authors:
  - Your Name <you@example.com>

targets:
  main:
    main: src/main.cr

dependencies:
  native:
    github: native-cr/native.cr
    version: ~> 0.1.0

crystal: ">= 1.20.0"

license: MIT
EOF
}

create_gitignore() {
    cat > "$PROJECT_PATH/.gitignore" << 'EOF'
/.native_cache/
/.shards/
/shard.lock
/*.dSYM/
/*.o
/*.so
/*.a
/*.dll
/*.exe
/.DS_Store
/.idea/
/.vscode/
/build/
/dist/
EOF
}

create_spec_helper() {
    cat > "$PROJECT_PATH/spec/spec_helper.cr" << 'EOF'
require "spec"
require "../src/main"
EOF

    if [[ "$TEMPLATE_TYPE" != "library" ]]; then
        cat > "$PROJECT_PATH/spec/main_spec.cr" << 'EOF'
require "./spec_helper"

describe "App" do
  it "works" do
    true.should eq(true)
  end
end
EOF
    else
        cat > "$PROJECT_PATH/spec/lib_spec.cr" << 'EOF'
require "./spec_helper"
require "../src/lib"

describe MyLibrary do
  it "returns hello" do
    MyLibrary.hello.should eq("Hello from MyLibrary!")
  end
  
  it "adds numbers" do
    MyLibrary.add(2, 3).should eq(5)
  end
  
  it "greets by name" do
    MyLibrary.greet("Crystal").should eq("Hello, Crystal!")
  end
end
EOF
    fi
}

parse_args "$@"
create_project
