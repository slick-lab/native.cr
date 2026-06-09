# src/native/framework/ui/switch.cr

module Native::UI
  class Switch < View
    @checked : Bool = false
    @on_checked_change : (Bool -> Nil)?
    @text_on : String = "ON"
    @text_off : String = "OFF"

    def initialize
      super()

      if Native::Platform.android?
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        switch_class = env.FindClass("android/widget/Switch")
        constructor = env.GetMethodID(switch_class, "<init>", "(Landroid/content/Context;)V")
        @native = env.NewObject(switch_class, constructor, activity).to_i64

        setupCheckedListener
      elsif Native::Platform.ios?
        ptr = LibIOS.create_switch
        @native = ptr.to_i64
      end
    end

    def checked=(value : Bool)
      @checked = value
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_checked = env.GetMethodID(env.GetObjectClass(@native), "setChecked", "(Z)V")
        env.CallVoidMethod(@native, set_checked, value)
      elsif Native::Platform.ios?
        LibIOS.switch_set_on(@native, value)
      end
    end

    def checked? : Bool
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return @checked unless env && @native != 0
        is_checked = env.GetMethodID(env.GetObjectClass(@native), "isChecked", "()Z")
        @checked = env.CallBooleanMethod(@native, is_checked)
      elsif Native::Platform.ios?
        @checked = LibIOS.switch_is_on(@native)
      end
      @checked
    end

    def toggle
      self.checked = !@checked
    end

    def text_on=(value : String)
      @text_on = value
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        jtext = env.NewStringUTF(value)
        set_text = env.GetMethodID(env.GetObjectClass(@native), "setTextOn", "(Ljava/lang/CharSequence;)V")
        env.CallVoidMethod(@native, set_text, jtext)
      end
    end

    def text_on : String
      @text_on
    end

    def text_off=(value : String)
      @text_off = value
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        jtext = env.NewStringUTF(value)
        set_text = env.GetMethodID(env.GetObjectClass(@native), "setTextOff", "(Ljava/lang/CharSequence;)V")
        env.CallVoidMethod(@native, set_text, jtext)
      end
    end

    def text_off : String
      @text_off
    end

    def show_text=(value : Bool)
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_show = env.GetMethodID(env.GetObjectClass(@native), "setShowText", "(Z)V")
        env.CallVoidMethod(@native, set_show, value)
      end
    end

    def on_checked_change(&block : Bool -> Nil)
      @on_checked_change = block
    end

    private def setupCheckedListener
      return unless Native::Platform.android?
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
