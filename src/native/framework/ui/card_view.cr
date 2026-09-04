# src/native/framework/ui/card_view.cr
# Refactored to use JNIHelpers for automatic local reference cleanup.

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

        card_class = env.find_class("androidx/cardview/widget/CardView")
        constructor = env.get_method_id(card_class, "<init>", "(Landroid/content/Context;)V")
        @native = env.new_object(card_class, constructor, activity).to_i64
        env.delete_local_ref(card_class) unless card_class.null?

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
        JNIHelpers.call_void(env, @native, "setContentPadding", "(IIII)V", value, value, value, value)
      {% end %}
    end

    def content_padding : Int32
      @content_padding
    end

    def addView(view : View)
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0 && view.native_ptr != 0
        JNIHelpers.call_void(env, @native, "addView", "(Landroid/view/View;)V", view.native_ptr)
      {% elsif flag?(:native_ios) %}
        LibIOS.card_view_add_subview(@native, view.native_ptr)
      {% end %}
    end

    def removeView(view : View)
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0 && view.native_ptr != 0
        JNIHelpers.call_void(env, @native, "removeView", "(Landroid/view/View;)V", view.native_ptr)
      {% elsif flag?(:native_ios) %}
        LibIOS.card_view_remove_subview(@native, view.native_ptr)
      {% end %}
    end

    private def applyCardElevation
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        JNIHelpers.call_void(env, @native, "setCardElevation", "(F)V", @card_elevation)
      {% elsif flag?(:native_ios) %}
        LibIOS.card_view_set_elevation(@native, @card_elevation)
      {% end %}
    end

    private def applyCardRadius
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        JNIHelpers.call_void(env, @native, "setRadius", "(F)V", @card_radius)
      {% elsif flag?(:native_ios) %}
        LibIOS.card_view_set_radius(@native, @card_radius)
      {% end %}
    end

    def background_color=(color : Native::Math::Color)
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        argb = (255 << 24) | ((color.r * 255).to_i << 16) | ((color.g * 255).to_i << 8) | (color.b * 255).to_i
        JNIHelpers.call_void(env, @native, "setCardBackgroundColor", "(I)V", argb)
      {% elsif flag?(:native_ios) %}
        LibIOS.card_view_set_background_color(@native, color.r, color.g, color.b)
      {% end %}
    end
  end
end
