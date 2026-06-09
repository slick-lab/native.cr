# src/native/framework/ui/button.cr

module Native::UI
  class Button < View
    @text : String = ""
    @text_size : Int32 = 14
    @text_color : Native::Math::Color = Native::Math::Color.white
    @background_color : Native::Math::Color = Native::Math::Color.blue
    @all_caps : Bool = false
    @on_click : -> Nil?
    @on_long_click : -> Nil?

    def initialize(text : String = "")
      super()
      @text = text

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
        setTextSize(@text_size)
        applyTextColor
        applyBackgroundColor
        setupClickListeners
      elsif Native::Platform.ios?
        ptr = LibIOS.create_button
        @native = ptr.to_i64
        if !text.empty?
          setText(text)
        end
        setTextSize(@text_size)
        applyTextColor
        applyBackgroundColor
      end
    end

    def text=(value : String)
      @text = value
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        jtext = env.NewStringUTF(value)
        set_text = env.GetMethodID(env.GetObjectClass(@native), "setText", "(Ljava/lang/CharSequence;)V")
        env.CallVoidMethod(@native, set_text, jtext)
      elsif Native::Platform.ios?
        LibIOS.button_set_text(@native, value.to_utf8)
      end
    end

    def text : String
      @text
    end

    def text_size=(value : Int32)
      @text_size = value
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_size = env.GetMethodID(env.GetObjectClass(@native), "setTextSize", "(F)V")
        env.CallVoidMethod(@native, set_size, value.to_f32)
      elsif Native::Platform.ios?
        LibIOS.button_set_text_size(@native, value)
      end
    end

    def text_size : Int32
      @text_size
    end

    def text_color=(value : Native::Math::Color)
      @text_color = value
      applyTextColor
    end

    def text_color : Native::Math::Color
      @text_color
    end

    def background_color=(value : Native::Math::Color)
      @background_color = value
      applyBackgroundColor
    end

    def background_color : Native::Math::Color
      @background_color
    end

    def all_caps=(value : Bool)
      @all_caps = value
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_all_caps = env.GetMethodID(env.GetObjectClass(@native), "setAllCaps", "(Z)V")
        env.CallVoidMethod(@native, set_all_caps, value)
      end
    end

    def all_caps? : Bool
      @all_caps
    end

    def on_click(&block : -> Nil)
      @on_click = block
      setupClickListeners if Native::Platform.android?
    end

    def on_long_click(&block : -> Nil)
      @on_long_click = block
      setupClickListeners if Native::Platform.android?
    end

    private def applyTextColor
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        color = ((@text_color.a * 255).to_i << 24) | ((@text_color.r * 255).to_i << 16) | ((@text_color.g * 255).to_i << 8) | (@text_color.b * 255).to_i
        set_color = env.GetMethodID(env.GetObjectClass(@native), "setTextColor", "(I)V")
        env.CallVoidMethod(@native, set_color, color)
      elsif Native::Platform.ios?
        LibIOS.button_set_text_color(@native, @text_color.r, @text_color.g, @text_color.b)
      end
    end

    private def applyBackgroundColor
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        color = ((@background_color.a * 255).to_i << 24) | ((@background_color.r * 255).to_i << 16) | ((@background_color.g * 255).to_i << 8) | (@background_color.b * 255).to_i
        set_bg = env.GetMethodID(env.GetObjectClass(@native), "setBackgroundColor", "(I)V")
        env.CallVoidMethod(@native, set_bg, color)
      elsif Native::Platform.ios?
        LibIOS.button_set_background_color(@native, @background_color.r, @background_color.g, @background_color.b, @background_color.a)
      end
    end

    private def setupClickListeners
      return unless Native::Platform.android?
      env = Native::Android::JNI.env
      return unless env && @native != 0

      callback_class = env.FindClass("com/nativecr/OnClickCallback")
      if callback_class == Pointer(Void).null
        return
      end

      callback_obj = env.NewObject(callback_class, env.GetMethodID(callback_class, "<init>", "(J)V"), Pointer(Void).address.to_i64)

      if @on_click
        set_onclick = env.GetMethodID(env.GetObjectClass(@native), "setOnClickListener", "(Landroid/view/View$OnClickListener;)V")
        env.CallVoidMethod(@native, set_onclick, callback_obj)
      end

      if @on_long_click
        set_onlongclick = env.GetMethodID(env.GetObjectClass(@native), "setOnLongClickListener", "(Landroid/view/View$OnLongClickListener;)V")
        env.CallVoidMethod(@native, set_onlongclick, callback_obj)
      end
    end

    def handleClick
      @on_click.try &.call
    end

    def handleLongClick
      @on_long_click.try &.call
    end
  end
end
