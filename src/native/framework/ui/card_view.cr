# src/native/framework/ui/card_view.cr

module Native::UI
  class CardView < View
    @card_elevation : Float32 = 2.0
    @card_radius : Float32 = 8.0
    @content_padding : Int32 = 16

    def initialize
      super()

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        card_class = env.FindClass("androidx/cardview/widget/CardView")
        constructor = env.GetMethodID(card_class, "<init>", "(Landroid/content/Context;)V")
        @native = env.NewObject(card_class, constructor, activity).to_i64

        applyCardElevation
        applyCardRadius
      {% elsif flag?(:native_ios) %}
        ptr = LibIOS.create_card_view
        @native = ptr.to_i64
        applyCardElevation
        applyCardRadius
      {% end %}
    end

    def elevation=(value : Float32)
      @card_elevation = value
      applyCardElevation
    end

    def elevation : Float32
      @card_elevation
    end

    def radius=(value : Float32)
      @card_radius = value
      applyCardRadius
    end

    def radius : Float32
      @card_radius
    end

    def content_padding=(value : Int32)
      @content_padding = value
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_padding = env.GetMethodID(env.GetObjectClass(@native), "setContentPadding", "(IIII)V")
        env.CallVoidMethod(@native, set_padding, value, value, value, value)
      {% end %}
    end

    def content_padding : Int32
      @content_padding
    end

    def addView(view : View)
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0 && view.native_ptr != 0
        add_view = env.GetMethodID(env.GetObjectClass(@native), "addView", "(Landroid/view/View;)V")
        env.CallVoidMethod(@native, add_view, view.native_ptr)
      {% elsif flag?(:native_ios) %}
        LibIOS.card_view_add_subview(@native, view.native_ptr)
      {% end %}
    end

    def removeView(view : View)
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0 && view.native_ptr != 0
        remove_view = env.GetMethodID(env.GetObjectClass(@native), "removeView", "(Landroid/view/View;)V")
        env.CallVoidMethod(@native, remove_view, view.native_ptr)
      {% elsif flag?(:native_ios) %}
        LibIOS.card_view_remove_subview(@native, view.native_ptr)
      {% end %}
    end

    private def applyCardElevation
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_elevation = env.GetMethodID(env.GetObjectClass(@native), "setCardElevation", "(F)V")
        env.CallVoidMethod(@native, set_elevation, @card_elevation)
      {% elsif flag?(:native_ios) %}
        LibIOS.card_view_set_elevation(@native, @card_elevation)
      {% end %}
    end

    private def applyCardRadius
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_radius = env.GetMethodID(env.GetObjectClass(@native), "setRadius", "(F)V")
        env.CallVoidMethod(@native, set_radius, @card_radius)
      {% elsif flag?(:native_ios) %}
        LibIOS.card_view_set_radius(@native, @card_radius)
      {% end %}
    end

    def background_color=(color : Native::Math::Color)
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        argb = (255 << 24) | ((color.r * 255).to_i << 16) | ((color.g * 255).to_i << 8) | (color.b * 255).to_i
        set_bg = env.GetMethodID(env.GetObjectClass(@native), "setCardBackgroundColor", "(I)V")
        env.CallVoidMethod(@native, set_bg, argb)
      {% elsif flag?(:native_ios) %}
        LibIOS.card_view_set_background_color(@native, color.r, color.g, color.b)
      {% end %}
    end
  end
end
