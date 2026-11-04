# src/native/engine/ios/bridge.cr

fun crystal_init : Void
  GC.init
end

fun crystal_start : Void
  app = Native::App.current
  app.load_saved_state
  app.setup
end

# NOTE: a crystal_render_frame fun referencing App#draw used to live here.
# Nothing on the Swift side ever called it, App#draw never existed, and
# the fun made any real iOS app compile fail — another "never actually
# instantiated" code path. Removed; touch events below are the live API.

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
