# src/native/framework/ui/radiobutton.cr
# Refactored to use JNIHelpers for automatic local reference cleanup.

module Native::UI
  class RadioButton < View
    @checked : Bool = false
    @text : String = ""
    @group : RadioGroup?
    @on_checked_change : (Bool -> Nil)?

    def initialize(text : String = "")
      super()
      @text = text

      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          activity = Native::Android::JNI.activity
          return unless activity

          @native = JNIHelpers.new_widget(env, "android/widget/RadioButton", activity)

          if !text.empty?
            JNIHelpers.set_text(env, @native, text)
          end
          setupCheckedListener(env)
        end
      {% elsif flag?(:native_ios) %}
        ptr = LibIOS.create_radio_button
        @native = ptr.to_i64
        if !text.empty?
          self.text = text
        end
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
        LibIOS.radio_button_set_checked(@native, value)
      {% end %}
    end

    def checked? : Bool
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0
          @checked = JNIHelpers.call_boolean(env, @native, "isChecked", "()Z")
        end
      {% elsif flag?(:native_ios) %}
        @checked = LibIOS.radio_button_is_checked(@native)
      {% end %}
      @checked
    end

    def text=(value : String)
      @text = value
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0
          JNIHelpers.set_text(env, @native, value)
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.radio_button_set_text(@native, value.to_utf8)
      {% end %}
    end

    def text : String
      @text
    end

    def group=(group : RadioGroup)
      @group = group
      group.addButton(self)
    end

    def group : RadioGroup?
      @group
    end

    def text_color=(value : Native::Math::Color)
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0
          JNIHelpers.set_text_color(env, @native, argb_from_color(value))
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.radio_button_set_text_color(@native, value.r, value.g, value.b)
      {% end %}
    end

    def text_size=(value : Int32)
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0
          JNIHelpers.set_text_size(env, @native, value)
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.radio_button_set_text_size(@native, value)
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

      if checked && @group
        @group.not_nil!.handleButtonSelected(self)
      end
    end

    private def argb_from_color(color : Native::Math::Color) : Int32
      ((color.a * 255).to_i << 24) |
      ((color.r * 255).to_i << 16) |
      ((color.g * 255).to_i << 8) |
      (color.b * 255).to_i
    end
  end

  class RadioGroup
    @buttons : Array(RadioButton) = [] of RadioButton
    @selected_button : RadioButton?
    @on_selected_change : (RadioButton -> Nil)?

    def addButton(button : RadioButton)
      @buttons << button
      if button.checked?
        @selected_button = button
      end
    end

    def removeButton(button : RadioButton)
      @buttons.delete(button)
      if @selected_button == button
        @selected_button = nil
      end
    end

    def selected_button : RadioButton?
      @selected_button
    end

    def selected_button=(button : RadioButton)
      return unless @buttons.includes?(button)

      @selected_button.try(&.checked = false)
      @selected_button = button
      @selected_button.try(&.checked = true)
      @on_selected_change.try &.call(button)
    end

    def on_selected_change(&block : RadioButton -> Nil)
      @on_selected_change = block
    end

    def handleButtonSelected(button : RadioButton)
      if @selected_button != button
        @selected_button = button
        @on_selected_change.try &.call(button)
      end
    end

    def clearSelection
      @selected_button.try(&.checked = false)
      @selected_button = nil
    end
  end
end
