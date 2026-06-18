# src/native/framework/ui/seek_bar.cr

module Native::UI
  class SeekBar < View
    @progress : Int32 = 0
    @max : Int32 = 100
    @on_progress_changed : (Int32 -> Nil)?
    @on_start_touch : (-> Nil)?
    @on_stop_touch : (-> Nil)?

    def initialize
      super()

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        seek_class = env.find_class("android/widget/SeekBar")
        constructor = env.get_method_id(seek_class, "<init>", "(Landroid/content/Context;)V")
        @native = env.new_object(seek_class, constructor, activity).to_i64

        setupSeekBarListener
      {% elsif flag?(:native_ios) %}
        ptr = LibIOS.create_slider
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
        LibIOS.slider_set_value(@native, @progress, @max)
      {% end %}
    end

    def progress : Int32
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return @progress unless env && @native != 0
        get_progress = env.get_method_id(env.get_object_class(@native), "getProgress", "()I")
        @progress = env.call_int_method(@native, get_progress)
      {% elsif flag?(:native_ios) %}
        value = LibIOS.slider_get_value(@native)
        @progress = (value * @max).to_i
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
        LibIOS.slider_set_max(@native, @max)
      {% end %}
    end

    def max : Int32
      @max
    end

    def on_progress_changed(&block : Int32 -> Nil)
      @on_progress_changed = block
    end

    def on_start_touch(&block : -> Nil)
      @on_start_touch = block
    end

    def on_stop_touch(&block : -> Nil)
      @on_stop_touch = block
    end

    private def setupSeekBarListener
      {% unless flag?(:native_android) %}
      return
      {% end %}
      env = Native::Android::JNI.env
      return unless env && @native != 0

      callback_class = env.find_class("com/nativecr/SeekBarCallback")
      if callback_class == Pointer(Void).null
        return
      end

      callback_obj = env.new_object(callback_class, env.get_method_id(callback_class, "<init>", "(J)V"), 0i64)

      set_listener = env.get_method_id(env.get_object_class(@native), "setOnSeekBarChangeListener", "(Landroid/widget/SeekBar$OnSeekBarChangeListener;)V")
      env.call_void_method(@native, set_listener, callback_obj)
    end

    def handleProgressChanged(progress : Int32)
      @progress = progress
      @on_progress_changed.try &.call(progress)
    end

    def handleStartTrackingTouch
      @on_start_touch.try &.call
    end

    def handleStopTrackingTouch
      @on_stop_touch.try &.call
    end
  end
end
