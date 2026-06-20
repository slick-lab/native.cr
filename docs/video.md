# Video

native.cr lets you play video files inside your app using `Native::Media::VideoPlayer`. The player is a `UI::View`, so you can drop it directly into any layout.

---

## Basic usage

```crystal
player = Native::Media::VideoPlayer.new
player.width = 360
player.height = 240

player.load("assets/intro.mp4")   # load a video file

player.on_prepared do
  player.play              # start as soon as the video is ready
end

# Add the player to your layout
col = UI::Column.new
col.add_child(player)
@root = col
```

---

## Controlling playback

```crystal
player.play
player.pause
player.stop

puts player.playing?       # => Bool

# Seek to a position (in milliseconds)
player.seek_to(5000)       # jump to 5 seconds

puts player.current_position   # current time in ms (Int32)
puts player.duration           # total length in ms (Int32)
```

---

## Looping

```crystal
player.looping = true   # loop the video automatically
puts player.looping?    # => Bool
```

---

## Volume

```crystal
player.volume = 0.5    # 0.0 (mute) to 1.0 (full)
puts player.volume
```

---

## Scale type

Controls how the video fits inside the player view:

```crystal
player.scale_type = Native::Media::VideoPlayer::ScaleType::FitCenter  # letterbox (default)
player.scale_type = Native::Media::VideoPlayer::ScaleType::CenterCrop  # crop to fill
player.scale_type = Native::Media::VideoPlayer::ScaleType::FitXY       # stretch
```

---

## Callbacks

```crystal
# Called when the video is loaded and ready to play
player.on_prepared do
  puts "Video ready: #{player.duration}ms"
  player.play
end

# Called when the video finishes playing
player.on_completion do
  puts "Video ended"
  # restart, show a replay button, etc.
end

# Called if something goes wrong
player.on_error do |message|
  puts "Video error: #{message}"
end

# Called with info events (buffering updates, etc.)
player.on_info do |what, extra|
  puts "Info: #{what}, #{extra}"
end
```

---

## Full example — splash screen video

```crystal
class SplashApp < Native::App
  def setup
    set_background_color(0, 0, 0)

    @player = Native::Media::VideoPlayer.new
    @player.width = 400
    @player.height = 700
    @player.scale_type = Native::Media::VideoPlayer::ScaleType::FitCenter

    @player.load("assets/splash.mp4")

    @player.on_prepared do
      @player.play
    end

    @player.on_completion do
      show_main_screen
    end

    @player.on_error do |msg|
      puts "Could not play splash video: #{msg}"
      show_main_screen
    end

    @root = @player
  end

  def show_main_screen
    # switch to your main app screen
  end

  def draw
    @root.draw(renderer)
  end
end
```

---

## Tips

- Call `player.load(path)` before setting up `on_prepared` so the callback fires correctly.
- Always pause the player in `on_pause` and resume in `on_resume`:
  ```crystal
  def on_pause
    @player.pause
  end

  def on_resume
    @player.play if @player.looping?
  end
  ```
- The video file must be bundled with your app in the `assets/` folder, or accessed via a URL (if supported by the platform).
