# src/native/framework/ui/seek_bar.cr
# Refactored to use JNIHelpers for automatic local reference cleanup.

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
        JNIHelpers.with_env do |env|
          activity = Native::Android::JNI.activity
          return unless activity

          @native = JNIHelpers.new_widget(env, "android/widget/SeekBar", activity)
          setup_seek_bar_listener(env)
        end
      {% elsif flag?(:native_ios) %}
        ptr = LibIOS.create_slider
        @native = ptr.to_i64
      {% end %}
    end

    def progress=(value : Int32)
      @progress = value.clamp(0, @max)
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0
          JNIHelpers.set_progress(env, @native, @progress)
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.slider_set_value(@native, @progress, @max)
      {% end %}
    end

    def progress : Int32
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return @progress if @native == 0
          @progress = JNIHelpers.get_progress(env, @native)
        end
      {% elsif flag?(:native_ios) %}
        value = LibIOS.slider_get_value(@native)
        @progress = (value * @max).to_i
      {% end %}
      @progress
    end

    def max=(value : Int32)
      @max = value
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0
          JNIHelpers.set_max(env, @native, @max)
        end
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

    def handle_progress_changed(progress : Int32)
      @progress = progress
      @on_progress_changed.try &.call(progress)
    end

    def handle_start_touch
      @on_start_touch.try &.call
    end

    def handle_stop_touch
      @on_stop_touch.try &.call
    end

    private def setup_seek_bar_listener(env : Native::Android::JNIEnvWrapper)
      {% unless flag?(:native_android) %}
        return
      {% end %}
      # TODO: Set up OnSeekBarChangeListener via callback
    end
  end
end
