# src/native/framework/ui.cr

module Native::UI
  abstract class View
    @native : Int64 = 0
    @x : Int32 = 0
    @y : Int32 = 0
    @width : Int32 = 0
    @height : Int32 = 0
    @visible : Bool = true

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
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_visibility = env.GetMethodID(env.GetObjectClass(@native), "setVisibility", "(I)V")
        env.CallVoidMethod(@native, set_visibility, value ? 0 : 8)
      elsif Native::Platform.ios?
        LibIOS.view_set_visible(@native, value)
      end
    end

    def visible? : Bool
      @visible
    end

    protected def update_position : Nil
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_x = env.GetMethodID(env.GetObjectClass(@native), "setX", "(F)V")
        set_y = env.GetMethodID(env.GetObjectClass(@native), "setY", "(F)V")
        env.CallVoidMethod(@native, set_x, @x.to_f32)
        env.CallVoidMethod(@native, set_y, @y.to_f32)
      elsif Native::Platform.ios?
        LibIOS.view_set_position(@native, @x, @y)
      end
    end

    protected def update_size : Nil
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        layout_params = env.GetMethodID(env.GetObjectClass(@native), "getLayoutParams", "()Landroid/view/ViewGroup$LayoutParams;")
        params = env.CallObjectMethod(@native, layout_params)
        if params
          set_width = env.GetFieldID(env.GetObjectClass(params), "width", "I")
          set_height = env.GetFieldID(env.GetObjectClass(params), "height", "I")
          env.SetIntField(params, set_width, @width)
          env.SetIntField(params, set_height, @height)
          set_layout = env.GetMethodID(env.GetObjectClass(@native), "setLayoutParams", "(Landroid/view/ViewGroup$LayoutParams;)V")
          env.CallVoidMethod(@native, set_layout, params)
        end
      elsif Native::Platform.ios?
        LibIOS.view_set_size(@native, @width, @height)
      end
    end

    def native_ptr : Int64
      @native
    end
  end

  class TextView < View
    def initialize(text : String = "")
      if Native::Platform.android?
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        text_view_class = env.FindClass("android/widget/TextView")
        constructor = env.GetMethodID(text_view_class, "<init>", "(Landroid/content/Context;)V")
        @native = env.NewObject(text_view_class, constructor, activity).to_i64

        if !text.empty?
          setText(text)
        end
      elsif Native::Platform.ios?
        ptr = LibIOS.create_label
        @native = ptr.to_i64
        if !text.empty?
          setText(text)
        end
      end
    end

    def setText(text : String) : Nil
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        jtext = env.NewStringUTF(text)
        set_text_method = env.GetMethodID(env.GetObjectClass(@native), "setText", "(Ljava/lang/CharSequence;)V")
        env.CallVoidMethod(@native, set_text_method, jtext)
      elsif Native::Platform.ios?
        LibIOS.label_set_text(@native, text.to_utf8)
      end
    end

    def setTextSize(size : Int32) : Nil
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_text_size = env.GetMethodID(env.GetObjectClass(@native), "setTextSize", "(F)V")
        env.CallVoidMethod(@native, set_text_size, size.to_f32)
      elsif Native::Platform.ios?
        LibIOS.label_set_text_size(@native, size)
      end
    end

    def setTextColor(r : Int32, g : Int32, b : Int32) : Nil
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        color = (0xFF << 24) | ((r & 0xFF) << 16) | ((g & 0xFF) << 8) | (b & 0xFF)
        set_color = env.GetMethodID(env.GetObjectClass(@native), "setTextColor", "(I)V")
        env.CallVoidMethod(@native, set_color, color)
      elsif Native::Platform.ios?
        LibIOS.label_set_text_color(@native, r, g, b)
      end
    end

    def text : String
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return "" unless env && @native != 0
        get_text = env.GetMethodID(env.GetObjectClass(@native), "getText", "()Ljava/lang/CharSequence;")
        result = env.CallObjectMethod(@native, get_text)
        if result
          str = env.GetStringUTFChars(result, nil).to_s
          env.DeleteLocalRef(result)
          str
        else
          ""
        end
      elsif Native::Platform.ios?
        ptr = LibIOS.label_get_text(@native)
        if ptr
          result = String.new(ptr)
          LibIOS.free_string(ptr)
          result
        else
          ""
        end
      else
        ""
      end
    end
  end

  class Button < View
    @on_click_callback : -> Nil?

    def initialize(text : String = "")
      if Native::Platform.android?
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        button_class = env.FindClass("android/widget/Button")
        constructor = env.GetMethodID(button_class, "<init>", "(Landroid/content/Context;)V")
        @native = env.NewObject(button_class, constructor, activity).to_i64

        if !text.empty?
          setText(text)
        end
      elsif Native::Platform.ios?
        ptr = LibIOS.create_button
        @native = ptr.to_i64
        if !text.empty?
          setText(text)
        end
      end
    end

    def setText(text : String) : Nil
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        jtext = env.NewStringUTF(text)
        set_text_method = env.GetMethodID(env.GetObjectClass(@native), "setText", "(Ljava/lang/CharSequence;)V")
        env.CallVoidMethod(@native, set_text_method, jtext)
      elsif Native::Platform.ios?
        LibIOS.button_set_text(@native, text.to_utf8)
      end
    end

    def setOnClickListener(&block : -> Nil) : Nil
      @on_click_callback = block

      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0

        callback_class = env.FindClass("com/nativecr/OnClickCallback")
        if callback_class == Pointer(Void).null
          return
        end

        callback_obj = env.NewObject(callback_class, env.GetMethodID(callback_class, "<init>", "(J)V"), Pointer(Void).address.to_i64)

        set_onclick = env.GetMethodID(env.GetObjectClass(@native), "setOnClickListener", "(Landroid/view/View$OnClickListener;)V")
        env.CallVoidMethod(@native, set_onclick, callback_obj)
      elsif Native::Platform.ios?
        LibIOS.button_set_callback(@native)
      end
    end

    def handleClick : Nil
      @on_click_callback.try &.call
    end
  end

  class ImageView < View
    def initialize
      if Native::Platform.android?
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        image_class = env.FindClass("android/widget/ImageView")
        constructor = env.GetMethodID(image_class, "<init>", "(Landroid/content/Context;)V")
        @native = env.NewObject(image_class, constructor, activity).to_i64
      elsif Native::Platform.ios?
        ptr = LibIOS.create_image_view
        @native = ptr.to_i64
      end
    end

    def setImageResource(resource_id : Int32) : Nil
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_image = env.GetMethodID(env.GetObjectClass(@native), "setImageResource", "(I)V")
        env.CallVoidMethod(@native, set_image, resource_id)
      elsif Native::Platform.ios?
        LibIOS.image_view_set_resource(@native, resource_id)
      end
    end
  end

  class LinearLayout < View
    enum Orientation
      Vertical
      Horizontal
    end

    def initialize(orientation : Orientation = Orientation::Vertical)
      if Native::Platform.android?
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        layout_class = env.FindClass("android/widget/LinearLayout")
        constructor = env.GetMethodID(layout_class, "<init>", "(Landroid/content/Context;)V")
        @native = env.NewObject(layout_class, constructor, activity).to_i64

        set_orientation = env.GetMethodID(layout_class, "setOrientation", "(I)V")
        orientation_value = orientation == Orientation::Vertical ? 1 : 0
        env.CallVoidMethod(@native, set_orientation, orientation_value)
      elsif Native::Platform.ios?
        ptr = LibIOS.create_stack_view
        @native = ptr.to_i64
      end
    end

    def addView(view : View) : Nil
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0 && view.native_ptr != 0
        add_view = env.GetMethodID(env.GetObjectClass(@native), "addView", "(Landroid/view/View;)V")
        env.CallVoidMethod(@native, add_view, view.native_ptr)
      elsif Native::Platform.ios?
        LibIOS.stack_view_add_view(@native, view.native_ptr)
      end
    end

    def removeView(view : View) : Nil
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0 && view.native_ptr != 0
        remove_view = env.GetMethodID(env.GetObjectClass(@native), "removeView", "(Landroid/view/View;)V")
        env.CallVoidMethod(@native, remove_view, view.native_ptr)
      elsif Native::Platform.ios?
        LibIOS.stack_view_remove_view(@native, view.native_ptr)
      end
    end
  end

  class ScrollView < View
    def initialize
      if Native::Platform.android?
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        scroll_class = env.FindClass("android/widget/ScrollView")
        constructor = env.GetMethodID(scroll_class, "<init>", "(Landroid/content/Context;)V")
        @native = env.NewObject(scroll_class, constructor, activity).to_i64
      elsif Native::Platform.ios?
        ptr = LibIOS.create_scroll_view
        @native = ptr.to_i64
      end
    end

    def addView(view : View) : Nil
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0 && view.native_ptr != 0
        add_view = env.GetMethodID(env.GetObjectClass(@native), "addView", "(Landroid/view/View;)V")
        env.CallVoidMethod(@native, add_view, view.native_ptr)
      elsif Native::Platform.ios?
        LibIOS.scroll_view_add_view(@native, view.native_ptr)
      end
    end
  end
end
