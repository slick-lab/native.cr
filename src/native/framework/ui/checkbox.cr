# src/native/framework/ui/checkbox.cr

module Native::UI
  class CheckBox < View
    @checked : Bool = false
    @text : String = ""
    @on_checked_change : (Bool -> Nil)?

    def initialize(text : String = "")
      super()
      @text = text

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        checkbox_class = env.FindClass("android/widget/CheckBox")
        constructor = env.GetMethodID(checkbox_class, "<init>", "(Landroid/content/Context;)V")
        @native = env.NewObject(checkbox_class, constructor, activity).to_i64

        if !text.empty?
          setText(text)
        end
        setupCheckedListener
      {% elsif flag?(:native_ios) %}
        ptr = LibIOS.create_checkbox
        @native = ptr.to_i64
        if !text.empty?
          setText(text)
        end
      {% end %}
    end

    def checked=(value : Bool)
      @checked = value
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_checked = env.GetMethodID(env.GetObjectClass(@native), "setChecked", "(Z)V")
        env.CallVoidMethod(@native, set_checked, value)
      {% elsif flag?(:native_ios) %}
        LibIOS.checkbox_set_checked(@native, value)
      {% end %}
    end

    def checked? : Bool
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return @checked unless env && @native != 0
        is_checked = env.GetMethodID(env.GetObjectClass(@native), "isChecked", "()Z")
        @checked = env.CallBooleanMethod(@native, is_checked)
      {% elsif flag?(:native_ios) %}
        @checked = LibIOS.checkbox_is_checked(@native)
      {% end %}
      @checked
    end

    def toggle
      self.checked = !@checked
    end

    def text=(value : String)
      @text = value
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        jtext = env.NewStringUTF(value)
        set_text = env.GetMethodID(env.GetObjectClass(@native), "setText", "(Ljava/lang/CharSequence;)V")
        env.CallVoidMethod(@native, set_text, jtext)
      {% elsif flag?(:native_ios) %}
        LibIOS.checkbox_set_text(@native, value.to_utf8)
      {% end %}
    end

    def text : String
      @text
    end

    def text_color=(value : Native::Math::Color)
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        color = ((value.a * 255).to_i << 24) | ((value.r * 255).to_i << 16) | ((value.g * 255).to_i << 8) | (value.b * 255).to_i
        set_color = env.GetMethodID(env.GetObjectClass(@native), "setTextColor", "(I)V")
        env.CallVoidMethod(@native, set_color, color)
      {% elsif flag?(:native_ios) %}
        LibIOS.checkbox_set_text_color(@native, value.r, value.g, value.b)
      {% end %}
    end

    def text_size=(value : Int32)
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_size = env.GetMethodID(env.GetObjectClass(@native), "setTextSize", "(F)V")
        env.CallVoidMethod(@native, set_size, value.to_f32)
      {% elsif flag?(:native_ios) %}
        LibIOS.checkbox_set_text_size(@native, value)
      {% end %}
    end

    def on_checked_change(&block : Bool -> Nil)
      @on_checked_change = block
    end

    private def setupCheckedListener
      {% unless flag?(:native_android) %}
      return
      {% end %}
      env = Native::Android::JNI.env
      return unless env && @native != 0

      callback_class = env.FindClass("com/nativecr/CompoundButtonCallback")
      if callback_class == Pointer(Void).null
        return
      end

      callback_obj = env.NewObject(callback_class, env.GetMethodID(callback_class, "<init>", "(J)V"), Pointer(Void).address.to_i64)

      set_listener = env.GetMethodID(env.GetObjectClass(@native), "setOnCheckedChangeListener", "(Landroid/widget/CompoundButton$OnCheckedChangeListener;)V")
      env.CallVoidMethod(@native, set_listener, callback_obj)
    end

    def handleCheckedChanged(checked : Bool)
      @checked = checked
      @on_checked_change.try &.call(checked)
    end
  end
end
