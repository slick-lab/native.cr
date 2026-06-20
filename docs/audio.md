# Audio

native.cr provides three audio classes — for short sound effects, long music tracks, and microphone recording — plus a mixer for global volume control.

---

## Quick start — `Native::Audio::Audio`

One-liner helpers for the most common tasks:

```crystal
# Play a sound effect once
instance = Native::Audio::Audio.play_sound("assets/click.wav")
instance = Native::Audio::Audio.play_sound("assets/click.wav", volume: 0.8_f32)

# Play background music (loops by default)
player = Native::Audio::Audio.play_music("assets/background.mp3")
player = Native::Audio::Audio.play_music("assets/bg.mp3", loop: false)

# Pause / resume / stop everything at once
Native::Audio::Audio.pause_all
Native::Audio::Audio.resume_all
Native::Audio::Audio.stop_all
```

---

## `Native::Audio::Sound` — sound effects

`Sound` is optimised for **short clips** — button taps, game sounds, alerts. It loads the file into memory so it can be played immediately (even several overlapping instances at once).

### Load once, play many times

```crystal
# Load at app startup
@jump_sound = Native::Audio::Sound.new("assets/jump.wav")
@coin_sound = Native::Audio::Sound.new("assets/coin.wav")

puts @jump_sound.loaded?   # => true
```

### Play

```crystal
# Play with defaults (volume 1.0, no loop, normal pitch)
instance = @jump_sound.play

# Play with custom config
config = Native::Audio::SoundConfig.new(
  volume: 0.8_f32,   # 0.0 (silent) to 1.0 (full volume)
  loop:   false,     # loop the sound continuously?
  pitch:  1.3_f32,   # 1.0 = normal, 0.5 = half speed, 2.0 = double speed
  pan:    0.0_f32    # -1.0 (left) to 1.0 (right), 0.0 = centre
)
instance = @coin_sound.play(config)
```

`play` returns a `SoundInstance?` — `nil` if the sound is not loaded or playback failed.

### Controlling a playing instance

```crystal
instance = @music_sting.play

instance.stop
instance.pause
instance.resume
instance.volume = 0.3_f32
instance.is_playing?   # => Bool
```

### Stop all instances of a sound

```crystal
@jump_sound.stop_all   # stops every concurrent playback of this sound
```

### Unload when done

```crystal
@jump_sound.unload   # free the memory
```

---

## `Native::Audio::MusicPlayer` — background music

`MusicPlayer` **streams** the file instead of loading it entirely into memory, making it suitable for long tracks (music, podcasts, narration).

```crystal
player = Native::Audio::MusicPlayer.new("assets/theme.mp3")

# Playback control
player.play               # start from the beginning
player.play(loop: true)   # loop forever
player.pause
player.resume
player.stop

# Volume
player.volume = 0.7_f32   # 0.0–1.0 (automatically clamped)
puts player.volume

# Seeking (position in seconds)
player.seek(30.5)                 # jump to 30.5 seconds
puts player.current_position      # => Float64 (seconds)
puts player.duration              # => Float64 (total length in seconds)

# State
puts player.is_playing?    # => Bool

# Cleanup
player.unload
```

---

## `Native::Audio::AudioRecorder` — microphone recording

`AudioRecorder` captures audio from the microphone and returns raw PCM bytes.

> **Permission required.** Request `Microphone` permission first. See the [Permissions guide](./permissions.md).

```crystal
recorder = Native::Audio::AudioRecorder.new

# Start recording
if recorder.start
  puts "Recording…"
end

puts recorder.is_recording?   # => Bool

# ... after some time ...

# Stop and get the audio data
if audio_data = recorder.stop
  puts "Recorded #{audio_data.size} bytes"

  # Save to a file
  docs = Native::Storage::FileStorage.new(
    Native::Storage::FileStorage::StorageType::Documents
  )
  docs.write("recording_#{Time.utc.to_unix}.pcm", audio_data)
else
  puts "Recording failed or empty"
end
```

---

## `Native::Audio::AudioMixer` — global volume

Control the master, music, and sound-effects volume independently:

```crystal
Native::Audio::AudioMixer.master_volume = 0.8_f32  # affects everything
Native::Audio::AudioMixer.music_volume  = 0.5_f32  # affects MusicPlayer only
Native::Audio::AudioMixer.sfx_volume    = 1.0_f32  # affects Sound only

puts Native::Audio::AudioMixer.master_volume  # => 0.8
```

All values are clamped to `0.0–1.0`.

---

## Lifecycle best practices

```crystal
def on_pause
  @music.pause            # pause the music track
  Native::Audio::Audio.pause_all  # pause all sound effects too
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
```

---

## Full example — game audio system

```crystal
class GameApp < Native::App
  def setup
    # Load sound effects once
    @jump  = Native::Audio::Sound.new("assets/jump.wav")
    @coin  = Native::Audio::Sound.new("assets/coin.wav")
    @death = Native::Audio::Sound.new("assets/death.wav")

    # Start background music looping
    @bgm = Native::Audio::MusicPlayer.new("assets/level1.mp3")
    @bgm.volume = 0.6_f32
    @bgm.play(loop: true)

    # Set up volume mixer
    Native::Audio::AudioMixer.master_volume = 1.0_f32
    Native::Audio::AudioMixer.sfx_volume    = 0.9_f32

    build_ui
  end

  def build_ui
    jump_btn  = Native::UI::Button.new("Jump")
    coin_btn  = Native::UI::Button.new("Collect Coin")
    mute_btn  = Native::UI::Button.new("Mute")

    jump_btn.on_click  { player_jumped }
    coin_btn.on_click  { coin_collected }
    mute_btn.on_click  { toggle_mute }

    layout = Native::UI::LinearLayout.new
    layout.orientation = Native::UI::LinearLayout::Orientation::Vertical
    layout.gravity = Native::UI::LinearLayout::Gravity::Center
    [jump_btn, coin_btn, mute_btn].each { |v| layout.addView(v) }
    @root = layout
  end

  def player_jumped
    @jump.play
  end

  def coin_collected
    config = Native::Audio::SoundConfig.new(
      volume: 0.9_f32,
      pitch:  1.2_f32   # slightly higher pitch = more satisfying
    )
    @coin.play(config)
  end

  def player_died
    @bgm.pause
    @death.play
    spawn { sleep 2.seconds; @bgm.play(loop: true) }
  end

  @muted = false

  def toggle_mute
    @muted = !@muted
    Native::Audio::AudioMixer.master_volume = @muted ? 0.0_f32 : 1.0_f32
  end

  def on_pause
    @bgm.pause
    Native::Audio::Audio.pause_all
  end

  def on_resume
    @bgm.resume
    Native::Audio::Audio.resume_all
  end

  def on_destroy
    @jump.unload
    @coin.unload
    @death.unload
    @bgm.unload
  end
end
```

---

## Audio tips

| Tip | Reason |
|---|---|
| Load `Sound` files once in `setup`, not in callbacks | Avoids delay and repeated disk reads |
| Use `Sound` for clips under ~5 seconds | Best performance for short audio |
| Use `MusicPlayer` for anything longer | Streams to avoid high memory use |
| Always `unload` in `on_destroy` | Prevents memory leaks |
| Pause audio in `on_pause` | The OS may interrupt playback anyway; explicit pause ensures a clean resume |
