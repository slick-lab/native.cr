# Audio

Sound effects, music playback, and recording.

---

## Quick Start

```crystal
# Play sound effect
Native::Audio::Audio.play_sound("assets/click.wav")

# Play music (loops by default)
Native::Audio::Audio.play_music("assets/theme.mp3")

# Pause/resume all
Native::Audio::Audio.pause_all
Native::Audio::Audio.resume_all
```

---

## Sound Effects

Load once, play many times:

```crystal
@jump = Native::Audio::Sound.new("assets/jump.wav")
@coin = Native::Audio::Sound.new("assets/coin.wav")

# Play
@jump.play

# With options
config = Native::Audio::SoundConfig.new(
  volume: 0.8_f32,
  pitch: 1.2_f32
)
@coin.play(config)
```

---

## Music Player

For long tracks (streams instead of loading into memory):

```crystal
music = Native::Audio::MusicPlayer.new("assets/music.mp3")
music.volume = 0.7_f32
music.play(loop: true)

# Control
music.pause
music.resume
music.seek(30.5)  # seconds

# Position
music.current_position
music.duration
```

---

## Recording

Requires microphone permission:

```crystal
Native::Permissions::Permissions.microphone do |status|
  if status == Native::Permissions::PermissionStatus::Granted
    start_recording
  end
end

recorder = Native::Audio::AudioRecorder.new
recorder.start
# ...
data = recorder.stop  # => Bytes
```

---

## Audio Mixer

Global volume control:

```crystal
Native::Audio::AudioMixer.master_volume = 0.8_f32
Native::Audio::AudioMixer.music_volume = 0.5_f32
Native::Audio::AudioMixer.sfx_volume = 1.0_f32
```

---

## Lifecycle

```crystal
def on_pause
  @music.pause
  Native::Audio::Audio.pause_all
end

def on_resume
  @music.resume
  Native::Audio::Audio.resume_all
end

def on_destroy
  @sound.unload
  @music.unload
end
```

---

## Example: Game Audio

```crystal
class GameApp < Native::App
  def setup
    @jump = Native::Audio::Sound.new("assets/jump.wav")
    @music = Native::Audio::MusicPlayer.new("assets/bg.mp3")
    @music.play(loop: true)
    
    btn = Native::UI::Button.new("Jump")
    btn.on_click { @jump.play }
    @root = btn
  end
end
```
