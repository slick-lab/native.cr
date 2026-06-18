# src/native/framework/ui/view.cr

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
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_visibility = env.get_method_id(env.get_object_class(@native), "setVisibility", "(I)V")
        env.call_void_method(@native, set_visibility, value ? 0 : 8)
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
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_enabled = env.get_method_id(env.get_object_class(@native), "setEnabled", "(Z)V")
        env.call_void_method(@native, set_enabled, value)
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
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_tag = env.get_method_id(env.get_object_class(@native), "setTag", "(Ljava/lang/Object;)V")
        env.call_void_method(@native, set_tag, env.new_string_utf(value))
      {% elsif flag?(:native_ios) %}
        LibIOS.view_set_tag(@native, value.to_utf8)
      {% end %}
    end

    def tag : String?
      @tag
    end

    protected def update_position : Nil
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_x = env.get_method_id(env.get_object_class(@native), "setX", "(F)V")
        set_y = env.get_method_id(env.get_object_class(@native), "setY", "(F)V")
        env.call_void_method(@native, set_x, @x.to_f32)
        env.call_void_method(@native, set_y, @y.to_f32)
      {% elsif flag?(:native_ios) %}
        LibIOS.view_set_position(@native, @x, @y)
      {% end %}
    end

    protected def update_size : Nil
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        layout_params = env.get_method_id(env.get_object_class(@native), "getLayoutParams", "()Landroid/view/ViewGroup$LayoutParams;")
        params = env.call_object_method(@native, layout_params)
        if params
          set_width = env.get_field_id(env.get_object_class(params), "width", "I")
          set_height = env.get_field_id(env.get_object_class(params), "height", "I")
          env.set_int_field(params, set_width, @width)
          env.set_int_field(params, set_height, @height)
          set_layout = env.get_method_id(env.get_object_class(@native), "setLayoutParams", "(Landroid/view/ViewGroup$LayoutParams;)V")
          env.call_void_method(@native, set_layout, params)
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
        env = Native::Android::JNI.env
        return unless env && @native != 0
        argb = (255 << 24) | ((color.r * 255).to_i << 16) | ((color.g * 255).to_i << 8) | (color.b * 255).to_i
        set_bg = env.get_method_id(env.get_object_class(@native), "setBackgroundColor", "(I)V")
        env.call_void_method(@native, set_bg, argb)
      {% elsif flag?(:native_ios) %}
        LibIOS.view_set_background_color(@native, color.r, color.g, color.b, color.a)
      {% end %}
    end
  end
end
