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

        video_class = env.find_class("com/nativecr/VideoPlayer")
        if video_class == Pointer(Void).null
          return
        end

        constructor = env.get_method_id(video_class, "<init>", "(Landroid/app/Activity;)V")
        @native = env.new_object(video_class, constructor, activity).to_i64

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
        load_video = env.get_method_id(env.get_object_class(@native), "loadVideo", "(Ljava/lang/String;)V")
        env.call_void_method(@native, load_video, env.new_string_utf(path))
      {% elsif flag?(:native_ios) %}
        LibIOS.video_player_load(@native, path.to_utf8)
      {% end %}
    end

    def play
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        play_video = env.get_method_id(env.get_object_class(@native), "play", "()V")
        env.call_void_method(@native, play_video)
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
        pause_video = env.get_method_id(env.get_object_class(@native), "pause", "()V")
        env.call_void_method(@native, pause_video)
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
        stop_video = env.get_method_id(env.get_object_class(@native), "stop", "()V")
        env.call_void_method(@native, stop_video)
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
        set_loop = env.get_method_id(env.get_object_class(@native), "setLooping", "(Z)V")
        env.call_void_method(@native, set_loop, value)
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
        set_volume = env.get_method_id(env.get_object_class(@native), "setVolume", "(FF)V")
        env.call_void_method(@native, set_volume, @volume, @volume)
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
        set_scale = env.get_method_id(env.get_object_class(@native), "setScaleType", "(I)V")
        env.call_void_method(@native, set_scale, scale_value)
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
        seek = env.get_method_id(env.get_object_class(@native), "seekTo", "(I)V")
        env.call_void_method(@native, seek, msec)
      {% elsif flag?(:native_ios) %}
        LibIOS.video_player_seek_to(@native, msec)
      {% end %}
    end

    def current_position : Int32
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return 0 unless env && @native != 0
        get_pos = env.get_method_id(env.get_object_class(@native), "getCurrentPosition", "()I")
        env.call_int_method(@native, get_pos)
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
        get_dur = env.get_method_id(env.get_object_class(@native), "getDuration", "()I")
        env.call_int_method(@native, get_dur)
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

      callback_class = env.find_class("com/nativecr/VideoPlayerCallback")
      if callback_class == Pointer(Void).null
        return
      end

      callback_obj = env.new_object(callback_class, env.get_method_id(callback_class, "<init>", "(J)V"), 0i64)

      set_callback = env.get_method_id(env.get_object_class(@native), "setCallback", "(Lcom/nativecr/VideoPlayerCallback;)V")
      env.call_void_method(@native, set_callback, callback_obj)
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
