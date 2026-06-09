# src/native/framework/ui/text_view.cr

module Native::UI
  class TextView < View
    @text : String = ""
    @text_size : Int32 = 14
    @text_color : Native::Math::Color = Native::Math::Color.black
    @gravity : Int32 = 0
    @max_lines : Int32 = 0
    @ellipsize : Int32 = 0

    def initialize(text : String = "")
      super()
      @text = text

      if Native::Platform.android?
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        view_class = env.FindClass("android/widget/TextView")
        constructor = env.GetMethodID(view_class, "<init>", "(Landroid/content/Context;)V")
        @native = env.NewObject(view_class, constructor, activity).to_i64

        if !text.empty?
          setText(text)
        end
        setTextSize(@text_size)
        applyGravity
      elsif Native::Platform.ios?
        ptr = LibIOS.create_label
        @native = ptr.to_i64
        if !text.empty?
          setText(text)
        end
        setTextSize(@text_size)
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
        LibIOS.label_set_text(@native, value.to_utf8)
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
        LibIOS.label_set_text_size(@native, value)
      end
    end

    def text_size : Int32
      @text_size
    end

    def text_color=(value : Native::Math::Color)
      @text_color = value
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        color = ((value.a * 255).to_i << 24) | ((value.r * 255).to_i << 16) | ((value.g * 255).to_i << 8) | (value.b * 255).to_i
        set_color = env.GetMethodID(env.GetObjectClass(@native), "setTextColor", "(I)V")
        env.CallVoidMethod(@native, set_color, color)
      elsif Native::Platform.ios?
        LibIOS.label_set_text_color(@native, value.r, value.g, value.b)
      end
    end

    def text_color : Native::Math::Color
      @text_color
    end

    def gravity=(gravity : Int32)
      @gravity = gravity
      applyGravity
    end

    def gravity : Int32
      @gravity
    end

    def center
      @gravity = 17
      applyGravity
    end

    def center_horizontal
      @gravity = 1
      applyGravity
    end

    def center_vertical
      @gravity = 16
      applyGravity
    end

    def left
      @gravity = 3
      applyGravity
    end

    def right
      @gravity = 5
      applyGravity
    end

    def max_lines=(value : Int32)
      @max_lines = value
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_max = env.GetMethodID(env.GetObjectClass(@native), "setMaxLines", "(I)V")
        env.CallVoidMethod(@native, set_max, value)
      elsif Native::Platform.ios?
        LibIOS.label_set_max_lines(@native, value)
      end
    end

    def max_lines : Int32
      @max_lines
    end

    def ellipsize_end
      @ellipsize = 3
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_ellipsize = env.GetMethodID(env.GetObjectClass(@native), "setEllipsize", "(Landroid/text/TextUtils$TruncateAt;)V")
        value = env.GetStaticObjectField(env.FindClass("android/text/TextUtils$TruncateAt"), env.GetStaticFieldID(env.FindClass("android/text/TextUtils$TruncateAt"), "END", "Landroid/text/TextUtils$TruncateAt;"))
        env.CallVoidMethod(@native, set_ellipsize, value)
      end
    end

    private def applyGravity
      return unless Native::Platform.android?
      env = Native::Android::JNI.env
      return unless env && @native != 0
      set_gravity = env.GetMethodID(env.GetObjectClass(@native), "setGravity", "(I)V")
      env.CallVoidMethod(@native, set_gravity, @gravity)
    end
  end
end
