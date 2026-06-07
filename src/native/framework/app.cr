require "json"
require "signal"

module Native
  abstract class App
    macro inherited
      preserve
    end

    macro preserve
      {% preserve_vars = @type.instance_vars.select { |var| var.has_annotation! Preserve } %}

      def save_state
        state_file = ENV["NATIVE_CR_STATE_FILE"]?
        return unless state_file

        File.open(state_file, "w") do |file|
          {% for var in preserve_vars %}
            value = @{{var.name}}
            {% if var.type.resolve == Int32 %}
              file.puts "{{var.name}}=i:#{value}"
            {% elsif var.type.resolve == String %}
              file.puts "{{var.name}}=s:#{value}"
            {% elsif var.type.resolve == Float32 || var.type.resolve == Float64 %}
              file.puts "{{var.name}}=f:#{value}"
            {% elsif var.type.resolve == Bool %}
              file.puts "{{var.name}}=b:#{value}"
            {% else %}
              file.puts "{{var.name}}={{value}}"
            {% end %}
          {% end %}
        end
      end

      def load_state
        state_file = ENV["NATIVE_CR_STATE_FILE"]?
        return unless state_file && File.exists?(state_file)

        File.each_line(state_file) do |line|
          key, rest = line.split('=', 2)
          next unless rest

          type_char = rest[0]?
          value = rest[2..-1] if rest.size > 2
          next unless value

          case key
          {% for var in preserve_vars %}
          when "{{var.name}}"
            {% if var.type.resolve == Int32 %}
              @{{var.name}} = value.to_i
            {% elsif var.type.resolve == String %}
              @{{var.name}} = value
            {% elsif var.type.resolve == Float32 %}
              @{{var.name}} = value.to_f.to_f32
            {% elsif var.type.resolve == Float64 %}
              @{{var.name}} = value.to_f
            {% elsif var.type.resolve == Bool %}
              @{{var.name}} = value == "true"
            {% else %}
              @{{var.name}} = value
            {% end %}
          {% end %}
          end
        end
        File.delete(state_file)
      end
    end

    annotation Preserve; end

    def initialize
      @renderer = Pointer(Void).null
      @bg_r = 100_u8
      @bg_g = 100_u8
      @bg_b = 100_u8
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

    protected def load_saved_state
      load_state
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

    @[JSON::Field(ignore: true)]
    property renderer : Void*

    private def update_background_color : Nil
      {% if flag?(:android) %}
        LibAndroid.set_clear_color(@renderer, @bg_r, @bg_g, @bg_b)
      {% elsif flag?(:ios) %}
        LibIOS.set_clear_color(@renderer, @bg_r / 255.0, @bg_g / 255.0, @bg_b / 255.0)
      {% end %}
    end

    @@current : App?

    def self.current : App
      @@current.not_nil!
    end

    def self.current=(app : App)
      @@current = app
    end

    def self.start(app_class : App.class) : Nil
      app = app_class.new
      @@current = app
      app.load_saved_state
      app.setup
      app.run
    end

    def run : Nil
      loop do
        sleep 0.016
      end
    end
  end
end
