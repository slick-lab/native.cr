# src/native/framework/ui/switch.cr
# Refactored to use JNIHelpers for automatic local reference cleanup.

module Native::UI
  class Switch < View
    @checked : Bool = false
    @on_checked_change : (Bool -> Nil)?
    @text_on : String = "ON"
    @text_off : String = "OFF"

    def initialize
      super()

      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          activity = Native::Android::JNI.activity
          return unless activity

          @native = JNIHelpers.new_widget(env, "android/widget/Switch", activity)

          setupCheckedListener(env)
        end
      {% elsif flag?(:native_ios) %}
        ptr = LibIOS.create_switch
        @native = ptr.to_i64
      {% end %}
    end

    def checked=(value : Bool)
      @checked = value
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0
          JNIHelpers.call_void(env, @native, "setChecked", "(Z)V", value)
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.switch_set_on(@native, value)
      {% end %}
    end

    def checked? : Bool
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0
          @checked = JNIHelpers.call_boolean(env, @native, "isChecked", "()Z")
        end
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
        JNIHelpers.with_env do |env|
          return if @native == 0
          JNIHelpers.call_void_string(env, @native, "setTextOn", "(Ljava/lang/CharSequence;)V", value)
        end
      {% end %}
    end

    def text_on : String
      @text_on
    end

    def text_off=(value : String)
      @text_off = value
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0
          JNIHelpers.call_void_string(env, @native, "setTextOff", "(Ljava/lang/CharSequence;)V", value)
        end
      {% end %}
    end

    def text_off : String
      @text_off
    end

    def show_text=(value : Bool)
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0
          JNIHelpers.call_void(env, @native, "setShowText", "(Z)V", value)
        end
      {% end %}
    end

    def on_checked_change(&block : Bool -> Nil)
      @on_checked_change = block
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0
          setupCheckedListener(env)
        end
      {% end %}
    end

    private def setupCheckedListener(env : Native::Android::JNIEnvWrapper)
      {% unless flag?(:native_android) %}
        return
      {% end %}

      callback = JNIHelpers.new_callback(env, "com/nativecr/CompoundButtonCallback", 0i64)
      return if callback.null?

      begin
        JNIHelpers.call_void(
          env, @native, "setOnCheckedChangeListener",
          "(Landroid/widget/CompoundButton$OnCheckedChangeListener;)V", callback
        )
      ensure
        env.delete_local_ref(callback)
      end
    end

    def handleCheckedChanged(checked : Bool)
      @checked = checked
      @on_checked_change.try &.call(checked)
    end
  end
end
