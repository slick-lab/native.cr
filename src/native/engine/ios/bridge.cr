# src/native/engine/ios/bridge.cr

fun crystal_init : Void
  GC.init
end

fun crystal_start : Void
  app = Native::App.current
  app.load_saved_state
  app.setup
end

fun crystal_render_frame : Void
  app = Native::App.current
  app.draw
end

fun crystal_touch_began(x : Float32, y : Float32) : Void
  app = Native::App.current
  app.on_touch_began(x, y)
end

fun crystal_touch_moved(x : Float32, y : Float32) : Void
  app = Native::App.current
  app.on_touch_moved(x, y)
end

fun crystal_touch_ended(x : Float32, y : Float32) : Void
  app = Native::App.current
  app.on_touch_ended(x, y)
end
