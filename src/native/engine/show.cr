require "crsfml"

# Desktop preview runner for native.cr apps.
# Uses SFML (crsfml shard) for cross-platform windowing and event handling.
#
# Usage:
#   require "native"
#   require "native/engine/show"
#
#   class MyApp < Native::App
#     def setup
#       puts "App ready!"
#     end
#   end
#
#   Native::DesktopRunner.run(MyApp)
#
module Native
  class DesktopRunner
    WIDTH  = 1024
    HEIGHT = 768
    TITLE  = "native.cr preview"

    @app : App

    def initialize(app_class : App.class)
      @window = SF::RenderWindow.new(
        SF::VideoMode.new(WIDTH, HEIGHT),
        TITLE,
        SF::Style::Default
      )
      @window.framerate_limit = 60

      @app = app_class.new
      @running = true
    end

    def self.run(app_class : App.class)
      runner = new(app_class)
      runner.start
    end

    def start
      @app.setup
      @app.on_resume

      while @running
        handle_events
        @window.clear(SF::Color.new(30, 30, 30))
        # Apps render via their own renderer or the framework's UI system.
        # No draw() callback — App uses setup + event-driven updates.
        @window.display
      end

      @app.on_pause
      @app.on_destroy
    end

    private def handle_events
      while event = @window.poll_event
        case event
        when SF::Event::Closed
          @running = false
        when SF::Event::KeyPressed
          if event.code == SF::Keyboard::Escape
            @running = false
          else
            @app.on_key_pressed(key_to_int(event.code))
          end
        when SF::Event::KeyReleased
          @app.on_key_released(key_to_int(event.code))
        when SF::Event::MouseButtonPressed
          @app.on_touch_began(event.x.to_f32, event.y.to_f32)
        when SF::Event::MouseButtonReleased
          @app.on_touch_ended(event.x.to_f32, event.y.to_f32)
        when SF::Event::MouseMoved
          # Only report moved when a button is held (dragging)
          if SF::Mouse.pressed?(SF::Mouse::Left) ||
             SF::Mouse.pressed?(SF::Mouse::Right) ||
             SF::Mouse.pressed?(SF::Mouse::Middle)
            @app.on_touch_moved(event.x.to_f32, event.y.to_f32)
          end
        end
      end
    end

    private def key_to_int(code : SF::Keyboard::Key) : Int32
      code.value
    end
  end
end
