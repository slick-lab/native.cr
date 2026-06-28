@[Link("GL")]
lib LibGL
  GL_COLOR_BUFFER_BIT = 0x00004000
  GL_DEPTH_BUFFER_BIT = 0x00000100

  fun glClearColor(red : Float32, green : Float32, blue : Float32, alpha : Float32)
  fun glClear(mask : UInt32)
  fun glViewport(x : Int32, y : Int32, width : Int32, height : Int32)
end

module GL
  def self.clear_color(r : Float32, g : Float32, b : Float32, a : Float32 = 1.0f32)
    LibGL.glClearColor(r, g, b, a)
  end

  def self.clear
    LibGL.glClear(LibGL::GL_COLOR_BUFFER_BIT | LibGL::GL_DEPTH_BUFFER_BIT)
  end

  def self.viewport(x : Int32, y : Int32, w : Int32, h : Int32)
    LibGL.glViewport(x, y, w, h)
  end
end
