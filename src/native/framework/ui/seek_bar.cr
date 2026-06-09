# src/native/framework/ui/seek_bar.cr

module Native::UI
  class SeekBar < View
    @progress : Int32 = 0
    @max : Int32 = 100
    @on_progress_changed : (Int32 -> Nil)?
    @on_start_touch : ( -> Nil)?
    @on_stop_touch : ( -> Nil)?

    def initialize
      super()

      if Native::Platform.android?
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        seek_class = env.FindClass("android/widget/SeekBar")
        constructor = env.GetMethodID(seek_class, "<init>", "(Landroid/content/Context;)V")
        @native = env.NewObject(seek_class, constructor, activity).to_i64

        setupSeekBarListener
      elsif Native::Platform.ios?
        ptr = LibIOS.create_slider
        @native = ptr.to_i64
      end
    end

    def progress=(value : Int32)
      @progress = value.clamp(0, @max)
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_progress = env.GetMethodID(env.GetObjectClass(@native), "setProgress", "(I)V")
        env.CallVoidMethod(@native, set_progress, @progress)
      elsif Native::Platform.ios?
        LibIOS.slider_set_value(@native, @progress, @max)
      end
    end

    def progress : Int32
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return @progress unless env && @native != 0
        get_progress = env.GetMethodID(env.GetObjectClass(@native), "getProgress", "()I")
        @progress = env.CallIntMethod(@native, get_progress)
      elsif Native::Platform.ios?
        value = LibIOS.slider_get_value(@native)
        @progress = (value * @max).to_i
      end
      @progress
    end

    def max=(value : Int32)
      @max = value
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_max = env.GetMethodID(env.GetObjectClass(@native), "setMax", "(I)V")
        env.CallVoidMethod(@native, set_max, @max)
      elsif Native::Platform.ios?
        LibIOS.slider_set_max(@native, @max)
      end
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
      return unless Native::Platform.android?
      env = Native::Android::JNI.env
      return unless env && @native != 0

      callback_class = env.FindClass("com/nativecr/SeekBarCallback")
      if callback_class == Pointer(Void).null
        return
      end

      callback_obj = env.NewObject(callback_class, env.GetMethodID(callback_class, "<init>", "(J)V"), Pointer(Void).address.to_i64)

      set_listener = env.GetMethodID(env.GetObjectClass(@native), "setOnSeekBarChangeListener", "(Landroid/widget/SeekBar$OnSeekBarChangeListener;)V")
      env.CallVoidMethod(@native, set_listener, callback_obj)
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
