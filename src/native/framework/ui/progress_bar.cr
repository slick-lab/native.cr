# src/native/framework/ui/progress_bar.cr

module Native::UI
  class ProgressBar < View
    @progress : Int32 = 0
    @max : Int32 = 100
    @indeterminate : Bool = false

    def initialize
      super()

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        progress_class = env.find_class("android/widget/ProgressBar")
        constructor = env.get_method_id(progress_class, "<init>", "(Landroid/content/Context;)V")
        @native = env.new_object(progress_class, constructor, activity).to_i64
      {% elsif flag?(:native_ios) %}
        ptr = LibIOS.create_progress_view
        @native = ptr.to_i64
      {% end %}
    end

    def progress=(value : Int32)
      @progress = value.clamp(0, @max)
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_progress = env.get_method_id(env.get_object_class(@native), "setProgress", "(I)V")
        env.call_void_method(@native, set_progress, @progress)
      {% elsif flag?(:native_ios) %}
        LibIOS.progress_view_set_progress(@native, @progress, @max)
      {% end %}
    end

    def progress : Int32
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return @progress unless env && @native != 0
        get_progress = env.get_method_id(env.get_object_class(@native), "getProgress", "()I")
        @progress = env.call_int_method(@native, get_progress)
      {% end %}
      @progress
    end

    def max=(value : Int32)
      @max = value
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_max = env.get_method_id(env.get_object_class(@native), "setMax", "(I)V")
        env.call_void_method(@native, set_max, @max)
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
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_indeterminate = env.get_method_id(env.get_object_class(@native), "setIndeterminate", "(Z)V")
        env.call_void_method(@native, set_indeterminate, value)
      {% elsif flag?(:native_ios) %}
        LibIOS.progress_view_set_indeterminate(@native, value)
      {% end %}
    end

    def indeterminate? : Bool
      @indeterminate
    end

    def horizontal
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        style = env.get_static_field_id(env.find_class("android/R$attr"), "progressBarStyleHorizontal", "I")
        style_value = env.get_static_int_field(env.find_class("android/R$attr"), style)
        # Need to recreate with different style
      {% end %}
    end
  end

  class CircularProgressBar < ProgressBar
    def initialize
      super()
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        progress_class = env.find_class("android/widget/ProgressBar")
        style = env.get_static_field_id(env.find_class("android/R$attr"), "progressBarStyleLarge", "I")
        constructor = env.get_method_id(progress_class, "<init>", "(Landroid/content/Context;I)V")
        @native = env.new_object(progress_class, constructor, activity, style).to_i64
      {% end %}
    end
  end
end
