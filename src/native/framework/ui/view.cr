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

    private def argb_from_color(color : Native::Math::Color) : Int32
      (255 << 24) |
      ((color.r * 255).to_i << 16) |
      ((color.g * 255).to_i << 8) |
      (color.b * 255).to_i
    end

    # ── Corner rounding DSL ──────────────────────────────────────────────────
    # `corner_radius = 24` (uniform) or `corner_radius = CornerRadius.all(24)`.
    # Android: GradientDrawable recreated with the current background color
    # so the shape survives reassignment; iOS: CALayer cornerRadius (uniform —
    # per-corner values use the max); desktop: stored for introspection.

    @corner_radius : CornerRadius = CornerRadius.new

    def corner_radius : CornerRadius
      @corner_radius
    end

    def corner_radius=(value : Int32 | Float32)
      self.corner_radius = CornerRadius.all(value)
    end

    def corner_radius=(value : CornerRadius)
      @corner_radius = value
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0
          JNIHelpers.with_class(env, "android/graphics/drawable/GradientDrawable") do |klass|
            next if klass.null?
            new_m = env.get_method_id(klass, "<init>", "()V")
            set_radius = env.get_method_id(klass, "setCornerRadius", "(F)V")
            set_color = env.get_method_id(klass, "setColor", "(I)V")
            next if new_m.null? || set_radius.null? || set_color.null?
            drawable = env.new_object(klass, new_m)
            next if drawable.null?
            env.call_void_method(drawable, set_radius, value.max)
            bg = argb_from_color(@bg_color || Native::Math::Color.new(0.0, 0.0, 0.0, 0.0))
            env.call_void_method(drawable, set_color, bg)
            set_bg = env.get_method_id(env.get_object_class(@native), "setBackground", "(Landroid/graphics/drawable/Drawable;)V")
            unless set_bg.null?
              env.call_void_method(@native, set_bg, drawable)
            end
            env.delete_local_ref(drawable)
          end
        end
      {% elsif flag?(:native_ios) %}
        if value.uniform?
          LibIOS.view_set_corner_radius(@native, value.max) if @native != 0
        else
          # CALayer can do per-corner via maskedCorners; uniform-max keeps
          # the API honest until per-corner lands.
          LibIOS.view_set_corner_radius(@native, value.max) if @native != 0
        end
      {% end %}
    end

    @bg_color : Native::Math::Color? = nil

    def background_color=(color : Native::Math::Color)
      @bg_color = color
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0
          if @corner_radius.max > 0
            # Reapply the rounded background with the new color instead of
            # overwriting the GradientDrawable with a flat one.
            self.corner_radius = @corner_radius
          else
            argb = argb_from_color(color)
            JNIHelpers.set_background_color(env, @native, argb)
          end
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.view_set_background_color(@native, color.r.to_f32, color.g.to_f32, color.b.to_f32, color.a.to_f32)
      {% end %}
    end
  end
end
