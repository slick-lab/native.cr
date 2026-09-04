# src/native/framework/ui/scroll_view.cr
# Refactored to use JNIHelpers for automatic local reference cleanup.

module Native::UI
  class ScrollView < View
    enum ScrollDirection
      Vertical
      Horizontal
    end

    enum ScrollBarStyle
      InsideOverlay
      InsideInset
      OutsideInset
    end

    @direction : ScrollDirection = ScrollDirection::Vertical
    @scroll_bar_style : ScrollBarStyle = ScrollBarStyle::InsideOverlay
    @scroll_bar_fade_duration : Int32 = 250
    @scroll_bar_size : Int32 = 4
    @is_scrolling : Bool = false
    @on_scroll_changed : (Int32, Int32 -> Nil)?
    @on_scroll_state_changed : (Bool -> Nil)?

    def initialize(direction : ScrollDirection = ScrollDirection::Vertical)
      super()

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        if direction == ScrollDirection::Vertical
          scroll_class = env.find_class("android/widget/ScrollView")
        else
          scroll_class = env.find_class("android/widget/HorizontalScrollView")
        end

        constructor = env.get_method_id(scroll_class, "<init>", "(Landroid/content/Context;)V")
        @native = env.new_object(scroll_class, constructor, activity).to_i64
        env.delete_local_ref(scroll_class) unless scroll_class.null?

        setupScrollListener
      {% elsif flag?(:native_ios) %}
        ptr = LibIOS.create_scroll_view
        @native = ptr.to_i64
        LibIOS.scroll_view_set_direction(@native, direction == ScrollDirection::Vertical ? 0 : 1)
      {% end %}
    end

    def addView(view : View)
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0 && view.native_ptr != 0
        JNIHelpers.call_void(env, @native, "addView", "(Landroid/view/View;)V", , view.native_ptr)
      {% elsif flag?(:native_ios) %}
        LibIOS.scroll_view_add_view(@native, view.native_ptr)
      {% end %}
    end

    def removeView(view : View)
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0 && view.native_ptr != 0
        JNIHelpers.call_void(env, @native, "removeView", "(Landroid/view/View;)V", , view.native_ptr)
      {% elsif flag?(:native_ios) %}
        LibIOS.scroll_view_remove_view(@native, view.native_ptr)
      {% end %}
    end

    def scroll_to(x : Int32, y : Int32, animated : Bool = true)
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0

        if animated
          JNIHelpers.call_void(env, @native, "smoothScrollTo", "(II)V", , x, y)
        else
          JNIHelpers.call_void(env, @native, "scrollTo", "(II)V", x, y)
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.scroll_view_scroll_to(@native, x, y, animated)
      {% end %}
    end

    def scroll_to_bottom(animated : Bool = true)
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0

        child = getChildAt(0)
        if child
          bottom = child.height - height
          scroll_to(0, bottom, animated)
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.scroll_view_scroll_to_bottom(@native, animated)
      {% end %}
    end

    def scroll_to_top(animated : Bool = true)
      scroll_to(0, 0, animated)
    end

    def scroll_x : Int32
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return 0 unless env && @native != 0
        JNIHelpers.call_int(env, @native, "getScrollX", "()I")
      {% elsif flag?(:native_ios) %}
        LibIOS.scroll_view_get_scroll_x(@native)
      {% else %}
        0
      {% end %}
    end

    def scroll_y : Int32
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return 0 unless env && @native != 0
        JNIHelpers.call_int(env, @native, "getScrollY", "()I")
      {% elsif flag?(:native_ios) %}
        LibIOS.scroll_view_get_scroll_y(@native)
      {% else %}
        0
      {% end %}
    end

    def max_scroll_x : Int32
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return 0 unless env && @native != 0
        child = getChildAt(0)
        child ? child.width - width : 0
      {% else %}
        0
      {% end %}
    end

    def max_scroll_y : Int32
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return 0 unless env && @native != 0
        child = getChildAt(0)
        child ? child.height - height : 0
      {% else %}
        0
      {% end %}
    end

    def scroll_bar_style=(value : ScrollBarStyle)
      @scroll_bar_style = value
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        JNIHelpers.call_void(env, @native, "setScrollBarStyle", "(I)V", , value.value)
      {% end %}
    end

    def scroll_bar_style : ScrollBarStyle
      @scroll_bar_style
    end

    def is_scrolling? : Bool
      @is_scrolling
    end

    def on_scroll_changed(&block : Int32, Int32 -> Nil)
      @on_scroll_changed = block
    end

    def on_scroll_state_changed(&block : Bool -> Nil)
      @on_scroll_state_changed = block
    end

    private def getChildAt(index : Int32) : View?
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return nil unless env && @native != 0
        get_child = env.get_method_id(env.get_object_class(@native), "getChildAt", "(I)Landroid/view/View;")
        child_ptr = env.call_object_method(@native, get_child, index)
        if child_ptr != Pointer(Void).null
          view = View.new
          view.native = child_ptr.to_i64
          view
        else
          nil
        end
      {% else %}
        nil
      {% end %}
    end

    private def setupScrollListener
      {% unless flag?(:native_android) %}
        return
      {% end %}
      env = Native::Android::JNI.env
      return unless env && @native != 0

      callback_class = env.find_class("com/nativecr/ScrollViewCallback")
      if callback_class == Pointer(Void).null
        return
      end

      callback_obj = env.new_object(callback_class, env.get_method_id(callback_class, "<init>", "(J)V"), 0i64)
      env.delete_local_ref(callback_class) unless callback_class.null?

      JNIHelpers.call_void(env, @native, "setOnScrollChangeListener", "(Landroid/view/View$OnScrollChangeListener;)V", , callback_obj)
    end

    def handleScrollChanged(x : Int32, y : Int32)
      @on_scroll_changed.try &.call(x, y)
    end

    def handleScrollStateChanged(scrolling : Bool)
      @is_scrolling = scrolling
      @on_scroll_state_changed.try &.call(scrolling)
    end
  end
end
