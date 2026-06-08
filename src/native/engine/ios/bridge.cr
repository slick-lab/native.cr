# src/native/engine/ios/bridge.cr

@[Link("objc")]
@[Link("Foundation")]
@[Link("UIKit")]
@[Link("Metal")]
@[Link("QuartzCore")]
lib LibIOS
  fun UIApplicationMain(argc: Int32, argv: UInt8**, principalClassName: UInt8*, delegateClassName: UInt8*) : Int32
end

@[Export("ios_app_main")]
fun ios_app_main : Void
  GC.init
  Native::App.current.run
end

@[Export("ios_render_frame")]
fun ios_render_frame : Void
  if app = Native::App.current?
    app.draw
  end
end

@[Export("ios_handle_touch")]
fun ios_handle_touch(x : Float32, y : Float32, action : Int32) : Void
  if app = Native::App.current?
    case action
    when 0
      app.on_touch_began(x, y)
    when 1
      app.on_touch_moved(x, y)
    when 2
      app.on_touch_ended(x, y)
    end
  end
end
