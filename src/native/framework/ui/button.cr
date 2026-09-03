# src/native/framework/ui/button.cr
# Refactored to use JNIHelpers for automatic local reference cleanup.

module Native::UI
  class Button < View
    @text : String = ""
    @text_size : Int32 = 14
    @text_color : Native::Math::Color = Native::Math::Color.white
    @background_color : Native::Math::Color = Native::Math::Color.blue
    @all_caps : Bool = false
    @on_click : (-> Nil)? = nil
    @on_long_click : (-> Nil)? = nil

    def initialize(text : String = "")
      super()
      @text = text

      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          activity = Native::Android::JNI.activity
          return unless activity

          @native = JNIHelpers.new_widget(env, "android/widget/Button", activity)

          if !text.empty?
            JNIHelpers.set_text(env, @native, text)
          end
          JNIHelpers.set_text_size(env, @native, @text_size)
          apply_text_color(env)
          apply_background_color(env)
          setup_click_listeners(env)
        end
      {% elsif flag?(:native_ios) %}
        ptr = LibIOS.create_button
        @native = ptr.to_i64
        if !text.empty?
          self.text = text
        end
        self.text_size = @text_size
        apply_text_color
        apply_background_color
      {% end %}
    end

    def text=(value : String)
      @text = value
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0
          JNIHelpers.set_text(env, @native, value)
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.button_set_text(@native, value.to_utf8)
      {% end %}
    end

    def text : String
      @text
    end

    def text_size=(value : Int32)
      @text_size = value
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0
          JNIHelpers.set_text_size(env, @native, value)
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.button_set_text_size(@native, value)
      {% end %}
    end

    def text_size : Int32
      @text_size
    end

    def text_color=(value : Native::Math::Color)
      @text_color = value
      apply_text_color
    end

    def text_color : Native::Math::Color
      @text_color
    end

    def background_color=(value : Native::Math::Color)
      @background_color = value
      apply_background_color
    end

    def background_color : Native::Math::Color
      @background_color
    end

    def all_caps=(value : Bool)
      @all_caps = value
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0
          JNIHelpers.set_all_caps(env, @native, value)
        end
      {% end %}
    end

    def all_caps? : Bool
      @all_caps
    end

    def on_click(&block : -> Nil)
      @on_click = block
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0
          setup_click_listeners(env)
        end
      {% end %}
    end

    def on_long_click(&block : -> Nil)
      @on_long_click = block
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0
          setup_click_listeners(env)
        end
      {% end %}
    end

    private def apply_text_color(env : Native::Android::JNIEnvWrapper? = nil)
      {% if flag?(:native_android) %}
        if env
          return if @native == 0
          color = argb_from_color(@text_color)
          JNIHelpers.set_text_color(env, @native, color)
        else
          JNIHelpers.with_env do |e|
            return if @native == 0
            color = argb_from_color(@text_color)
            JNIHelpers.set_text_color(e, @native, color)
          end
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.button_set_text_color(@native, @text_color.r, @text_color.g, @text_color.b)
      {% end %}
    end

    private def apply_background_color(env : Native::Android::JNIEnvWrapper? = nil)
      {% if flag?(:native_android) %}
        if env
          return if @native == 0
          color = argb_from_color(@background_color)
          JNIHelpers.set_background_color(env, @native, color)
        else
          JNIHelpers.with_env do |e|
            return if @native == 0
            color = argb_from_color(@background_color)
            JNIHelpers.set_background_color(e, @native, color)
          end
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.button_set_background_color(@native, @background_color.r, @background_color.g, @background_color.b, @background_color.a)
      {% end %}
    end

    private def setup_click_listeners(env : Native::Android::JNIEnvWrapper)
      {% unless flag?(:native_android) %}
        return
      {% end %}

      callback = JNIHelpers.new_callback(env, "com/nativecr/OnClickCallback", 0i64)
      return if callback.null?

      begin
        if @on_click
          JNIHelpers.set_on_click_listener(env, @native, callback)
        end

        if @on_long_click
          JNIHelpers.set_on_long_click_listener(env, @native, callback)
        end
      ensure
        env.delete_local_ref(callback)
      end
    end

    def handle_click
      @on_click.try &.call
    end

    def handle_long_click
      @on_long_click.try &.call
    end

    private def argb_from_color(color : Native::Math::Color) : Int32
      ((color.a * 255).to_i << 24) |
      ((color.r * 255).to_i << 16) |
      ((color.g * 255).to_i << 8) |
      (color.b * 255).to_i
    end
  end
end
