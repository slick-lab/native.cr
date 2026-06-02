# src/native/framework/audio.cr

module Native
  module Audio
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
      @sound_ptr : Void*? = nil
      @duration : Float64 = 0.0
      @is_loaded : Bool = false

      def initialize(path : String)
        load(path)
      end

      def initialize(data : Bytes, format : AudioFormat)
        load_from_memory(data, format)
      end

      def load(path : String) : Bool
        {{ if flag?(:android) }}
          result = load_android(path)
        {{ elsif flag?(:ios) }}
          result = load_ios(path)
        {{ else }}
          result = false
        {{ end }}
        
        @is_loaded = result
        result
      end

      def load_from_memory(data : Bytes, format : AudioFormat) : Bool
        {{ if flag?(:android) }}
          result = load_memory_android(data, format)
        {{ elsif flag?(:ios) }}
          result = load_memory_ios(data, format)
        {{ else }}
          result = false
        {{ end }}
        
        @is_loaded = result
        result
      end

      def play(config : SoundConfig = SoundConfig.new) : SoundInstance?
        return nil unless @is_loaded && @sound_ptr
        
        {{ if flag?(:android) }}
          instance_ptr = LibAudio.sound_play(@sound_ptr, config.volume, config.loop, config.pitch, config.pan)
        {{ elsif flag?(:ios) }}
          instance_ptr = LibAudio.sound_play(@sound_ptr, config.volume, config.loop, config.pitch, config.pan)
        {{ else }}
          return nil
        {{ end }}
        
        instance_ptr ? SoundInstance.new(instance_ptr) : nil
      end

      def stop_all : Nil
        return unless @is_loaded && @sound_ptr
        
        {{ if flag?(:android) }}
          LibAudio.sound_stop_all(@sound_ptr)
        {{ elsif flag?(:ios) }}
          LibAudio.sound_stop_all(@sound_ptr)
        {{ end }}
      end

      def duration : Float64
        @duration
      end

      def loaded? : Bool
        @is_loaded
      end

      def unload : Nil
        return unless @is_loaded && @sound_ptr
        
        {{ if flag?(:android) }}
          LibAudio.sound_unload(@sound_ptr)
        {{ elsif flag?(:ios) }}
          LibAudio.sound_unload(@sound_ptr)
        {{ end }}
        
        @sound_ptr = nil
        @is_loaded = false
      end

      private def load_android(path : String) : Bool
        ptr = LibAndroid.sound_load(path.to_utf8)
        if ptr
          @sound_ptr = ptr
          @duration = LibAndroid.sound_get_duration(ptr)
          true
        else
          false
        end
      end

      private def load_ios(path : String) : Bool
        ptr = LibIOS.sound_load(path.to_utf8)
        if ptr
          @sound_ptr = ptr
          @duration = LibIOS.sound_get_duration(ptr)
          true
        else
          false
        end
      end

      private def load_memory_android(data : Bytes, format : AudioFormat) : Bool
        ptr = LibAndroid.sound_load_memory(data, data.size, format.to_i32)
        if ptr
          @sound_ptr = ptr
          @duration = LibAndroid.sound_get_duration(ptr)
          true
        else
          false
        end
      end

      private def load_memory_ios(data : Bytes, format : AudioFormat) : Bool
        ptr = LibIOS.sound_load_memory(data, data.size, format.to_i32)
        if ptr
          @sound_ptr = ptr
          @duration = LibIOS.sound_get_duration(ptr)
          true
        else
          false
        end
      end
    end

    class SoundInstance
      @instance_ptr : Void*
      @is_playing : Bool = true

      def initialize(@instance_ptr : Void*)
      end

      def stop : Nil
        return unless @is_playing
        
        {{ if flag?(:android) }}
          LibAudio.sound_instance_stop(@instance_ptr)
        {{ elsif flag?(:ios) }}
          LibAudio.sound_instance_stop(@instance_ptr)
        {{ end }}
        
        @is_playing = false
      end

      def pause : Nil
        return unless @is_playing
        
        {{ if flag?(:android) }}
          LibAudio.sound_instance_pause(@instance_ptr)
        {{ elsif flag?(:ios) }}
          LibAudio.sound_instance_pause(@instance_ptr)
        {{ end }}
      end

      def resume : Nil
        {{ if flag?(:android) }}
          LibAudio.sound_instance_resume(@instance_ptr)
        {{ elsif flag?(:ios) }}
          LibAudio.sound_instance_resume(@instance_ptr)
        {{ end }}
        
        @is_playing = true
      end

      def volume=(value : Float32)
        {{ if flag?(:android) }}
          LibAudio.sound_instance_set_volume(@instance_ptr, value)
        {{ elsif flag?(:ios) }}
          LibAudio.sound_instance_set_volume(@instance_ptr, value)
        {{ end }}
      end

      def pitch=(value : Float32)
        {{ if flag?(:android) }}
          LibAudio.sound_instance_set_pitch(@instance_ptr, value)
        {{ elsif flag?(:ios) }}
          LibAudio.sound_instance_set_pitch(@instance_ptr, value)
        {{ end }}
      end

      def is_playing? : Bool
        return false unless @is_playing
        
        {{ if flag?(:android) }}
          LibAudio.sound_instance_is_playing(@instance_ptr)
        {{ elsif flag?(:ios) }}
          LibAudio.sound_instance_is_playing(@instance_ptr)
        {{ else }}
          false
        {{ end }}
      end
    end

    class MusicPlayer
      @music_ptr : Void*? = nil
      @is_playing : Bool = false
      @volume : Float32 = 1.0

      def initialize(path : String)
        load(path)
      end

      def load(path : String) : Bool
        {{ if flag?(:android) }}
          ptr = LibAndroid.music_load(path.to_utf8)
        {{ elsif flag?(:ios) }}
          ptr = LibIOS.music_load(path.to_utf8)
        {{ else }}
          ptr = nil
        {{ end }}
        
        if ptr
          @music_ptr = ptr
          true
        else
          false
        end
      end

      def play(loop : Bool = false) : Nil
        return unless @music_ptr
        
        {{ if flag?(:android) }}
          LibAudio.music_play(@music_ptr, loop)
        {{ elsif flag?(:ios) }}
          LibAudio.music_play(@music_ptr, loop)
        {{ end }}
        
        @is_playing = true
      end

      def pause : Nil
        return unless @music_ptr && @is_playing
        
        {{ if flag?(:android) }}
          LibAudio.music_pause(@music_ptr)
        {{ elsif flag?(:ios) }}
          LibAudio.music_pause(@music_ptr)
        {{ end }}
        
        @is_playing = false
      end

      def resume : Nil
        return unless @music_ptr && !@is_playing
        
        {{ if flag?(:android) }}
          LibAudio.music_resume(@music_ptr)
        {{ elsif flag?(:ios) }}
          LibAudio.music_resume(@music_ptr)
        {{ end }}
        
        @is_playing = true
      end

      def stop : Nil
        return unless @music_ptr
        
        {{ if flag?(:android) }}
          LibAudio.music_stop(@music_ptr)
        {{ elsif flag?(:ios) }}
          LibAudio.music_stop(@music_ptr)
        {{ end }}
        
        @is_playing = false
      end

      def volume=(value : Float32)
        @volume = value.clamp(0.0, 1.0)
        
        {{ if flag?(:android) }}
          LibAudio.music_set_volume(@music_ptr, @volume)
        {{ elsif flag?(:ios) }}
          LibAudio.music_set_volume(@music_ptr, @volume)
        {{ end }}
      end

      def volume : Float32
        @volume
      end

      def is_playing? : Bool
        @is_playing
      end

      def seek(position : Float64) : Nil
        return unless @music_ptr
        
        {{ if flag?(:android) }}
          LibAudio.music_seek(@music_ptr, position)
        {{ elsif flag?(:ios) }}
          LibAudio.music_seek(@music_ptr, position)
        {{ end }}
      end

      def current_position : Float64
        return 0.0 unless @music_ptr
        
        {{ if flag?(:android) }}
          LibAudio.music_get_position(@music_ptr)
        {{ elsif flag?(:ios) }}
          LibAudio.music_get_position(@music_ptr)
        {{ else }}
          0.0
        {{ end }}
      end

      def duration : Float64
        return 0.0 unless @music_ptr
        
        {{ if flag?(:android) }}
          LibAudio.music_get_duration(@music_ptr)
        {{ elsif flag?(:ios) }}
          LibAudio.music_get_duration(@music_ptr)
        {{ else }}
          0.0
        {{ end }}
      end

      def unload : Nil
        stop
        
        {{ if flag?(:android) }}
          LibAudio.music_unload(@music_ptr)
        {{ elsif flag?(:ios) }}
          LibAudio.music_unload(@music_ptr)
        {{ end }}
        
        @music_ptr = nil
      end
    end

    class AudioRecorder
      @recorder_ptr : Void*? = nil
      @is_recording : Bool = false

      def initialize
      end

      def start : Bool
        return false if @is_recording
        
        {{ if flag?(:android) }}
          @recorder_ptr = LibAndroid.recorder_start
        {{ elsif flag?(:ios) }}
          @recorder_ptr = LibIOS.recorder_start
        {{ else }}
          return false
        {{ end }}
        
        @is_recording = @recorder_ptr ? true : false
        @is_recording
      end

      def stop : Bytes?
        return nil unless @is_recording && @recorder_ptr
        
        {{ if flag?(:android) }}
          data_ptr = LibAndroid.recorder_stop(@recorder_ptr)
          size = LibAndroid.recorder_get_size(@recorder_ptr)
        {{ elsif flag?(:ios) }}
          data_ptr = LibIOS.recorder_stop(@recorder_ptr)
          size = LibIOS.recorder_get_size(@recorder_ptr)
        {{ else }}
          return nil
        {{ end }}
        
        @is_recording = false
        @recorder_ptr = nil
        
        if data_ptr && size > 0
          Bytes.new(size) { |i| data_ptr[i] }
        else
          nil
        end
      end

      def is_recording? : Bool
        @is_recording
      end
    end

    module AudioMixer
      @master_volume : Float32 = 1.0
      @music_volume : Float32 = 1.0
      @sfx_volume : Float32 = 1.0

      def self.master_volume=(value : Float32)
        @master_volume = value.clamp(0.0, 1.0)
        apply_volumes
      end

      def self.master_volume : Float32
        @master_volume
      end

      def self.music_volume=(value : Float32)
        @music_volume = value.clamp(0.0, 1.0)
        apply_volumes
      end

      def self.music_volume : Float32
        @music_volume
      end

      def self.sfx_volume=(value : Float32)
        @sfx_volume = value.clamp(0.0, 1.0)
        apply_volumes
      end

      def self.sfx_volume : Float32
        @sfx_volume
      end

      private def self.apply_volumes
        {{ if flag?(:android) }}
          LibAudio.set_master_volume(@master_volume * @music_volume)
          LibAudio.set_sfx_volume(@master_volume * @sfx_volume)
        {{ elsif flag?(:ios) }}
          LibAudio.set_master_volume(@master_volume * @music_volume)
          LibAudio.set_sfx_volume(@master_volume * @sfx_volume)
        {{ end }}
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
        {{ if flag?(:android) }}
          LibAudio.stop_all_sounds
          LibAudio.stop_music
        {{ elsif flag?(:ios) }}
          LibAudio.stop_all_sounds
          LibAudio.stop_music
        {{ end }}
      end

      def self.pause_all : Nil
        {{ if flag?(:android) }}
          LibAudio.pause_all_sounds
          LibAudio.pause_music
        {{ elsif flag?(:ios) }}
          LibAudio.pause_all_sounds
          LibAudio.pause_music
        {{ end }}
      end

      def self.resume_all : Nil
        {{ if flag?(:android) }}
          LibAudio.resume_all_sounds
          LibAudio.resume_music
        {{ elsif flag?(:ios) }}
          LibAudio.resume_all_sounds
          LibAudio.resume_music
        {{ end }}
      end
    end
  end
end
