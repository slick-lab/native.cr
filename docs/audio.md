# Audio

native.cr provides three audio classes and a convenient `Audio` module for playing sound effects, streaming music, and recording audio.

---

## Quick play — one-liners

```crystal
# Play a sound effect once
Native::Audio::Audio.play_sound("assets/click.wav")

# Play background music (loops by default)
player = Native::Audio::Audio.play_music("assets/background.mp3")

# Stop everything
Native::Audio::Audio.stop_all

# Pause/resume everything (useful when app is backgrounded)
Native::Audio::Audio.pause_all
Native::Audio::Audio.resume_all
```

---

## Sound effects (`Native::Audio::Sound`)

`Sound` is for short audio clips — button taps, game sounds, alerts.

```crystal
# Load the file once (at app startup)
sound = Native::Audio::Sound.new("assets/explosion.wav")
puts sound.loaded?   # => true

# Play it (can overlap — plays multiple instances at once)
instance = sound.play
```

### Play with options

```crystal
config = Native::Audio::SoundConfig.new(
  volume: 0.8,   # 0.0 (silent) to 1.0 (full volume)
  loop: false,   # loop the sound?
  pitch: 1.2,    # 1.0 = normal, 2.0 = double speed/pitch
  pan: -0.5      # -1.0 (left) to 1.0 (right), 0 = centre
)

instance = sound.play(config)
```

### Controlling a playing instance

```crystal
instance.stop
instance.pause
instance.resume
instance.volume = 0.5
instance.is_playing?   # => Bool
```

### Stop all instances of a sound

```crystal
sound.stop_all
```

### Unload when done

```crystal
sound.unload   # free memory
```

---

## Music player (`Native::Audio::MusicPlayer`)

`MusicPlayer` is for long audio — background music, podcasts, narration. It streams instead of loading the whole file into memory.

```crystal
player = Native::Audio::MusicPlayer.new("assets/theme.mp3")
player.play                  # start playing
player.play(loop: true)      # loop forever

player.pause
player.resume
player.stop

player.volume = 0.7          # 0.0 – 1.0
player.seek(30.5)            # jump to 30.5 seconds
puts player.current_position # current time in seconds
puts player.duration         # total length in seconds
puts player.is_playing?

player.unload                # release resources
```

---

## Audio recorder (`Native::Audio::AudioRecorder`)

Record audio from the microphone.

> **Remember:** You need microphone permission first. See the [Permissions guide](./permissions.md).

```crystal
recorder = Native::Audio::AudioRecorder.new

# Start recording
if recorder.start
  puts "Recording..."
end

# ... after some time ...

# Stop and get the recorded audio bytes
if audio_data = recorder.stop
  puts "Recorded #{audio_data.size} bytes"

  # Save to file
  storage = Native::Storage::FileStorage.new(
    Native::Storage::FileStorage::StorageType::Documents
  )
  storage.write("recording.pcm", audio_data)
else
  puts "Recording failed or nothing was recorded"
end

puts recorder.is_recording?   # => Bool
```

---

## Volume mixer (`Native::Audio::AudioMixer`)

Control global volume levels:

```crystal
Native::Audio::AudioMixer.master_volume = 0.8   # affects everything
Native::Audio::AudioMixer.music_volume  = 0.5   # affects music only
Native::Audio::AudioMixer.sfx_volume    = 1.0   # affects sound effects only

puts Native::Audio::AudioMixer.master_volume
```

---

## Real example — game with sounds

```crystal
class GameApp < Native::App
  def setup
    @jump_sound = Native::Audio::Sound.new("assets/jump.wav")
    @coin_sound = Native::Audio::Sound.new("assets/coin.wav")
    @music = Native::Audio::MusicPlayer.new("assets/bgm.mp3")
    @music.play(loop: true)
    @music.volume = 0.6
  end

  def on_pause
    @music.pause
    Native::Audio::Audio.pause_all
  end

  def on_resume
    @music.resume
    Native::Audio::Audio.resume_all
  end

  def on_destroy
    @jump_sound.unload
    @coin_sound.unload
    @music.unload
  end

  def player_jumped
    @jump_sound.play
  end

  def coin_collected
    config = Native::Audio::SoundConfig.new(volume: 0.9, pitch: 1.3)
    @coin_sound.play(config)
  end
end
```

---

## Tips

- Load sounds **once** in `setup`, not in every frame.
- Use `Sound` for short clips, `MusicPlayer` for long tracks.
- Always `unload` audio in `on_destroy` to free memory.
- Pause audio in `on_pause` — playing audio in the background may be interrupted by the OS anyway and wastes battery.
