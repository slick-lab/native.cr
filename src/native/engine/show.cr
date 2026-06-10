require "sdl"
require "opengl"

class NativeDesktop
  WIDTH  = 1024
  HEIGHT =  768

  def initialize(app_class : Native::App.class)
    SDL.init(SDL::Init::VIDEO)

    @window = SDL::Window.new(
      "native.cr",
      x: SDL::Window::POS_CENTERED,
      y: SDL::Window::POS_CENTERED,
      width: WIDTH,
      height: HEIGHT,
      flags: SDL::Window::OPENGL
    )

    @gl_context = @window.gl_create_context
    @app = app_class.new

    setup_opengl
    @app.setup
  end

  def run
    running = true

    while running
      while event = SDL::Event.poll
        case event
        when SDL::Event::Quit
          running = false
        when SDL::Event::KeyDown
          if event.sym == SDL::Key::ESCAPE
            running = false
          else
            @app.on_key_pressed(event.sym.to_i) if @app.responds_to?(:on_key_pressed)
          end
        when SDL::Event::KeyUp
          @app.on_key_released(event.sym.to_i) if @app.responds_to?(:on_key_released)
        when SDL::Event::MouseButtonDown
          @app.on_touch_began(event.x.to_f32, event.y.to_f32) if @app.responds_to?(:on_touch_began)
        when SDL::Event::MouseButtonUp
          @app.on_touch_ended(event.x.to_f32, event.y.to_f32) if @app.responds_to?(:on_touch_ended)
        when SDL::Event::MouseMotion
          if event.state != 0
            @app.on_touch_moved(event.x.to_f32, event.y.to_f32) if @app.responds_to?(:on_touch_moved)
          end
        end
      end

      glClear(GL_COLOR_BUFFER_BIT)
      @app.draw
      @window.gl_swap
      SDL.delay(16)
    end
  end

  def finalize
    @gl_context = nil
    @window = nil
    SDL.quit
  end

  private def setup_opengl
    glClearColor(0.2, 0.3, 0.3, 1.0)
    glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    glViewport(0, 0, WIDTH, HEIGHT)
    glMatrixMode(GL_PROJECTION)
    glLoadIdentity
    glOrtho(0, WIDTH, HEIGHT, 0, -1, 1)
    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity
  end
end

app_class = MyApp
window = NativeDesktop.new(app_class)
window.run
window.finalize
