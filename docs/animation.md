# Animations

Smooth value transitions and UI animations.

---

## Quick Start

```crystal
anim = Native::Animation::ValueAnimator.new(0.0, 1.0)
anim.duration = 500
anim.interpolator = Native::Animation::Interpolator::AccelerateDecelerate

anim.on_update { |value| @view.alpha = value.to_f32 }
anim.start
```

---

## ValueAnimator

Animates between two values:

```crystal
anim = Native::Animation::ValueAnimator.new(0.0, 100.0)
anim.duration = 300
anim.on_update { |v| @label.text = v.round.to_s }
anim.start
```

---

## Interpolators

Control easing curves:

| Interpolator | Effect |
|--------------|--------|
| Linear | Constant speed |
| Accelerate | Starts slow, speeds up |
| Decelerate | Starts fast, slows down |
| AccelerateDecelerate | Slow start and end |
| Bounce | Bounces at end |
| Overshoot | Overshoots then settles |
| Anticipate | Pulls back before animating |
| AnticipateOvershoot | Pulls back, overshoots, settles |

```crystal
anim.interpolator = Native::Animation::Interpolator::Bounce
```

---

## Properties

| Property | Type | Description |
|----------|------|-------------|
| `duration` | Int32 | Length in ms (default: 300) |
| `interpolator` | Interpolator | Easing function |
| `repeat_count` | Int32 | 0 = once, -1 = infinite |
| `repeat_mode` | Int32 | 1 = restart, 2 = reverse |

---

## Callbacks

```crystal
anim.on_start { puts "Started" }
anim.on_update { |value| update_ui(value) }
anim.on_end { puts "Finished" }
anim.on_repeat { puts "Repeating" }
```

---

## Control

```crystal
anim.start
anim.cancel
anim.end  # Jump to end immediately

anim.is_running?  # => Bool
```

---

## ObjectAnimator

Animate view properties directly:

```crystal
fade = Native::Animation::ObjectAnimator.new(@view, "alpha", 1.0, 0.0)
fade.duration = 300
fade.start
```

Common properties: `alpha`, `translationX`, `translationY`, `scaleX`, `scaleY`, `rotation`.

---

## AnimatorSet

Group animations:

```crystal
set = Native::Animation::AnimatorSet.new

fade1 = Native::Animation::ObjectAnimator.new(@view1, "alpha", 1.0, 0.0)
fade2 = Native::Animation::ObjectAnimator.new(@view2, "alpha", 1.0, 0.0)

set.play_together(fade1)  # Add to set
set.start
```

---

## Example: Fade Out

```crystal
class FadeApp < Native::App
  def setup
    @box = Native::UI::View.new
    @box.width = 200
    @box.height = 200
    @box.background_color = 0xFF0088FF

    btn = Native::UI::Button.new("Fade Out")
    btn.on_click { fade_out }

    @root = layout
  end

  def fade_out
    anim = Native::Animation::ObjectAnimator.new(@box, "alpha", 1.0, 0.0)
    anim.duration = 500
    anim.interpolator = Native::Animation::Interpolator::Accelerate
    anim.start
  end
end
```
