require "json"
require "../core/state"
{% if flag?(:android) %}
  require "../engine/android/android_main"
{% end %}
{% if flag?(:ios) %}
  require "../engine/ios/bridge"
{% end %}

module Native
  annotation Preserve; end

  abstract class App
    include JSON::Serializable

    macro inherited
      macro preserve
        {% preserve_vars = @type.instance_vars.select { |var| var.has_annotation! Native::Preserve } %}
        
        def to_json : String
          {
            {% for var in preserve_vars %}
              {{var.name.stringify}}: @{{var.name}},
            {% end %}
          }.to_json
        end
        
        def from_json(json : String) : Nil
          data = JSON.parse(json)
          {% for var in preserve_vars %}
            if data.has_key?({{var.name.stringify}})
              @{{var.name}} = data[{{var.name.stringify}}].as({{var.type}})
            end
          {% end %}
        end
      end
    end

    def initialize
      @_window = create_window
      @_renderer = create_renderer
      setup_signal_handlers
    end

    def run : Nil
      load_saved_state
      setup_callbacks
      start_event_loop
    end

    def background_color : (UInt8, UInt8, UInt8) -> Tuple(UInt8, UInt8, UInt8)
      {@_bg_r, @_bg_g, @_bg_b}
    end

    def background_color=(color : {UInt8, UInt8, UInt8}) : Nil
      @_bg_r, @_bg_g, @_bg_b = color
      update_background_color
    end

    def set_background_color(r : UInt8, g : UInt8, b : UInt8) : Nil
      @_bg_r = r
      @_bg_g = g
      @_bg_b = b
      update_background_color
    end

    def change_color(r : UInt8, g : UInt8, b : UInt8) : Nil
      set_background_color(r, g, b)
    end

    def screen_width : Int32
      @_screen_width
    end

    def screen_height : Int32
      @_screen_height
    end

    def framebuffer_width : Int32
      @_fb_width
    end

    def framebuffer_height : Int32
      @_fb_height
    end

    def dpi : Float32
      @_dpi
    end

    def content_scale : Float32
      @_content_scale
    end

    abstract def setup : Nil
    abstract def update : Nil
    abstract def draw : Nil

    def on_touch_began(x : Float32, y : Float32) : Nil
    end

    def on_touch_moved(x : Float32, y : Float32) : Nil
    end

    def on_touch_ended(x : Float32, y : Float32) : Nil
    end

    def on_key_pressed(key : Int32) : Nil
    end

    def on_key_released(key : Int32) : Nil
    end

    def on_pause : Nil
    end

    def on_resume : Nil
    end

    def on_destroy : Nil
    end

    private def create_window : Void*
      {% if flag?(:android) %}
        LibAndroid.create_native_window
      {% elsif flag?(:ios) %}
        LibIOS.create_metal_layer
      {% else %}
        Pointer(Void).null
      {% end %}
    end

    private def create_renderer : Void*
      {% if flag?(:android) %}
        LibAndroid.create_opengl_renderer(@_window)
      {% elsif flag?(:ios) %}
        LibIOS.create_metal_renderer(@_window)
      {% else %}
        Pointer(Void).null
      {% end %}
    end

    private def setup_signal_handlers : Nil
      {% if flag?(:android) %}
        Signal::USR1.trap { save_state }
        Signal::TERM.trap { save_state; exit(0) }
      {% end %}
    end

    private def save_state : Nil
      state_file = ENV["NATIVE_CR_STATE_FILE"]?
      return unless state_file

      begin
        File.write(state_file, to_json)
      rescue ex
        STDERR.puts "[native.cr] Failed to save state: #{ex.message}"
      end
    end

    private def load_saved_state : Nil
      state_file = ENV["NATIVE_CR_STATE_FILE"]?
      return unless state_file && File.exists?(state_file)

      begin
        json = File.read(state_file)
        from_json(json)
        File.delete(state_file)
      rescue ex
        STDERR.puts "[native.cr] Failed to load state: #{ex.message}"
      end
    end

    private def setup_callbacks : Nil
      {% if flag?(:android) %}
        setup_android_callbacks
      {% elsif flag?(:ios) %}
        setup_ios_callbacks
      {% end %}
    end

    private def setup_android_callbacks : Nil
      LibAndroid.set_on_touch_callback(@_window, ->(x : Float32, y : Float32, action : Int32) {
        app = App.current
        case action
        when 0 then app.on_touch_began(x, y)
        when 1 then app.on_touch_moved(x, y)
        when 2 then app.on_touch_ended(x, y)
        end
      })
    end

    private def setup_ios_callbacks : Nil
      LibIOS.set_on_touch_callback(@_window, ->(x : Float32, y : Float32, action : Int32) {
        app = App.current
        case action
        when 0 then app.on_touch_began(x, y)
        when 1 then app.on_touch_moved(x, y)
        when 2 then app.on_touch_ended(x, y)
        end
      })
    end

    private def start_event_loop : Nil
      setup

      {% if flag?(:android) %}
        loop do
          break if LibAndroid.poll_events(@_window) == 0
          update
          draw
          LibAndroid.swap_buffers(@_renderer)
        end
      {% elsif flag?(:ios) %}
        # iOS uses CADisplayLink, callback handled by bridge
        loop do
          NSRunLoop.current_run_loop.run
        end
      {% end %}
    end

    private def update_background_color : Nil
      {% if flag?(:android) %}
        LibAndroid.set_clear_color(@_renderer, @_bg_r, @_bg_g, @_bg_b)
      {% elsif flag?(:ios) %}
        LibIOS.set_clear_color(@_renderer, @_bg_r / 255.0, @_bg_g / 255.0, @_bg_b / 255.0)
      {% end %}
    end

    @@current : App?

    def self.current : App
      @@current.not_nil!
    end

    def self.start(app_class : App.class) : Nil
      app = app_class.new
      @@current = app
      app.run
    end
  end
end
