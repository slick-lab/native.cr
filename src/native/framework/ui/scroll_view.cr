# src/native/framework/ui/scroll_view.cr

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
          scroll_class = env.FindClass("android/widget/ScrollView")
        else
          scroll_class = env.FindClass("android/widget/HorizontalScrollView")
        end

        constructor = env.GetMethodID(scroll_class, "<init>", "(Landroid/content/Context;)V")
        @native = env.NewObject(scroll_class, constructor, activity).to_i64

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
        add_view = env.GetMethodID(env.GetObjectClass(@native), "addView", "(Landroid/view/View;)V")
        env.CallVoidMethod(@native, add_view, view.native_ptr)
      {% elsif flag?(:native_ios) %}
        LibIOS.scroll_view_add_view(@native, view.native_ptr)
      {% end %}
    end

    def removeView(view : View)
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0 && view.native_ptr != 0
        remove_view = env.GetMethodID(env.GetObjectClass(@native), "removeView", "(Landroid/view/View;)V")
        env.CallVoidMethod(@native, remove_view, view.native_ptr)
      {% elsif flag?(:native_ios) %}
        LibIOS.scroll_view_remove_view(@native, view.native_ptr)
      {% end %}
    end

    def scroll_to(x : Int32, y : Int32, animated : Bool = true)
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0

        if animated
          smooth_scroll = env.GetMethodID(env.GetObjectClass(@native), "smoothScrollTo", "(II)V")
          env.CallVoidMethod(@native, smooth_scroll, x, y)
        else
          scroll_to = env.GetMethodID(env.GetObjectClass(@native), "scrollTo", "(II)V")
          env.CallVoidMethod(@native, scroll_to, x, y)
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
        get_x = env.GetMethodID(env.GetObjectClass(@native), "getScrollX", "()I")
        env.CallIntMethod(@native, get_x)
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
        get_y = env.GetMethodID(env.GetObjectClass(@native), "getScrollY", "()I")
        env.CallIntMethod(@native, get_y)
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
        set_style = env.GetMethodID(env.GetObjectClass(@native), "setScrollBarStyle", "(I)V")
        env.CallVoidMethod(@native, set_style, value.value)
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
        get_child = env.GetMethodID(env.GetObjectClass(@native), "getChildAt", "(I)Landroid/view/View;")
        child_ptr = env.CallObjectMethod(@native, get_child, index)
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

      callback_class = env.FindClass("com/nativecr/ScrollViewCallback")
      if callback_class == Pointer(Void).null
        return
      end

      callback_obj = env.NewObject(callback_class, env.GetMethodID(callback_class, "<init>", "(J)V"), Pointer(Void).address.to_i64)

      set_listener = env.GetMethodID(env.GetObjectClass(@native), "setOnScrollChangeListener", "(Landroid/view/View$OnScrollChangeListener;)V")
      env.CallVoidMethod(@native, set_listener, callback_obj)
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
