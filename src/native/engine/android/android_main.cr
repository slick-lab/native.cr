@[Link("android_native_app_glue")]
@[Link("EGL")]
@[Link("GLESv2")]
@[Link("log")]
@[Link("c")]
lib LibAndroid
  struct android_app
    userData : Void*
    activity : Void*
    window : Void*
    onAppCmd : (Void*, Int32) -> Void
    onInputEvent : (Void*, Void*) -> Int32
    destroyRequested : Int32
    config : Void*
    savedState : Void*
    savedStateSize : UInt64
  end

  struct AInputEvent
  end

  fun android_main(state : android_app*)
  fun app_dummy()
  fun poll_events(state : android_app*) : Int32
  fun destroy_requested(state : android_app*) : Bool
  fun has_window(state : android_app*) : Bool
  fun set_color(state : android_app*, r : UInt8, g : UInt8, b : UInt8)
  fun swap_buffers(state : android_app*)
end

@[Export("crystal_android_main")]
fun crystal_android_main(state : LibAndroid::android_app*) : Void
  GC.init
  app = AndroidApp.new(state)
  app.run
end

class AndroidApp
  property color_r : UInt8
  property color_g : UInt8
  property color_b : UInt8

  def initialize(@state : LibAndroid::android_app*)
    @color_r = 100u8
    @color_g = 150u8
    @color_b = 200u8
    setup_callbacks
  end

  private def setup_callbacks : Nil
    @state.value.userData = self.as(Void*)
    @state.value.onAppCmd = ->(app : Void*, cmd : Int32) {
      app_ptr = app.as(LibAndroid::android_app*)
      android_app = app_ptr.value.userData.as(AndroidApp)
      android_app.handle_command(cmd)
    }
    @state.value.onInputEvent = ->(app : Void*, event : Void*) : Int32 {
      app_ptr = app.as(LibAndroid::android_app*)
      android_app = app_ptr.value.userData.as(AndroidApp)
      android_app.handle_input(event.as(LibAndroid::AInputEvent*))
    }
  end

  def run : Nil
    loop do
      ident = LibAndroid.poll_events(@state)
      break if LibAndroid.destroy_requested(@state)
      if LibAndroid.has_window(@state)
        draw_frame
      end
    end
  end

  def handle_command(cmd : Int32) : Nil
    case cmd
    when 1  # APP_CMD_INIT_WINDOW
      draw_frame if LibAndroid.has_window(@state)
    when 2  # APP_CMD_TERM_WINDOW
      # Window destroyed
    end
  end

  def handle_input(event : LibAndroid::AInputEvent*) : Int32
    event_type = LibAndroid.get_event_type(event)
    if event_type == 3  # AINPUT_EVENT_TYPE_MOTION
      action = LibAndroid.get_action(event)
      if action == 0 || action == 1  # DOWN or UP
        @color_r = (@color_r + 10) & 255
        @color_g = (@color_g + 20) & 255
        @color_b = (@color_b + 30) & 255
        draw_frame
        return 1
      end
    end
    0
  end

  private def draw_frame : Nil
    LibAndroid.set_color(@state, @color_r, @color_b, @color_b)
    LibAndroid.swap_buffers(@state)
  end

  def change_color(r : UInt8, g : UInt8, b : UInt8) : Nil
    @color_r = r
    @color_g = g
    @color_b = b
    draw_frame
  end
end

LibAndroid.app_dummy
