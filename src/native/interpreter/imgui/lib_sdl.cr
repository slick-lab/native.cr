@[Link("SDL2")]
lib LibSDL
  SDL_INIT_VIDEO   = 0x00000020_u32
  SDL_INIT_EVENTS  = 0x00004000_u32

  SDL_WINDOW_OPENGL        = 0x00000002_u32
  SDL_WINDOW_RESIZABLE     = 0x00000020_u32
  SDL_WINDOW_SHOWN         = 0x00000004_u32
  SDL_WINDOW_ALLOW_HIGHDPI = 0x00002000_u32

  SDL_WINDOWPOS_CENTERED = 0x2FFF0000_i32

  SDL_GL_CONTEXT_MAJOR_VERSION = 17
  SDL_GL_CONTEXT_MINOR_VERSION = 18
  SDL_GL_CONTEXT_PROFILE_MASK  = 21
  SDL_GL_CONTEXT_PROFILE_CORE  = 0x0001
  SDL_GL_DOUBLEBUFFER          = 5
  SDL_GL_DEPTH_SIZE            = 6
  SDL_GL_STENCIL_SIZE          = 13

  SDL_QUIT            = 0x100
  SDL_KEYDOWN         = 0x300
  SDL_KEYUP           = 0x301
  SDL_MOUSEMOTION     = 0x400
  SDL_MOUSEBUTTONDOWN = 0x401
  SDL_MOUSEBUTTONUP   = 0x402
  SDL_MOUSEWHEEL      = 0x403
  SDL_TEXTINPUT       = 0x303
  SDL_WINDOWEVENT     = 0x200

  SDLK_ESCAPE = 27
  SDLK_RETURN = 13

  struct KeySym
    scancode : Int32
    sym      : Int32
    mod      : UInt16
    unused   : UInt32
  end

  struct KeyboardEvent
    type      : UInt32
    timestamp : UInt32
    window_id : UInt32
    state     : UInt8
    repeat    : UInt8
    padding2  : UInt8
    padding3  : UInt8
    keysym    : KeySym
  end

  struct MouseMotionEvent
    type      : UInt32
    timestamp : UInt32
    window_id : UInt32
    which     : UInt32
    state     : UInt32
    x         : Int32
    y         : Int32
    xrel      : Int32
    yrel      : Int32
  end

  struct MouseButtonEvent
    type      : UInt32
    timestamp : UInt32
    window_id : UInt32
    which     : UInt32
    button    : UInt8
    state     : UInt8
    clicks    : UInt8
    padding1  : UInt8
    x         : Int32
    y         : Int32
  end

  struct MouseWheelEvent
    type      : UInt32
    timestamp : UInt32
    window_id : UInt32
    which     : UInt32
    x         : Int32
    y         : Int32
    direction : UInt32
    preciseX  : Float32
    preciseY  : Float32
  end

  struct TextInputEvent
    type      : UInt32
    timestamp : UInt32
    window_id : UInt32
    text      : UInt8[32]
  end

  struct WindowEvent
    type      : UInt32
    timestamp : UInt32
    window_id : UInt32
    event     : UInt8
    padding1  : UInt8
    padding2  : UInt8
    padding3  : UInt8
    data1     : Int32
    data2     : Int32
  end

  struct QuitEvent
    type      : UInt32
    timestamp : UInt32
  end

  union Event
    type     : UInt32
    key      : KeyboardEvent
    motion   : MouseMotionEvent
    button   : MouseButtonEvent
    wheel    : MouseWheelEvent
    text     : TextInputEvent
    window   : WindowEvent
    quit     : QuitEvent
    padding  : UInt8[56]
  end

  fun SDL_Init(flags : UInt32) : Int32
  fun SDL_Quit()
  fun SDL_GetError() : UInt8*
  fun SDL_CreateWindow(title : UInt8*, x : Int32, y : Int32, w : Int32, h : Int32, flags : UInt32) : Void*
  fun SDL_DestroyWindow(window : Void*)
  fun SDL_GL_SetAttribute(attr : Int32, value : Int32) : Int32
  fun SDL_GL_CreateContext(window : Void*) : Void*
  fun SDL_GL_DeleteContext(context : Void*)
  fun SDL_GL_SwapWindow(window : Void*)
  fun SDL_GL_SetSwapInterval(interval : Int32) : Int32
  fun SDL_PollEvent(event : Event*) : Int32
  fun SDL_GetWindowSize(window : Void*, w : Int32*, h : Int32*)
  fun SDL_SetWindowTitle(window : Void*, title : UInt8*)
  fun SDL_Delay(ms : UInt32)
end

module SDL
  def self.init_video
    LibSDL.SDL_Init(LibSDL::SDL_INIT_VIDEO | LibSDL::SDL_INIT_EVENTS)
  end

  def self.quit
    LibSDL.SDL_Quit
  end

  def self.get_error : String
    String.new(LibSDL.SDL_GetError)
  end

  def self.create_window(title : String, w : Int32, h : Int32) : Void*
    flags = LibSDL::SDL_WINDOW_OPENGL |
            LibSDL::SDL_WINDOW_RESIZABLE |
            LibSDL::SDL_WINDOW_SHOWN |
            LibSDL::SDL_WINDOW_ALLOW_HIGHDPI
    LibSDL.SDL_CreateWindow(
      title,
      LibSDL::SDL_WINDOWPOS_CENTERED,
      LibSDL::SDL_WINDOWPOS_CENTERED,
      w, h, flags
    )
  end

  def self.destroy_window(window : Void*)
    LibSDL.SDL_DestroyWindow(window)
  end

  def self.setup_gl_attributes
    LibSDL.SDL_GL_SetAttribute(LibSDL::SDL_GL_CONTEXT_PROFILE_MASK, LibSDL::SDL_GL_CONTEXT_PROFILE_CORE)
    LibSDL.SDL_GL_SetAttribute(LibSDL::SDL_GL_CONTEXT_MAJOR_VERSION, 3)
    LibSDL.SDL_GL_SetAttribute(LibSDL::SDL_GL_CONTEXT_MINOR_VERSION, 0)
    LibSDL.SDL_GL_SetAttribute(LibSDL::SDL_GL_DOUBLEBUFFER, 1)
    LibSDL.SDL_GL_SetAttribute(LibSDL::SDL_GL_DEPTH_SIZE, 24)
    LibSDL.SDL_GL_SetAttribute(LibSDL::SDL_GL_STENCIL_SIZE, 8)
  end

  def self.gl_create_context(window : Void*) : Void*
    LibSDL.SDL_GL_CreateContext(window)
  end

  def self.gl_delete_context(ctx : Void*)
    LibSDL.SDL_GL_DeleteContext(ctx)
  end

  def self.gl_swap_window(window : Void*)
    LibSDL.SDL_GL_SwapWindow(window)
  end

  def self.gl_set_swap_interval(interval : Int32)
    LibSDL.SDL_GL_SetSwapInterval(interval)
  end

  def self.poll_event : LibSDL::Event?
    event = LibSDL::Event.new
    return event if LibSDL.SDL_PollEvent(pointerof(event)) != 0
    nil
  end

  def self.get_window_size(window : Void*) : {Int32, Int32}
    w = 0
    h = 0
    LibSDL.SDL_GetWindowSize(window, pointerof(w), pointerof(h))
    {w, h}
  end

  def self.set_window_title(window : Void*, title : String)
    LibSDL.SDL_SetWindowTitle(window, title)
  end

  def self.delay(ms : UInt32)
    LibSDL.SDL_Delay(ms)
  end
end
