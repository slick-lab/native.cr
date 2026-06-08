# src/native/framework/renderer.cr

module Native::Renderer
  def self.draw_text(text : UInt8*, x : Int32, y : Int32, size : Int32, r : UInt8, g : UInt8, b : UInt8) : Nil
    {% if flag?(:android) %}
      LibAndroid.draw_text(text, x, y, size, r, g, b)
    {% elsif flag?(:ios) %}
      LibIOS.create_label(text, x, y, size, r, g, b)
    {% else %}
      LibSDL2.draw_text(text, x, y, size, r, g, b)
    {% end %}
  end

  def self.draw_rect(x : Int32, y : Int32, w : Int32, h : Int32, r : UInt8, g : UInt8, b : UInt8, a : UInt8) : Nil
    {% if flag?(:android) %}
      LibAndroid.draw_rect(x, y, w, h, r, g, b, a)
    {% elsif flag?(:ios) %}
      LibIOS.create_rect(x, y, w, h, r, g, b, a)
    {% else %}
      LibSDL2.draw_rect(x, y, w, h, r, g, b, a)
    {% end %}
  end

  def self.measure_text(text : UInt8*, size : Int32) : Int32
    {% if flag?(:android) %}
      LibAndroid.measure_text(text, size)
    {% elsif flag?(:ios) %}
      LibIOS.measure_text(text, size)
    {% else %}
      LibSDL2.measure_text(text, size)
    {% end %}
  end
end
