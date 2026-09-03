# src/native/framework/ui/text_view.cr
# Refactored to use JNIHelpers for automatic local reference cleanup.

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

      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          activity = Native::Android::JNI.activity
          return unless activity

          @native = JNIHelpers.new_widget(env, "android/widget/TextView", activity)

          if !text.empty?
            JNIHelpers.set_text(env, @native, text)
          end
          JNIHelpers.set_text_size(env, @native, @text_size)
          apply_gravity(env)
        end
      {% elsif flag?(:native_ios) %}
        ptr = LibIOS.create_label
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
        JNIHelpers.with_env do |env|
          return if @native == 0
          JNIHelpers.set_text(env, @native, value)
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.label_set_text(@native, value.to_utf8)
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
        LibIOS.label_set_text_size(@native, value)
      {% end %}
    end

    def text_size : Int32
      @text_size
    end

    def text_color=(value : Native::Math::Color)
      @text_color = value
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0
          color = argb_from_color(value)
          JNIHelpers.set_text_color(env, @native, color)
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.label_set_text_color(@native, value.r, value.g, value.b)
      {% end %}
    end

    def text_color : Native::Math::Color
      @text_color
    end

    def gravity=(gravity : Int32)
      @gravity = gravity
      apply_gravity
    end

    def gravity : Int32
      @gravity
    end

    def center
      @gravity = 17
      apply_gravity
    end

    def center_horizontal
      @gravity = 1
      apply_gravity
    end

    def center_vertical
      @gravity = 16
      apply_gravity
    end

    def left
      @gravity = 3
      apply_gravity
    end

    def right
      @gravity = 5
      apply_gravity
    end

    def max_lines=(value : Int32)
      @max_lines = value
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0
          JNIHelpers.set_max_lines(env, @native, value)
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.label_set_max_lines(@native, value)
      {% end %}
    end

    def max_lines : Int32
      @max_lines
    end

    def ellipsize_end
      @ellipsize = 3
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0

          # Get TruncateAt.END static field
          end_ref = JNIHelpers.call_static_object(env, "android/text/TextUtils$TruncateAt", "END", "Landroid/text/TextUtils$TruncateAt;")
          return if end_ref.null?

          begin
            JNIHelpers.call_void(env, @native, "setEllipsize", "(Landroid/text/TextUtils$TruncateAt;)V", end_ref)
          ensure
            env.delete_local_ref(end_ref)
          end
        end
      {% end %}
    end

    private def apply_gravity(env : Native::Android::JNIEnvWrapper? = nil)
      {% unless flag?(:native_android) %}
        return
      {% end %}

      if env
        return if @native == 0
        JNIHelpers.set_gravity(env, @native, @gravity)
      else
        JNIHelpers.with_env do |e|
          return if @native == 0
          JNIHelpers.set_gravity(e, @native, @gravity)
        end
      end
    end

    private def argb_from_color(color : Native::Math::Color) : Int32
      ((color.a * 255).to_i << 24) |
      ((color.r * 255).to_i << 16) |
      ((color.g * 255).to_i << 8) |
      (color.b * 255).to_i
    end
  end
end
