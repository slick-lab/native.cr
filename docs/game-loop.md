# Game Loop

Frame-based update loop for games and animations.

---

## Loop Modes

| Mode | Description |
|------|-------------|
| Fixed | Consistent physics, variable render |
| Variable | Simple, frame-rate dependent |
| Adaptive | Caps at target FPS |

---

## Quick Start

```crystal
loop = Native::GameLoop::GameLoop.new
loop.on_update { |dt| update_physics(dt) }
loop.on_render { |alpha| draw_frame(alpha) }
loop.start
```

---

## LoopConfig

```crystal
config = Native::GameLoop::LoopConfig.new
config.mode = Native::GameLoop::LoopMode::Adaptive
config.target_fps = 60
config.max_frame_time = 0.25  # Cap delta to avoid spiral of death

loop = Native::GameLoop::GameLoop.new(config)
```

---

## Callbacks

```crystal
loop.on_start { initialize_game }
loop.on_update { |delta| update_logic(delta) }
loop.on_fixed_update { |fixed_delta| update_physics(fixed_delta) }
loop.on_render { |alpha| interpolate_and_draw(alpha) }
loop.on_pause { pause_game }
loop.on_resume { resume_game }
loop.on_stop { cleanup }
```

---

## Control

```crystal
loop.start
loop.pause
loop.resume
loop.stop

loop.is_running?
loop.is_paused?
```

---

## Stats

```crystal
loop.fps          # Current FPS
loop.delta_time   # Last frame time in seconds
loop.frame_count  # Total frames
```

---

## Fixed vs Variable

**Fixed** — Physics stays consistent:

```crystal
config.mode = Native::GameLoop::LoopMode::Fixed
config.fixed_update_rate = 1.0 / 60.0  # 60 Hz physics
```

**Variable** — Simpler, but depends on frame rate:

```crystal
config.mode = Native::GameLoop::LoopMode::Variable
```

---

## GameLoopDSL

Include in your app class:

```crystal
class MyGame < Native::App
  include Native::GameLoop::GameLoopDSL

  def setup
    game_loop(target_fps: 60, mode: Native::GameLoop::LoopMode::Fixed)
  end

  def game_start
    @score = 0
  end

  def game_update(delta)
    update_entities(delta)
  end

  def game_fixed_update(fixed_delta)
    update_physics(fixed_delta)
  end

  def game_render(alpha)
    draw_frame(alpha)
  end

  def on_pause
    pause_game
  end

  def on_resume
    resume_game
  end
end
```

---

## Helper Classes

```crystal
fixed = Native::GameLoop::FixedGameLoop.new(60)
variable = Native::GameLoop::VariableGameLoop.new(30)
```

---

## Example: Simple Game

```crystal
class BallGame < Native::App
  include Native::GameLoop::GameLoopDSL

  @[Preserve]
  property ball_x = 0.0
  @[Preserve]
  property ball_y = 0.0
  @[Preserve]
  property vel_x = 200.0
  @[Preserve]
  property vel_y = 150.0

  def setup
    @ball_x = 200.0
    @ball_y = 300.0
    game_loop(target_fps: 60)
  end

  def game_update(delta)
    @ball_x += @vel_x * delta
    @ball_y += @vel_y * delta

    bounce if hit_wall?
  end

  def game_render(alpha)
    draw_ball(@ball_x, @ball_y)
  end

  def bounce
    @vel_x = -@vel_x if hit_left? || hit_right?
    @vel_y = -@vel_y if hit_top? || hit_bottom?
  end

  def on_pause
    pause_game
  end
end
```
