# src/native/framework/ui/edit_text.cr

module Native::UI
  class EditText < View
    @text : String = ""
    @hint : String = ""
    @text_size : Int32 = 14
    @text_color : Native::Math::Color = Native::Math::Color.black
    @hint_color : Native::Math::Color = Native::Math::Color.gray(128)
    @input_type : Int32 = 1
    @max_length : Int32 = 0
    @lines : Int32 = 1
    @on_text_changed : (String -> Nil)?

    def initialize(text : String = "")
      super()
      @text = text

      if Native::Platform.android?
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        view_class = env.FindClass("android/widget/EditText")
        constructor = env.GetMethodID(view_class, "<init>", "(Landroid/content/Context;)V")
        @native = env.NewObject(view_class, constructor, activity).to_i64

        if !text.empty?
          setText(text)
        end
        setTextSize(@text_size)
        setupTextWatcher
      elsif Native::Platform.ios?
        ptr = LibIOS.create_text_field
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
        LibIOS.text_field_set_text(@native, value.to_utf8)
      end
    end

    def text : String
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return @text unless env && @native != 0
        get_text = env.GetMethodID(env.GetObjectClass(@native), "getText", "()Landroid/text/Editable;")
        result = env.CallObjectMethod(@native, get_text)
        if result
          @text = env.GetStringUTFChars(result, nil).to_s
          env.DeleteLocalRef(result)
        end
      elsif Native::Platform.ios?
        ptr = LibIOS.text_field_get_text(@native)
        if ptr
          @text = String.new(ptr)
          LibIOS.free_string(ptr)
        end
      end
      @text
    end

    def hint=(value : String)
      @hint = value
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        jhint = env.NewStringUTF(value)
        set_hint = env.GetMethodID(env.GetObjectClass(@native), "setHint", "(Ljava/lang/CharSequence;)V")
        env.CallVoidMethod(@native, set_hint, jhint)
      elsif Native::Platform.ios?
        LibIOS.text_field_set_placeholder(@native, value.to_utf8)
      end
    end

    def hint : String
      @hint
    end

    def text_size=(value : Int32)
      @text_size = value
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_size = env.GetMethodID(env.GetObjectClass(@native), "setTextSize", "(F)V")
        env.CallVoidMethod(@native, set_size, value.to_f32)
      elsif Native::Platform.ios?
        LibIOS.text_field_set_text_size(@native, value)
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
        LibIOS.text_field_set_text_color(@native, value.r, value.g, value.b)
      end
    end

    def hint_color=(value : Native::Math::Color)
      @hint_color = value
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        color = ((value.a * 255).to_i << 24) | ((value.r * 255).to_i << 16) | ((value.g * 255).to_i << 8) | (value.b * 255).to_i
        set_hint_color = env.GetMethodID(env.GetObjectClass(@native), "setHintTextColor", "(I)V")
        env.CallVoidMethod(@native, set_hint_color, color)
      end
    end

    def input_type=(type : Int32)
      @input_type = type
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_input = env.GetMethodID(env.GetObjectClass(@native), "setInputType", "(I)V")
        env.CallVoidMethod(@native, set_input, type)
      elsif Native::Platform.ios?
        LibIOS.text_field_set_input_type(@native, type)
      end
    end

    def input_type : Int32
      @input_type
    end

    def password
      input_type = 128
    end

    def email
      input_type = 33
    end

    def number
      input_type = 2
    end

    def phone
      input_type = 3
    end

    def multiline
      input_type = 131073
      lines = 5
    end

    def lines=(value : Int32)
      @lines = value
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_lines = env.GetMethodID(env.GetObjectClass(@native), "setLines", "(I)V")
        env.CallVoidMethod(@native, set_lines, value)
      end
    end

    def lines : Int32
      @lines
    end

    def max_length=(value : Int32)
      @max_length = value
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        filters = env.NewObjectArray(1, env.FindClass("android/text/InputFilter"), nil)
        filter_class = env.FindClass("android/text/InputFilter$LengthFilter")
        filter_constructor = env.GetMethodID(filter_class, "<init>", "(I)V")
        filter = env.NewObject(filter_class, filter_constructor, value)
        env.SetObjectArrayElement(filters, 0, filter)
        set_filters = env.GetMethodID(env.GetObjectClass(@native), "setFilters", "([Landroid/text/InputFilter;)V")
        env.CallVoidMethod(@native, set_filters, filters)
      end
    end

    def max_length : Int32
      @max_length
    end

    def on_text_changed(&block : String -> Nil)
      @on_text_changed = block
    end

    private def setupTextWatcher
      return unless Native::Platform.android?
      env = Native::Android::JNI.env
      return unless env && @native != 0

      callback_class = env.FindClass("com/nativecr/TextWatcherCallback")
      if callback_class == Pointer(Void).null
        return
      end

      callback_obj = env.NewObject(callback_class, env.GetMethodID(callback_class, "<init>", "(J)V"), Pointer(Void).address.to_i64)

      add_watcher = env.GetMethodID(env.GetObjectClass(@native), "addTextChangedListener", "(Landroid/text/TextWatcher;)V")
      env.CallVoidMethod(@native, add_watcher, callback_obj)
    end

    def handleTextChanged(text : String)
      @text = text
      @on_text_changed.try &.call(text)
    end
  end
end
