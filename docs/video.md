# Video

Embedded video playback as a UI widget.

---

## Basic Usage

```crystal
player = Native::Media::VideoPlayer.new
player.width = 360
player.height = 240
player.load("assets/video.mp4")

player.on_prepared { player.play }
```

---

## Playback Control

```crystal
player.play
player.pause
player.stop

player.playing?  # => Bool
```

---

## Seeking

Time in milliseconds:

```crystal
player.seek_to(5000)  # 5 seconds

player.current_position  # ms
player.duration           # ms
```

---

## Looping & Volume

```crystal
player.looping = true
player.volume = 0.5_f32  # 0.0 - 1.0
```

---

## Scale Types

```crystal
player.scale_type = Native::Media::VideoPlayer::ScaleType::FitCenter
player.scale_type = Native::Media::VideoPlayer::ScaleType::CenterCrop
player.scale_type = Native::Media::VideoPlayer::ScaleType::FitXY
```

---

## Callbacks

```crystal
player.on_prepared { player.play }
player.on_completion { puts "Done" }
player.on_error { |msg| puts msg }
```

---

## Lifecycle

```crystal
def on_pause
  @player.pause
end

def on_resume
  @player.play if @player.looping?
end
```

---

## Example: Video Player

```crystal
class VideoApp < Native::App
  def setup
    @player = Native::Media::VideoPlayer.new
    @player.width = 400
    @player.height = 300
    
    play = Native::UI::Button.new("Play")
    play.on_click { @player.play }
    
    pause = Native::UI::Button.new("Pause")
    pause.on_click { @player.pause }
    
    @player.on_prepared { @player.play }
    @player.load("assets/demo.mp4")
    
    layout = Native::UI::LinearLayout.new
    layout.addView(@player)
    layout.addView(play)
    layout.addView(pause)
    @root = layout
  end

  def on_pause
    @player.pause
  end
end
```
