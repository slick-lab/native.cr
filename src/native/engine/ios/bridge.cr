# src/native/engine/ios/bridge.cr

@[Export("crystal_init")]
fun crystal_init : Void
  GC.init
end

@[Export("crystal_start")]
fun crystal_start : Void
  app = Native::App.current
  app.load_saved_state
  app.setup
end

@[Export("crystal_render_frame")]
fun crystal_render_frame : Void
  app = Native::App.current
  app.draw
end

@[Export("crystal_touch_began")]
fun crystal_touch_began(x : Float32, y : Float32) : Void
  app = Native::App.current
  app.on_touch_began(x, y)
end

@[Export("crystal_touch_moved")]
fun crystal_touch_moved(x : Float32, y : Float32) : Void
  app = Native::App.current
  app.on_touch_moved(x, y)
end

@[Export("crystal_touch_ended")]
fun crystal_touch_ended(x : Float32, y : Float32) : Void
  app = Native::App.current
  app.on_touch_ended(x, y)
end
