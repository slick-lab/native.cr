# src/native/engine/ios/bridge.cr

@[Link("objc")]
@[Link("Foundation")]
@[Link("UIKit")]
@[Link("Metal")]
@[Link("QuartzCore")]
lib LibIOS
  type CGFloat = Float64
  type CGPoint = Struct(x: CGFloat, y: CGFloat)
  type CGSize = Struct(width: CGFloat, height: CGFloat)
  type CGRect = Struct(origin: CGPoint, size: CGSize)

  fun UIApplicationMain(argc: Int32, argv: UInt8**, principalClassName: UInt8*, delegateClassName: UInt8*) : Int32
end

@[Link("native_cr_renderer")]
lib LibRenderer
  fun renderer_create(layer : Void*) : Void*
  fun renderer_render(renderer : Void*) : Void
  fun renderer_set_color(renderer : Void*, r : Float32, g : Float32, b : Float32) : Void
end

@[Export("ios_app_main")]
fun ios_app_main : Void
  GC.init
  app = IOSApp.new
  app.run
end

@[Export("ios_render_frame")]
fun ios_render_frame : Void
  IOSApp.current.try(&.render_frame)
end

@[Export("ios_handle_touch")]
fun ios_handle_touch(x : Float32, y : Float32, action : Int32) : Void
  IOSApp.current.try(&.handle_touch(x, y, action))
end

class IOSApp
  class_getter current : IOSApp?

  @renderer : Void*
  @color_r : Float32 = 0.39
  @color_g : Float32 = 0.59
  @color_b : Float32 = 0.78

  def initialize
    @@current = self
    @renderer = LibRenderer.renderer_create(nil)
    LibRenderer.renderer_set_color(@renderer, @color_r, @color_g, @color_b)
  end

  def run : Nil
    loop do
      NSRunLoop.NSDefaultRunLoopMode
      # Run loop handled by iOS
    end
  end

  def render_frame : Nil
    LibRenderer.renderer_render(@renderer)
  end

  def handle_touch(x : Float32, y : Float32, action : Int32) : Nil
    # action: 0 = began, 1 = moved, 2 = ended
    @color_r = (@color_r + 0.05) % 1.0
    @color_g = (@color_g + 0.10) % 1.0
    @color_b = (@color_b + 0.15) % 1.0
    LibRenderer.renderer_set_color(@renderer, @color_r, @color_g, @color_b)
  end

  def change_color(r : Float32, g : Float32, b : Float32) : Nil
    @color_r = r
    @color_g = g
    @color_b = b
    LibRenderer.renderer_set_color(@renderer, r, g, b)
  end
end

module NSRunLoop
  def self.NSDefaultRunLoopMode : String
    "kCFRunLoopDefaultMode"
  end
end
