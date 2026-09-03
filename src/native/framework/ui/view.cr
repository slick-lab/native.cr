# src/native/framework/ui/view.cr
# Refactored to use JNIHelpers for automatic local reference cleanup.

module Native::UI
  class View
    @native : Int64 = 0
    @x : Int32 = 0
    @y : Int32 = 0
    @width : Int32 = 0
    @height : Int32 = 0
    @visible : Bool = true
    @enabled : Bool = true
    @tag : String? = nil

    def x : Int32
      @x
    end

    def x=(value : Int32)
      @x = value
      update_position
    end

    def y : Int32
      @y
    end

    def y=(value : Int32)
      @y = value
      update_position
    end

    def width : Int32
      @width
    end

    def width=(value : Int32)
      @width = value
      update_size
    end

    def height : Int32
      @height
    end

    def height=(value : Int32)
      @height = value
      update_size
    end

    def visible=(value : Bool)
      @visible = value
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0
          JNIHelpers.set_visibility(env, @native, value)
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.view_set_visible(@native, value)
      {% end %}
    end

    def visible? : Bool
      @visible
    end

    def enabled=(value : Bool)
      @enabled = value
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0
          JNIHelpers.set_enabled(env, @native, value)
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.view_set_enabled(@native, value)
      {% end %}
    end

    def enabled? : Bool
      @enabled
    end

    def tag=(value : String)
      @tag = value
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0
          JNIHelpers.set_tag(env, @native, value)
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.view_set_tag(@native, value.to_utf8)
      {% end %}
    end

    def tag : String?
      @tag
    end

    protected def update_position : Nil
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0
          JNIHelpers.set_position(env, @native, @x, @y)
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.view_set_position(@native, @x, @y)
      {% end %}
    end

    protected def update_size : Nil
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0
          JNIHelpers.set_layout_params_size(env, @native, @width, @height)
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.view_set_size(@native, @width, @height)
      {% end %}
    end

    def native_ptr : Int64
      @native
    end

    def background_color=(color : Native::Math::Color)
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0
          argb = argb_from_color(color)
          JNIHelpers.set_background_color(env, @native, argb)
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.view_set_background_color(@native, color.r, color.g, color.b, color.a)
      {% end %}
    end

    private def argb_from_color(color : Native::Math::Color) : Int32
      (255 << 24) |
      ((color.r * 255).to_i << 16) |
      ((color.g * 255).to_i << 8) |
      (color.b * 255).to_i
    end
  end
end
