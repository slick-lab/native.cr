# Tutorial 4 — A Touch-Driven Game

Use the game loop, touch input, the animator, and audio — the four pieces
every native.cr game leans on. For a deeper reference see
[game-loop.md](../game-loop.md), [gesture.md](../gesture.md) and
[animation.md](../animation.md).

---

## 1. The game loop in one minute

`Native::GameLoop::GameLoop` runs your update code at a steady rate,
separating **fixed updates** (physics, AI) from **renders** (drawing). You
wire callbacks, then call `start`:

```crystal
loop = Native::GameLoop::GameLoop.new
loop.on_update do |dt|   # dt = seconds since last frame (Float64)
end
loop.on_render do |dt|
end
loop.start
```

`LoopConfig` tunes it: `target_fps` (default 60), `fixed_update_rate`,
`max_frame_time`, `mode`. Read live numbers back from `loop.fps` and
`loop.delta_time`.

---

## 2. The app: tap the dot

A dot drifts on screen; tapping near it scores a point.

```crystal
require "native"

class TapGame < Native::App
  @[Preserve]
  property score : Int32 = 0
  @[Preserve]
  property x : Float64 = 120.0
  @[Preserve]
  property direction : Float64 = 1.0

  def setup
    @score_label = Native::UI::TextView.new("Score: 0")
    @score_label.text_size = 22

    @dot = Native::UI::ImageView.new("assets/dot.png")
    @dot.width = 48
    @dot.height = 48

    canvas = Native::UI::LinearLayout.new
    canvas.orientation = Native::UI::LinearLayout::Orientation::Vertical
    canvas.gravity = Native::UI::LinearLayout::Gravity::Center
    canvas.addView(@dot)

    layout = Native::UI::LinearLayout.new
    layout.orientation = Native::UI::LinearLayout::Orientation::Vertical
    layout.padding = 16
    layout.addView(@score_label)
    layout.addView(canvas)
    @root = layout

    @loop = Native::GameLoop::GameLoop.new
    @loop.on_update do |dt|
      @x += 240.0 * @direction * dt
      @direction = -1.0 if @x > 300
      @direction = 1.0 if @x < 0
    end
    @loop.start
  end

  # Called by the runtime when a finger goes down.
  def on_touch_began(x : Float32, y : Float32) : Nil
    handle_tap(x, y)
  end

  private def handle_tap(x : Float64, y : Float64)
    if (x - @x).abs < 40
      @score += 1
      @score_label.text = "Score: #{@score}"
    end
  end
end

Native::App.registered_subclas = TapGame
```

> `@[Preserve]` on `score`, `x` and `direction` keeps the game state intact
> across hot reloads — reload mid-run and keep playing.

---

## 3. Juice it: animation and sound

**Animate** the dot on every hit with `Native::Animation::ValueAnimator`:

```crystal
animator = Native::Animation::ValueAnimator.new
animator.duration = 200          # milliseconds
animator.repeat_count = 1
animator.start
```

**Play a hit sound** from `assets/`:

```crystal
sound = Native::Audio::Sound.new("hit.wav")
sound.play
```

Both calls are cheap enough to run per hit. Load the sound once in `setup`
and reuse it — `Sound.play` overlaps cleanly on every platform.

---

## 4. Exercises

1. Speed the dot up each hit: add to the `240.0` factor on score.
2. Show "Miss!" with `Native::Dialog::Toast.new("Miss!").show` on a miss.
3. Persist the high score with `Native::Storage::Preferences`.
4. Swap `GameLoop` for `FixedGameLoop` and compare `loop.fps`.

Back to the [index](README.md) · Previous: [Tutorial 3](03-network-app.md)
