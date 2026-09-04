# src/native/framework/ui/edit_text.cr
# Refactored to use JNIHelpers for automatic local reference cleanup.

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

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        view_class = env.find_class("android/widget/EditText")
        constructor = env.get_method_id(view_class, "<init>", "(Landroid/content/Context;)V")
        @native = env.new_object(view_class, constructor, activity).to_i64
        env.delete_local_ref(view_class) unless view_class.null?

        if !text.empty?
          self.text = text
        end
        self.text_size = @text_size
        setupTextWatcher
      {% elsif flag?(:native_ios) %}
        ptr = LibIOS.create_text_field
        @native = ptr.to_i64
        if !text.empty?
          self.text = text
        end
        self.text_size = @text_size
      {% end %}
    end

    def text=(value : String)
      @text = value
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        jtext = env.new_string_utf(value)
        JNIHelpers.call_void(env, @native, "setText", "(Ljava/lang/CharSequence;)V", , jtext)
        env.delete_local_ref(jtext) unless jtext.null?
      {% elsif flag?(:native_ios) %}
        LibIOS.text_field_set_text(@native, value.to_utf8)
      {% end %}
    end

    def text : String
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return @text unless env && @native != 0
        get_text = env.get_method_id(env.get_object_class(@native), "getText", "()Landroid/text/Editable;")
        result = env.call_object_method(@native, get_text)
        if result
          @text = env.get_string_utf_chars(result, nil).to_s
          env.delete_local_ref(result)
        end
      {% elsif flag?(:native_ios) %}
        ptr = LibIOS.text_field_get_text(@native)
        if ptr
          @text = String.new(ptr)
          LibIOS.free_string(ptr)
        end
      {% end %}
      @text
    end

    def hint=(value : String)
      @hint = value
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        jhint = env.new_string_utf(value)
        JNIHelpers.call_void(env, @native, "setHint", "(Ljava/lang/CharSequence;)V", , jhint)
        env.delete_local_ref(jhint) unless jhint.null?
      {% elsif flag?(:native_ios) %}
        LibIOS.text_field_set_placeholder(@native, value.to_utf8)
      {% end %}
    end

    def hint : String
      @hint
    end

    def text_size=(value : Int32)
      @text_size = value
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        JNIHelpers.call_void(env, @native, "setTextSize", "(F)V", , value.to_f32)
      {% elsif flag?(:native_ios) %}
        LibIOS.text_field_set_text_size(@native, value)
      {% end %}
    end

    def text_size : Int32
      @text_size
    end

    def text_color=(value : Native::Math::Color)
      @text_color = value
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        color = ((value.a * 255).to_i << 24) | ((value.r * 255).to_i << 16) | ((value.g * 255).to_i << 8) | (value.b * 255).to_i
        JNIHelpers.call_void(env, @native, "setTextColor", "(I)V", , color)
      {% elsif flag?(:native_ios) %}
        LibIOS.text_field_set_text_color(@native, value.r, value.g, value.b)
      {% end %}
    end

    def hint_color=(value : Native::Math::Color)
      @hint_color = value
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        color = ((value.a * 255).to_i << 24) | ((value.r * 255).to_i << 16) | ((value.g * 255).to_i << 8) | (value.b * 255).to_i
        JNIHelpers.call_void(env, @native, "setHintTextColor", "(I)V", , color)
      {% end %}
    end

    def input_type=(type : Int32)
      @input_type = type
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        JNIHelpers.call_void(env, @native, "setInputType", "(I)V", , type)
      {% elsif flag?(:native_ios) %}
        LibIOS.text_field_set_input_type(@native, type)
      {% end %}
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
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        JNIHelpers.call_void(env, @native, "setLines", "(I)V", , value)
      {% end %}
    end

    def lines : Int32
      @lines
    end

    def max_length=(value : Int32)
      @max_length = value
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        filters = env.new_object_array(1, env.find_class("android/text/InputFilter"), nil)
        filter_class = env.find_class("android/text/InputFilter$LengthFilter")
        filter_constructor = env.get_method_id(filter_class, "<init>", "(I)V")
        filter = env.new_object(filter_class, filter_constructor, value)
        env.delete_local_ref(filter_class) unless filter_class.null?
        env.set_object_array_element(filters, 0, filter)
        JNIHelpers.call_void(env, @native, "setFilters", "([Landroid/text/InputFilter;)V", , filters)
      {% end %}
    end

    def max_length : Int32
      @max_length
    end

    def on_text_changed(&block : String -> Nil)
      @on_text_changed = block
    end

    private def setupTextWatcher
      {% unless flag?(:native_android) %}
        return
      {% end %}
      env = Native::Android::JNI.env
      return unless env && @native != 0

      callback_class = env.find_class("com/nativecr/TextWatcherCallback")
      if callback_class == Pointer(Void).null
        return
      end

      callback_obj = env.new_object(callback_class, env.get_method_id(callback_class, "<init>", "(J)V"), 0i64)
      env.delete_local_ref(callback_class) unless callback_class.null?

      JNIHelpers.call_void(env, @native, "addTextChangedListener", "(Landroid/text/TextWatcher;)V", , callback_obj)
    end

    def handleTextChanged(text : String)
      @text = text
      @on_text_changed.try &.call(text)
    end
  end
end
