# Video

`Native::Media::VideoPlayer` lets you embed and play video files inside your app. It is a `Native::UI::View` subclass, so you add it to your layout tree like any other widget.

---

## Basic usage

```crystal
player = Native::Media::VideoPlayer.new
player.width  = 360
player.height = 240

# Load a video file
player.load("assets/intro.mp4")

# Start playback when the video is ready
player.on_prepared do
  player.play
end

# Add to your layout
layout = Native::UI::LinearLayout.new
layout.orientation = Native::UI::LinearLayout::Orientation::Vertical
layout.addView(player)
@root = layout
```

---

## Playback control

```crystal
player.play
player.pause
player.stop

puts player.playing?     # => Bool
```

---

## Seeking

`seek_to` takes a position in **milliseconds**:

```crystal
player.seek_to(5000)    # jump to 5 seconds
player.seek_to(0)       # jump back to the start

puts player.current_position  # current time in ms (Int32)
puts player.duration          # total length in ms (Int32)

# Useful: show time remaining
remaining_ms = player.duration - player.current_position
remaining_s  = remaining_ms / 1000
puts "#{remaining_s}s remaining"
```

---

## Looping

```crystal
player.looping = true    # loop the video automatically when it finishes
puts player.looping?     # => Bool
```

---

## Volume

```crystal
player.volume = 0.5_f32   # 0.0 (mute) to 1.0 (full) — automatically clamped
puts player.volume
```

---

## Scale types

Controls how the video frame fills the player view:

```crystal
player.scale_type = Native::Media::VideoPlayer::ScaleType::FitCenter  # letterbox (default)
player.scale_type = Native::Media::VideoPlayer::ScaleType::CenterCrop # fill bounds, crop edges
player.scale_type = Native::Media::VideoPlayer::ScaleType::FitXY      # stretch to fill exactly
```

| Scale type | Effect |
|---|---|
| `FitCenter` | Fit the whole frame inside the view, preserving aspect ratio. Black bars may appear. |
| `CenterCrop` | Fill the entire view, cropping the edges if needed. No black bars. |
| `FitXY` | Stretch width and height independently. Distorts the image. |

---

## Callbacks

```crystal
# Called when the video has been loaded and is ready to play
player.on_prepared do
  puts "Duration: #{player.duration / 1000}s"
  player.play
end

# Called when playback reaches the end
player.on_completion do
  puts "Finished"
  # Loop manually, show replay button, navigate away, etc.
end

# Called when an error occurs (bad file, codec not supported, etc.)
player.on_error do |message|
  puts "Video error: #{message}"
end

# Called with buffering/info events
player.on_info do |what, extra|
  puts "Player info — what: #{what}, extra: #{extra}"
end
```

---

## Lifecycle

Always pause the player when the app goes to the background — video playback is resource-intensive:

```crystal
def on_pause
  @player.pause
end

def on_resume
  @player.play if @player.looping?
end
```

---

## Real example — splash screen video

Play a branded video on launch, then navigate to the main screen:

```crystal
class SplashApp < Native::App
  def setup
    set_background_color(0, 0, 0)

    @player = Native::Media::VideoPlayer.new
    @player.width      = 400
    @player.height     = 700
    @player.scale_type = Native::Media::VideoPlayer::ScaleType::FitCenter
    @player.volume     = 1.0_f32

    @player.on_prepared do
      @player.play
    end

    @player.on_completion do
      show_main_screen
    end

    @player.on_error do |msg|
      puts "Splash video failed: #{msg}"
      show_main_screen   # fall through gracefully
    end

    @player.load("assets/splash.mp4")

    layout = Native::UI::LinearLayout.new
    layout.gravity = Native::UI::LinearLayout::Gravity::Center
    layout.addView(@player)
    @root = layout
  end

  def show_main_screen
    # Replace @root with your actual main screen layout
    label = Native::UI::TextView.new("Welcome!")
    label.text_size = 32
    label.center

    layout = Native::UI::LinearLayout.new
    layout.gravity = Native::UI::LinearLayout::Gravity::Center
    layout.addView(label)
    @root = layout
  end
end

Native::App.start(SplashApp)
```

---

## Real example — video player with controls

```crystal
class VideoPlayerApp < Native::App
  def setup
    @player = Native::Media::VideoPlayer.new
    @player.width      = 400
    @player.height     = 250
    @player.scale_type = Native::Media::VideoPlayer::ScaleType::FitCenter

    @time_label = Native::UI::TextView.new("0:00 / 0:00")
    @time_label.text_size = 14

    play_btn  = Native::UI::Button.new("▶ Play")
    pause_btn = Native::UI::Button.new("⏸ Pause")
    back_btn  = Native::UI::Button.new("⏮ −10s")
    fwd_btn   = Native::UI::Button.new("⏭ +10s")

    play_btn.on_click  { @player.play }
    pause_btn.on_click { @player.pause }
    back_btn.on_click  { @player.seek_to([0, @player.current_position - 10_000].max) }
    fwd_btn.on_click   { @player.seek_to([@player.duration, @player.current_position + 10_000].min) }

    controls = Native::UI::LinearLayout.new(
      Native::UI::LinearLayout::Orientation::Horizontal
    )
    controls.gravity = Native::UI::LinearLayout::Gravity::Center
    [back_btn, play_btn, pause_btn, fwd_btn].each { |b| controls.addView(b) }

    @player.on_prepared do
      total_s = @player.duration / 1000
      @time_label.text = "0:00 / #{format_time(total_s)}"
      @player.play
    end

    @player.on_completion do
      @time_label.text = "Done"
    end

    @player.load("assets/demo.mp4")

    layout = Native::UI::LinearLayout.new
    layout.orientation = Native::UI::LinearLayout::Orientation::Vertical
    layout.gravity = Native::UI::LinearLayout::Gravity::Center
    layout.addView(@player)
    layout.addView(@time_label)
    layout.addView(controls)
    @root = layout
  end

  def format_time(seconds : Int32) : String
    m = seconds / 60
    s = seconds % 60
    "#{m}:#{s.to_s.rjust(2, '0')}"
  end

  def on_pause
    @player.pause
  end
end

Native::App.start(VideoPlayerApp)
```
