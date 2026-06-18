# src/native/framework/audio.cr

module Native::Audio
  enum AudioFormat
    PCM16
    PCM8
    AAC
    MP3
  end

  struct SoundConfig
    property volume : Float32 = 1.0
    property loop : Bool = false
    property pitch : Float32 = 1.0
    property pan : Float32 = 0.0

    def initialize(@volume = 1.0, @loop = false, @pitch = 1.0, @pan = 0.0)
    end
  end

  class Sound
    @sound_ptr : Int64 = 0
    @duration : Float64 = 0.0
    @is_loaded : Bool = false

    def initialize(path : String)
      load(path)
    end

    def load(path : String) : Bool
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return false unless env && activity

        sound_class = env.find_class("com/nativecr/SoundPlayer")
        if sound_class == Pointer(Void).null
          return false
        end

        load_method = env.get_static_method_id(sound_class, "load", "(Landroid/app/Activity;Ljava/lang/String;)J")
        if load_method == Pointer(Void).null
          return false
        end

        @sound_ptr = env.call_static_long_method(sound_class, load_method, activity, env.new_string_utf(path))
        @is_loaded = @sound_ptr != 0
        @is_loaded
      {% elsif flag?(:native_ios) %}
        ptr = LibIOS.sound_load(path.to_utf8)
        @sound_ptr = ptr.to_i64
        @is_loaded = ptr != Pointer(Void).null
        @is_loaded
      {% else %}
        false
      {% end %}
    end

    def play(config : SoundConfig = SoundConfig.new) : SoundInstance?
      return nil unless @is_loaded

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return nil unless env

        sound_class = env.find_class("com/nativecr/SoundPlayer")
        if sound_class == Pointer(Void).null
          return nil
        end

        play_method = env.get_static_method_id(sound_class, "play", "(JFIFF)J")
        if play_method == Pointer(Void).null
          return nil
        end

        instance_ptr = env.call_static_long_method(sound_class, play_method, @sound_ptr, config.volume, config.loop ? 1 : 0, config.pitch, config.pan)
        if instance_ptr != 0
          SoundInstance.new(instance_ptr)
        else
          nil
        end
      {% elsif flag?(:native_ios) %}
        ptr = LibIOS.sound_play(@sound_ptr, config.volume, config.loop, config.pitch, config.pan)
        if ptr != Pointer(Void).null
          SoundInstance.new(ptr.to_i64)
        else
          nil
        end
      {% else %}
        nil
      {% end %}
    end

    def stop_all : Nil
      return unless @is_loaded

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env

        sound_class = env.find_class("com/nativecr/SoundPlayer")
        if sound_class != Pointer(Void).null
          stop_method = env.get_static_method_id(sound_class, "stopAll", "(J)V")
          if stop_method != Pointer(Void).null
            env.call_static_void_method(sound_class, stop_method, @sound_ptr)
          end
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.sound_stop_all(@sound_ptr)
      {% end %}
    end

    def duration : Float64
      @duration
    end

    def loaded? : Bool
      @is_loaded
    end

    def unload : Nil
      return unless @is_loaded

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env

        sound_class = env.find_class("com/nativecr/SoundPlayer")
        if sound_class != Pointer(Void).null
          unload_method = env.get_static_method_id(sound_class, "unload", "(J)V")
          if unload_method != Pointer(Void).null
            env.call_static_void_method(sound_class, unload_method, @sound_ptr)
          end
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.sound_unload(@sound_ptr)
      {% end %}

      @sound_ptr = 0
      @is_loaded = false
    end
  end

  class SoundInstance
    @instance_ptr : Int64
    @is_playing : Bool = true

    def initialize(@instance_ptr : Int64)
    end

    def stop : Nil
      return unless @is_playing

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env

        sound_class = env.find_class("com/nativecr/SoundPlayer")
        if sound_class != Pointer(Void).null
          stop_method = env.get_static_method_id(sound_class, "stopInstance", "(J)V")
          if stop_method != Pointer(Void).null
            env.call_static_void_method(sound_class, stop_method, @instance_ptr)
          end
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.sound_instance_stop(@instance_ptr)
      {% end %}

      @is_playing = false
    end

    def pause : Nil
      return unless @is_playing

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env

        sound_class = env.find_class("com/nativecr/SoundPlayer")
        if sound_class != Pointer(Void).null
          pause_method = env.get_static_method_id(sound_class, "pause", "(J)V")
          if pause_method != Pointer(Void).null
            env.call_static_void_method(sound_class, pause_method, @instance_ptr)
          end
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.sound_instance_pause(@instance_ptr)
      {% end %}
    end

    def resume : Nil
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env

        sound_class = env.find_class("com/nativecr/SoundPlayer")
        if sound_class != Pointer(Void).null
          resume_method = env.get_static_method_id(sound_class, "resume", "(J)V")
          if resume_method != Pointer(Void).null
            env.call_static_void_method(sound_class, resume_method, @instance_ptr)
          end
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.sound_instance_resume(@instance_ptr)
      {% end %}

      @is_playing = true
    end

    def volume=(value : Float32)
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env

        sound_class = env.find_class("com/nativecr/SoundPlayer")
        if sound_class != Pointer(Void).null
          volume_method = env.get_static_method_id(sound_class, "setVolume", "(JF)V")
          if volume_method != Pointer(Void).null
            env.call_static_void_method(sound_class, volume_method, @instance_ptr, value)
          end
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.sound_instance_set_volume(@instance_ptr, value)
      {% end %}
    end

    def is_playing? : Bool
      return false unless @is_playing

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return false unless env

        sound_class = env.find_class("com/nativecr/SoundPlayer")
        if sound_class != Pointer(Void).null
          playing_method = env.get_static_method_id(sound_class, "isPlaying", "(J)Z")
          if playing_method != Pointer(Void).null
            return env.call_static_boolean_method(sound_class, playing_method, @instance_ptr)
          end
        end
        false
      {% elsif flag?(:native_ios) %}
        LibIOS.sound_instance_is_playing(@instance_ptr)
      {% else %}
        false
      {% end %}
    end
  end

  class MusicPlayer
    @music_ptr : Int64 = 0
    @is_playing : Bool = false
    @volume : Float32 = 1.0

    def initialize(path : String)
      load(path)
    end

    def load(path : String) : Bool
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return false unless env && activity

        music_class = env.find_class("com/nativecr/MusicPlayer")
        if music_class == Pointer(Void).null
          return false
        end

        load_method = env.get_static_method_id(music_class, "load", "(Landroid/app/Activity;Ljava/lang/String;)J")
        if load_method == Pointer(Void).null
          return false
        end

        @music_ptr = env.call_static_long_method(music_class, load_method, activity, env.new_string_utf(path))
        @music_ptr != 0
      {% elsif flag?(:native_ios) %}
        ptr = LibIOS.music_load(path.to_utf8)
        @music_ptr = ptr.to_i64
        ptr != Pointer(Void).null
      {% else %}
        false
      {% end %}
    end

    def play(loop : Bool = false) : Nil
      return if @music_ptr == 0

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env

        music_class = env.find_class("com/nativecr/MusicPlayer")
        if music_class != Pointer(Void).null
          play_method = env.get_static_method_id(music_class, "play", "(JZ)V")
          if play_method != Pointer(Void).null
            env.call_static_void_method(music_class, play_method, @music_ptr, loop)
          end
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.music_play(@music_ptr, loop)
      {% end %}

      @is_playing = true
    end

    def pause : Nil
      return if @music_ptr == 0 || !@is_playing

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env

        music_class = env.find_class("com/nativecr/MusicPlayer")
        if music_class != Pointer(Void).null
          pause_method = env.get_static_method_id(music_class, "pause", "(J)V")
          if pause_method != Pointer(Void).null
            env.call_static_void_method(music_class, pause_method, @music_ptr)
          end
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.music_pause(@music_ptr)
      {% end %}

      @is_playing = false
    end

    def resume : Nil
      return if @music_ptr == 0 || @is_playing

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env

        music_class = env.find_class("com/nativecr/MusicPlayer")
        if music_class != Pointer(Void).null
          resume_method = env.get_static_method_id(music_class, "resume", "(J)V")
          if resume_method != Pointer(Void).null
            env.call_static_void_method(music_class, resume_method, @music_ptr)
          end
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.music_resume(@music_ptr)
      {% end %}

      @is_playing = true
    end

    def stop : Nil
      return if @music_ptr == 0

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env

        music_class = env.find_class("com/nativecr/MusicPlayer")
        if music_class != Pointer(Void).null
          stop_method = env.get_static_method_id(music_class, "stop", "(J)V")
          if stop_method != Pointer(Void).null
            env.call_static_void_method(music_class, stop_method, @music_ptr)
          end
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.music_stop(@music_ptr)
      {% end %}

      @is_playing = false
    end

    def volume=(value : Float32)
      @volume = value.clamp(0.0, 1.0)

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env

        music_class = env.find_class("com/nativecr/MusicPlayer")
        if music_class != Pointer(Void).null
          volume_method = env.get_static_method_id(music_class, "setVolume", "(JF)V")
          if volume_method != Pointer(Void).null
            env.call_static_void_method(music_class, volume_method, @music_ptr, @volume)
          end
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.music_set_volume(@music_ptr, @volume)
      {% end %}
    end

    def volume : Float32
      @volume
    end

    def is_playing? : Bool
      @is_playing
    end

    def seek(position : Float64) : Nil
      return if @music_ptr == 0

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env

        music_class = env.find_class("com/nativecr/MusicPlayer")
        if music_class != Pointer(Void).null
          seek_method = env.get_static_method_id(music_class, "seek", "(JD)V")
          if seek_method != Pointer(Void).null
            env.call_static_void_method(music_class, seek_method, @music_ptr, position)
          end
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.music_seek(@music_ptr, position)
      {% end %}
    end

    def current_position : Float64
      return 0.0 if @music_ptr == 0

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return 0.0 unless env

        music_class = env.find_class("com/nativecr/MusicPlayer")
        if music_class != Pointer(Void).null
          position_method = env.get_static_method_id(music_class, "getPosition", "(J)D")
          if position_method != Pointer(Void).null
            return env.call_static_double_method(music_class, position_method, @music_ptr)
          end
        end
        0.0
      {% elsif flag?(:native_ios) %}
        LibIOS.music_get_position(@music_ptr)
      {% else %}
        0.0
      {% end %}
    end

    def duration : Float64
      return 0.0 if @music_ptr == 0

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return 0.0 unless env

        music_class = env.find_class("com/nativecr/MusicPlayer")
        if music_class != Pointer(Void).null
          duration_method = env.get_static_method_id(music_class, "getDuration", "(J)D")
          if duration_method != Pointer(Void).null
            return env.call_static_double_method(music_class, duration_method, @music_ptr)
          end
        end
        0.0
      {% elsif flag?(:native_ios) %}
        LibIOS.music_get_duration(@music_ptr)
      {% else %}
        0.0
      {% end %}
    end

    def unload : Nil
      stop

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env

        music_class = env.find_class("com/nativecr/MusicPlayer")
        if music_class != Pointer(Void).null
          unload_method = env.get_static_method_id(music_class, "unload", "(J)V")
          if unload_method != Pointer(Void).null
            env.call_static_void_method(music_class, unload_method, @music_ptr)
          end
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.music_unload(@music_ptr)
      {% end %}

      @music_ptr = 0
    end
  end

  class AudioRecorder
    @recorder_ptr : Int64 = 0
    @is_recording : Bool = false

    def initialize
    end

    def start : Bool
      return false if @is_recording

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return false unless env && activity

        recorder_class = env.find_class("com/nativecr/AudioRecorder")
        if recorder_class == Pointer(Void).null
          return false
        end

        start_method = env.get_static_method_id(recorder_class, "start", "(Landroid/app/Activity;)J")
        if start_method == Pointer(Void).null
          return false
        end

        @recorder_ptr = env.call_static_long_method(recorder_class, start_method, activity)
        @is_recording = @recorder_ptr != 0
        @is_recording
      {% elsif flag?(:native_ios) %}
        ptr = LibIOS.recorder_start
        @recorder_ptr = ptr.to_i64
        @is_recording = ptr != Pointer(Void).null
        @is_recording
      {% else %}
        false
      {% end %}
    end

    def stop : Bytes?
      return nil unless @is_recording && @recorder_ptr != 0

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return nil unless env

        recorder_class = env.find_class("com/nativecr/AudioRecorder")
        if recorder_class == Pointer(Void).null
          return nil
        end

        stop_method = env.get_static_method_id(recorder_class, "stop", "(J)[B")
        if stop_method == Pointer(Void).null
          return nil
        end

        byte_array = env.call_static_object_method(recorder_class, stop_method, @recorder_ptr)
        @is_recording = false
        @recorder_ptr = 0

        if byte_array
          length = env.get_array_length(byte_array)
          data = Bytes.new(length)
          env.get_byte_array_region(byte_array, 0, length, data)
          env.delete_local_ref(byte_array)
          data
        else
          nil
        end
      {% elsif flag?(:native_ios) %}
        size_ptr = Pointer(Int32).malloc(1)
        data_ptr = LibIOS.recorder_stop(@recorder_ptr, size_ptr)
        @is_recording = false
        @recorder_ptr = 0

        if data_ptr && size_ptr.value > 0
          data = Bytes.new(size_ptr.value) { |i| data_ptr[i] }
          LibIOS.free(data_ptr)
          data
        else
          nil
        end
      {% else %}
        nil
      {% end %}
    end

    def is_recording? : Bool
      @is_recording
    end
  end

  module AudioMixer
    @@master_volume : Float32 = 1.0
    @@music_volume : Float32 = 1.0
    @@sfx_volume : Float32 = 1.0

    def self.master_volume=(value : Float32)
      @@master_volume = value.clamp(0.0, 1.0).to_f32
      apply_volumes
    end

    def self.master_volume : Float32
      @@master_volume
    end

    def self.music_volume=(value : Float32)
      @@music_volume = value.clamp(0.0, 1.0)
      apply_volumes
    end

    def self.music_volume : Float32
      @@music_volume
    end

    def self.sfx_volume=(value : Float32)
      @@sfx_volume = value.clamp(0.0, 1.0)
      apply_volumes
    end

    def self.sfx_volume : Float32
      @@sfx_volume
    end

    private def self.apply_volumes
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env

        audio_class = env.find_class("com/nativecr/AudioMixer")
        if audio_class != Pointer(Void).null
          set_volume_method = env.get_static_method_id(audio_class, "setMasterVolume", "(F)V")
          if set_volume_method != Pointer(Void).null
            env.call_static_void_method(audio_class, set_volume_method, @master_volume)
          end
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.set_master_volume(@master_volume)
        LibIOS.set_music_volume(@music_volume)
        LibIOS.set_sfx_volume(@sfx_volume)
      {% end %}
    end
  end

  module Audio
    def self.play_sound(path : String, volume : Float32 = 1.0) : SoundInstance?
      sound = Sound.new(path)
      sound.play(SoundConfig.new(volume: volume))
    end

    def self.play_music(path : String, loop : Bool = true) : MusicPlayer
      player = MusicPlayer.new(path)
      player.play(loop)
      player
    end

    def self.stop_all : Nil
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env

        audio_class = env.find_class("com/nativecr/AudioMixer")
        if audio_class != Pointer(Void).null
          stop_method = env.get_static_method_id(audio_class, "stopAll", "()V")
          if stop_method != Pointer(Void).null
            env.call_static_void_method(audio_class, stop_method)
          end
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.stop_all_sounds
        LibIOS.stop_music
      {% end %}
    end

    def self.pause_all : Nil
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env

        audio_class = env.find_class("com/nativecr/AudioMixer")
        if audio_class != Pointer(Void).null
          pause_method = env.get_static_method_id(audio_class, "pauseAll", "()V")
          if pause_method != Pointer(Void).null
            env.call_static_void_method(audio_class, pause_method)
          end
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.pause_all_sounds
        LibIOS.pause_music
      {% end %}
    end

    def self.resume_all : Nil
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env

        audio_class = env.find_class("com/nativecr/AudioMixer")
        if audio_class != Pointer(Void).null
          resume_method = env.get_static_method_id(audio_class, "resumeAll", "()V")
          if resume_method != Pointer(Void).null
            env.call_static_void_method(audio_class, resume_method)
          end
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.resume_all_sounds
        LibIOS.resume_music
      {% end %}
    end
  end
end
