# src/native/framework/ui/switch.cr

module Native::UI
  class Switch < View
    @checked : Bool = false
    @on_checked_change : (Bool -> Nil)?
    @text_on : String = "ON"
    @text_off : String = "OFF"

    def initialize
      super()

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        switch_class = env.find_class("android/widget/Switch")
        constructor = env.get_method_id(switch_class, "<init>", "(Landroid/content/Context;)V")
        @native = env.new_object(switch_class, constructor, activity).to_i64

        setupCheckedListener
      {% elsif flag?(:native_ios) %}
        ptr = LibIOS.create_switch
        @native = ptr.to_i64
      {% end %}
    end

    def checked=(value : Bool)
      @checked = value
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_checked = env.get_method_id(env.get_object_class(@native), "setChecked", "(Z)V")
        env.call_void_method(@native, set_checked, value)
      {% elsif flag?(:native_ios) %}
        LibIOS.switch_set_on(@native, value)
      {% end %}
    end

    def checked? : Bool
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return @checked unless env && @native != 0
        is_checked = env.get_method_id(env.get_object_class(@native), "isChecked", "()Z")
        @checked = env.call_boolean_method(@native, is_checked)
      {% elsif flag?(:native_ios) %}
        @checked = LibIOS.switch_is_on(@native)
      {% end %}
      @checked
    end

    def toggle
      self.checked = !@checked
    end

    def text_on=(value : String)
      @text_on = value
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        jtext = env.new_string_utf(value)
        set_text = env.get_method_id(env.get_object_class(@native), "setTextOn", "(Ljava/lang/CharSequence;)V")
        env.call_void_method(@native, set_text, jtext)
      {% end %}
    end

    def text_on : String
      @text_on
    end

    def text_off=(value : String)
      @text_off = value
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        jtext = env.new_string_utf(value)
        set_text = env.get_method_id(env.get_object_class(@native), "setTextOff", "(Ljava/lang/CharSequence;)V")
        env.call_void_method(@native, set_text, jtext)
      {% end %}
    end

    def text_off : String
      @text_off
    end

    def show_text=(value : Bool)
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_show = env.get_method_id(env.get_object_class(@native), "setShowText", "(Z)V")
        env.call_void_method(@native, set_show, value)
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

      callback_class = env.find_class("com/nativecr/CompoundButtonCallback")
      if callback_class == Pointer(Void).null
        return
      end

      callback_obj = env.new_object(callback_class, env.get_method_id(callback_class, "<init>", "(J)V"), 0i64)

      set_listener = env.get_method_id(env.get_object_class(@native), "setOnCheckedChangeListener", "(Landroid/widget/CompoundButton$OnCheckedChangeListener;)V")
      env.call_void_method(@native, set_listener, callback_obj)
    end

    def handleCheckedChanged(checked : Bool)
      @checked = checked
      @on_checked_change.try &.call(checked)
    end
  end
end
