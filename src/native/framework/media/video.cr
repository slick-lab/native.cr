# src/native/framework/media/video.cr

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

        video_class = env.FindClass("com/nativecr/VideoPlayer")
        if video_class == Pointer(Void).null
          return
        end

        constructor = env.GetMethodID(video_class, "<init>", "(Landroid/app/Activity;)V")
        @native = env.NewObject(video_class, constructor, activity).to_i64

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
        load_video = env.GetMethodID(env.GetObjectClass(@native), "loadVideo", "(Ljava/lang/String;)V")
        env.CallVoidMethod(@native, load_video, env.NewStringUTF(path))
      {% elsif flag?(:native_ios) %}
        LibIOS.video_player_load(@native, path.to_utf8)
      {% end %}
    end

    def play
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        play_video = env.GetMethodID(env.GetObjectClass(@native), "play", "()V")
        env.CallVoidMethod(@native, play_video)
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
        pause_video = env.GetMethodID(env.GetObjectClass(@native), "pause", "()V")
        env.CallVoidMethod(@native, pause_video)
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
        stop_video = env.GetMethodID(env.GetObjectClass(@native), "stop", "()V")
        env.CallVoidMethod(@native, stop_video)
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
        set_loop = env.GetMethodID(env.GetObjectClass(@native), "setLooping", "(Z)V")
        env.CallVoidMethod(@native, set_loop, value)
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
        set_volume = env.GetMethodID(env.GetObjectClass(@native), "setVolume", "(FF)V")
        env.CallVoidMethod(@native, set_volume, @volume, @volume)
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
        set_scale = env.GetMethodID(env.GetObjectClass(@native), "setScaleType", "(I)V")
        env.CallVoidMethod(@native, set_scale, scale_value)
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
        seek = env.GetMethodID(env.GetObjectClass(@native), "seekTo", "(I)V")
        env.CallVoidMethod(@native, seek, msec)
      {% elsif flag?(:native_ios) %}
        LibIOS.video_player_seek_to(@native, msec)
      {% end %}
    end

    def current_position : Int32
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return 0 unless env && @native != 0
        get_pos = env.GetMethodID(env.GetObjectClass(@native), "getCurrentPosition", "()I")
        env.CallIntMethod(@native, get_pos)
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
        get_dur = env.GetMethodID(env.GetObjectClass(@native), "getDuration", "()I")
        env.CallIntMethod(@native, get_dur)
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

      callback_class = env.FindClass("com/nativecr/VideoPlayerCallback")
      if callback_class == Pointer(Void).null
        return
      end

      callback_obj = env.NewObject(callback_class, env.GetMethodID(callback_class, "<init>", "(J)V"), Pointer(Void).address.to_i64)

      set_callback = env.GetMethodID(env.GetObjectClass(@native), "setCallback", "(Lcom/nativecr/VideoPlayerCallback;)V")
      env.CallVoidMethod(@native, set_callback, callback_obj)
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
