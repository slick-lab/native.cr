# src/native/framework/media/video.cr
# Refactored to use JNIHelpers for automatic local reference cleanup.

module Native::Media
  class VideoPlayer < UI::View
    enum ScaleType
      FitXY
      FitCenter
      CenterCrop
    end

    @video_path : String = ""
    @is_playing : Bool = false
    @is_looping : Bool = false
    @volume : Float32 = 1.0
    @scale_type : ScaleType = ScaleType::FitCenter
    @on_prepared : (-> Nil)?
    @on_completion : (-> Nil)?
    @on_error : (String -> Nil)?
    @on_info : (Int32, Int32 -> Nil)?

    def initialize
      super()

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        video_class = env.find_class("com/nativecr/VideoPlayer")
        if video_class == Pointer(Void).null
          return
        end

        constructor = env.get_method_id(video_class, "<init>", "(Landroid/app/Activity;)V")
        @native = env.new_object(video_class, constructor, activity).to_i64
        env.delete_local_ref(video_class) unless video_class.null?

        setupCallbacks
      {% elsif flag?(:native_ios) %}
        ptr = LibIOS.create_video_player
        @native = ptr.to_i64
      {% end %}
    end

    def load(path : String)
      @video_path = path
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        JNIHelpers.call_void_string(env, @native, "loadVideo", "(Ljava/lang/String;)V", path)
      {% elsif flag?(:native_ios) %}
        LibIOS.video_player_load(@native, path.to_utf8)
      {% end %}
    end

    def play
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        JNIHelpers.call_void(env, @native, "play", "()V")
        @is_playing = true
      {% elsif flag?(:native_ios) %}
        LibIOS.video_player_play(@native)
        @is_playing = true
      {% end %}
    end

    def pause
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        JNIHelpers.call_void(env, @native, "pause", "()V")
        @is_playing = false
      {% elsif flag?(:native_ios) %}
        LibIOS.video_player_pause(@native)
        @is_playing = false
      {% end %}
    end

    def stop
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        JNIHelpers.call_void(env, @native, "stop", "()V")
        @is_playing = false
      {% elsif flag?(:native_ios) %}
        LibIOS.video_player_stop(@native)
        @is_playing = false
      {% end %}
    end

    def playing? : Bool
      @is_playing
    end

    def looping=(value : Bool)
      @is_looping = value
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        JNIHelpers.call_void(env, @native, "setLooping", "(Z)V", value)
      {% elsif flag?(:native_ios) %}
        LibIOS.video_player_set_looping(@native, value)
      {% end %}
    end

    def looping? : Bool
      @is_looping
    end

    def volume=(value : Float32)
      @volume = value.clamp(0.0, 1.0)
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        JNIHelpers.call_void(env, @native, "setVolume", "(FF)V", @volume, @volume)
      {% elsif flag?(:native_ios) %}
        LibIOS.video_player_set_volume(@native, @volume)
      {% end %}
    end

    def volume : Float32
      @volume
    end

    def scale_type=(value : ScaleType)
      @scale_type = value
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        scale_value = case value
                      when ScaleType::FitXY      then 0
                      when ScaleType::FitCenter  then 1
                      when ScaleType::CenterCrop then 2
                      end
        JNIHelpers.call_void(env, @native, "setScaleType", "(I)V", scale_value)
      {% elsif flag?(:native_ios) %}
        LibIOS.video_player_set_scale_type(@native, value.value)
      {% end %}
    end

    def scale_type : ScaleType
      @scale_type
    end

    def seek_to(msec : Int32)
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        JNIHelpers.call_void(env, @native, "seekTo", "(I)V", msec)
      {% elsif flag?(:native_ios) %}
        LibIOS.video_player_seek_to(@native, msec)
      {% end %}
    end

    def current_position : Int32
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return 0 unless env && @native != 0
        JNIHelpers.call_int(env, @native, "getCurrentPosition", "()I")
      {% elsif flag?(:native_ios) %}
        LibIOS.video_player_current_position(@native)
      {% else %}
        0
      {% end %}
    end

    def duration : Int32
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return 0 unless env && @native != 0
        JNIHelpers.call_int(env, @native, "getDuration", "()I")
      {% elsif flag?(:native_ios) %}
        LibIOS.video_player_duration(@native)
      {% else %}
        0
      {% end %}
    end

    def on_prepared(&block : -> Nil)
      @on_prepared = block
    end

    def on_completion(&block : -> Nil)
      @on_completion = block
    end

    def on_error(&block : String -> Nil)
      @on_error = block
    end

    def on_info(&block : Int32, Int32 -> Nil)
      @on_info = block
    end

    private def setupCallbacks
      {% unless flag?(:native_android) %}
        return
      {% end %}
      env = Native::Android::JNI.env
      return unless env && @native != 0

      callback_obj = JNIHelpers.new_callback(env, "com/nativecr/VideoPlayerCallback", 0i64)
      return if callback_obj.null?

      begin
        JNIHelpers.call_void(env, @native, "setCallback", "(Lcom/nativecr/VideoPlayerCallback;)V", callback_obj)
      ensure
        env.delete_local_ref(callback_obj)
      end
    end

    def handlePrepared
      @on_prepared.try &.call
    end

    def handleCompletion
      @is_playing = false
      @on_completion.try &.call
    end

    def handleError(error : String)
      @on_error.try &.call(error)
    end

    def handleInfo(what : Int32, extra : Int32)
      @on_info.try &.call(what, extra)
    end
  end
end
