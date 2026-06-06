# src/native/framework/app.cr

require "json"
require "signal"
require "../core/state"

abstract class NativeApp
  include JSON::Serializable

  macro preserve
    {% preserve_vars = @type.instance_vars.select { |var| var.has_annotation! Preserve } %}
    
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

  annotation Preserve; end

  def initialize
    @renderer = nil
    @bg_r = 100
    @bg_g = 100
    @bg_b = 100
    @screen_width = 0
    @screen_height = 0
    setup_signal_handlers
  end

  private def setup_signal_handlers
    Signal::USR1.trap do
      save_state
    end
    
    Signal::TERM.trap do
      save_state
      exit(0)
    end
  end

  private def save_state
    state_file = ENV["NATIVE_CR_STATE_FILE"]?
    
    if state_file
      begin
        json = to_json
        File.write(state_file, json)
        STDERR.puts "[native.cr] State saved to #{state_file}"
      rescue ex
        STDERR.puts "[native.cr] Failed to save state: #{ex.message}"
      end
    end
  end

  protected def load_saved_state
    state_file = ENV["NATIVE_CR_STATE_FILE"]?
    
    if state_file && File.exists?(state_file)
      begin
        json = File.read(state_file)
        from_json(json)
        STDERR.puts "[native.cr] State loaded from #{state_file}"
        File.delete(state_file)
      rescue ex
        STDERR.puts "[native.cr] Failed to load state: #{ex.message}"
      end
    end
  end

  def set_background_color(r : UInt8, g : UInt8, b : UInt8) : Nil
    @bg_r = r
    @bg_g = g
    @bg_b = b
    update_background_color
  end

  def change_color(r : UInt8, g : UInt8, b : UInt8) : Nil
    set_background_color(r, g, b)
  end

  def screen_width : Int32
    @screen_width
  end

  def screen_height : Int32
    @screen_height
  end

  abstract def setup : Nil
  abstract def draw : Nil

  def on_touch_began(x : Float32, y : Float32) : Nil
  end

  def on_touch_moved(x : Float32, y : Float32) : Nil
  end

  def on_touch_ended(x : Float32, y : Float32) : Nil
  end

  def on_touch_cancelled(x : Float32, y : Float32) : Nil
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

  def renderer : Void*
    @renderer
  end

  def renderer=(value : Void*)
    @renderer = value
  end

  private def update_background_color : Nil
    {% if flag?(:android) %}
      LibAndroid.set_clear_color(@renderer, @bg_r, @bg_g, @bg_b)
    {% elsif flag?(:ios) %}
      LibIOS.set_clear_color(@renderer, @bg_r / 255.0, @bg_g / 255.0, @bg_b / 255.0)
    {% end %}
  end

  @@current : NativeApp?

  def self.current : NativeApp
    @@current.not_nil!
  end

  def self.current=(app : NativeApp)
    @@current = app
  end

  def self.start(app_class : NativeApp.class)
    app = app_class.new
    @@current = app
    app.load_saved_state
    app.setup
    
    {% if flag?(:android) %}
      # Android: C engine will call crystal_android_main
      # The app is created and ready, just need to run the event loop
      app.run
    {% elsif flag?(:ios) %}
      # iOS: Obj-C engine will call crystal_ios_main
      app.run
    {% else %}
      # Desktop: run directly
      app.run
    {% end %}
  end

  def run : Nil
    loop do
      {% if flag?(:android) %}
        # On Android, the C engine handles the event loop
        # This is a placeholder - actual loop is in native.c
        sleep 1
      {% elsif flag?(:ios) %}
        # On iOS, the Obj-C engine handles the event loop
        sleep 1
      {% else %}
        # Desktop mode - needs implementation
        sleep 0.016
      {% end %}
    end
  end
end

# ==========================================
# ANDROID ENTRY POINT - Called from native.c
# ==========================================
{% if flag?(:android) %}
  @[Export("crystal_android_main")]
  fun crystal_android_main(state : Void*) : Void
    GC.init
    app = NativeApp.current
    app.renderer = state
    app.run
  end
{% end %}

# ==========================================
# IOS ENTRY POINT - Called from Objective-C
# ==========================================
{% if flag?(:ios) %}
  @[Export("crystal_ios_main")]
  fun crystal_ios_main(state : Void*) : Void
    GC.init
    app = NativeApp.current
    app.renderer = state
    app.run
  end
{% end %}
