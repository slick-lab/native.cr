# src/native/framework/ui/progress_bar.cr
# Refactored to use JNIHelpers for automatic local reference cleanup.

module Native::UI
  class ProgressBar < View
    @progress : Int32 = 0
    @max : Int32 = 100
    @indeterminate : Bool = false

    def initialize
      super()

      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          activity = Native::Android::JNI.activity
          return unless activity

          @native = JNIHelpers.new_widget(env, "android/widget/ProgressBar", activity)
        end
      {% elsif flag?(:native_ios) %}
        ptr = LibIOS.create_progress_view
        @native = ptr.to_i64
      {% end %}
    end

    def progress=(value : Int32)
      @progress = value.clamp(0, @max)
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0
          JNIHelpers.call_void(env, @native, "setProgress", "(I)V", @progress)
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.progress_view_set_progress(@native, @progress, @max)
      {% end %}
    end

    def progress : Int32
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0
          @progress = JNIHelpers.call_int(env, @native, "getProgress", "()I")
        end
      {% end %}
      @progress
    end

    def max=(value : Int32)
      @max = value
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0
          JNIHelpers.call_void(env, @native, "setMax", "(I)V", @max)
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.progress_view_set_max(@native, @max)
      {% end %}
    end

    def max : Int32
      @max
    end

    def indeterminate=(value : Bool)
      @indeterminate = value
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0
          JNIHelpers.call_void(env, @native, "setIndeterminate", "(Z)V", value)
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.progress_view_set_indeterminate(@native, value)
      {% end %}
    end

    def indeterminate? : Bool
      @indeterminate
    end

    def horizontal
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0
          JNIHelpers.with_class(env, "android/R$attr") do |attr_class|
            return if attr_class.null?
            style = env.get_static_field_id(attr_class, "progressBarStyleHorizontal", "I")
            style_value = style.null? ? 0 : env.get_static_int_field(attr_class, style)
            # Need to recreate with different style
          end
        end
      {% end %}
    end
  end

  class CircularProgressBar < ProgressBar
    def initialize
      super()
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          activity = Native::Android::JNI.activity
          return unless activity

          # Look up the styled attribute, then build the widget with the
          # two-arg (Context, style) constructor. Both class refs are
          # cleaned up by with_class.
          style = JNIHelpers.with_class(env, "android/R$attr") do |attr_class|
            next 0 if attr_class.null?
            fid = env.get_static_field_id(attr_class, "progressBarStyleLarge", "I")
            fid.null? ? 0 : env.get_static_int_field(attr_class, fid)
          end

          @native = JNIHelpers.with_class(env, "android/widget/ProgressBar") do |progress_class|
            next 0i64 if progress_class.null?
            ctor = env.get_method_id(progress_class, "<init>", "(Landroid/content/Context;I)V")
            next 0i64 if ctor.null?
            obj = env.new_object(progress_class, ctor, activity, style)
            obj.null? ? 0i64 : obj.to_i64
          end
        end
      {% end %}
    end
  end
end
