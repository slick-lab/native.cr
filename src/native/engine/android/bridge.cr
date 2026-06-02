@[Link("android_native_app_glue")]
@[Link("EGL")]
@[Link("GLESv2")]
@[Link("log")]
lib LibAndroid
  fun android_main(state : Void*)
end

@[Export("crystal_android_main")]
fun crystal_android_main(state : Void*) : Void
  GC.init
  app = NativeApp.new(state)
  app.run
end

class NativeApp
  def initialize(@state : Void*)
    @color_r = 100
    @color_g = 150
    @color_b = 200
  end

  def run
    loop do
      ident = poll_events
      break if should_exit?
      draw_frame if window_ready?
    end
  end

  private def poll_events : Int32
    LibAndroid.poll_events(@state)
  end

  private def should_exit? : Bool
    LibAndroid.destroy_requested(@state)
  end

  private def window_ready? : Bool
    LibAndroid.has_window(@state)
  end

  private def draw_frame : Nil
    LibAndroid.set_color(@state, @color_r, @color_g, @color_b)
    LibAndroid.swap_buffers(@state)
  end

  def change_color(r : Int32, g : Int32, b : Int32)
    @color_r = r
    @color_g = g
    @color_b = b
    draw_frame
  end
end
