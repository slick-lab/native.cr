# src/native/framework/app.cr

module Native
  abstract class App
    @@current : App?

    def self.current : App
      @@current.not_nil!
    end

    def self.current=(app : App)
      @@current = app
    end

    def self.start(app_class : App.class)
      app = app_class.new
      @@current = app
      app.load_saved_state
      app.setup
    end

    def initialize
      @renderer = Pointer(Void).null
      setup_signal_handlers
    end

    private def setup_signal_handlers
      Signal::USR1.trap { save_state }
      Signal::TERM.trap { save_state; exit(0) }
    end

    private def save_state
      state_file = ENV["NATIVE_CR_STATE_FILE"]?
      return unless state_file
      File.write(state_file, state_to_json)
    rescue
    end

    def load_saved_state
      state_file = ENV["NATIVE_CR_STATE_FILE"]?
      return unless state_file && File.exists?(state_file)
      json = File.read(state_file)
      state_from_json(json)
      File.delete(state_file)
    rescue
    end

    def state_to_json : String
      "{}"
    end

    def state_from_json(json : String) : Nil
    end

    abstract def setup : Nil

    def run : Nil
      loop do
        sleep 0.016
      end
    end

    # Optional callbacks (stub methods)
    def on_touch_began(x : Float32, y : Float32) : Nil; end

    def on_touch_moved(x : Float32, y : Float32) : Nil; end

    def on_touch_ended(x : Float32, y : Float32) : Nil; end

    def on_key_pressed(key : Int32) : Nil; end

    def on_key_released(key : Int32) : Nil; end

    def on_pause : Nil; end

    def on_resume : Nil; end

    def on_destroy : Nil; end

    property renderer : Void*
  end
end
