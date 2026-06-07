
---
title: Animations
---

# Animations

Animations bring your user interface to life. They provide visual feedback, guide user attention, and make your app feel polished and responsive. Native.cr provides a powerful animation system that lets you animate properties like position, size, color, and transparency with smooth easing curves.

## Why Animations Matter

Users expect mobile apps to feel fluid. When a button moves, it should glide, not teleport. When a screen appears, it should fade in, not pop into existence. Animations communicate cause and effect.

Consider these scenarios:

- **Button tap feedback** - A button shrinks slightly when tapped, then returns to normal size. This confirms the tap was detected.
- **Menu presentation** - A menu slides in from the side. This establishes spatial context.
- **Status change** - A color fades from red to green. This signals completion without words.

Without animations, your app feels mechanical and unresponsive. With animations, it feels alive and professional.

## What Can Be Animated

Native.cr can animate numeric properties of any view:

- **position** - `x` and `y` coordinates
- **size** - `width` and `height`
- **transparency** - `alpha` (0.0 to 1.0)
- **scale** - `scale` (1.0 is original size)
- **rotation** - `rotation` (in radians)
- **color** - `background_color` (animates red, green, blue, and alpha channels separately)

## The Animation DSL

Native.cr provides a domain-specific language (DSL) for animations. The DSL makes animation code readable and concise.

The basic structure is:

```crystal
animate(duration: 0.3, curve: Curve::EaseInOut) do
  view.x = 100
  view.y = 200
  view.alpha = 0.5
end
```

The animate method accepts two parameters:

- duration - How long the animation lasts in seconds (default is 0.3)
- curve - The easing function for the animation (default is Curve::EaseInOut)

Within the block, you set the target values for the properties you want to animate. The framework automatically interpolates from the current values to the target values over the specified duration.

Starting a Simple Animation

```crystal
button = UI::Button.new
button.x = 0
button.y = 0

animate(duration: 0.5) do
  button.x = 200
  button.y = 300
end
```

The button moves from (0, 0) to (200, 300) over half a second.

Animation Curves

Curves (also called easing functions) determine how the animation progresses over time. Without easing, animations move at constant speed, which feels mechanical. Real-world objects accelerate and decelerate.

## Linear Curve

Curve::Linear moves at constant speed from start to finish. The velocity never changes.

```crystal
animate(duration: 1.0, curve: Curve::Linear) do
  view.x = 300
end
```

Use linear for mechanical movements like progress bars or loading indicators where constant speed feels appropriate.

### Ease In Curve

Curve::EaseIn starts slowly and accelerates toward the end. The object "eases into" motion.

```crystal
animate(duration: 0.5, curve: Curve::EaseIn) do
  view.y = 500
end
```

Use ease-in when an object is leaving the screen or falling away. The slow start followed by rapid exit feels natural for dismissals.

### Ease Out Curve

Curve::EaseOut starts quickly and decelerates toward the end. The object "eases out" of motion.

```crystal
animate(duration: 0.5, curve: Curve::EaseOut) do
  view.y = 0
end
```

Use ease-out when an object is entering the screen or coming to rest. The rapid approach followed by gentle stop feels natural for appearances.

## Ease In Out Curve

Curve::EaseInOut starts slowly, speeds up in the middle, then slows down at the end. This is the most natural feeling curve for most UI animations.

```crystal
animate(duration: 0.3, curve: Curve::EaseInOut) do
  view.x = 150
  view.y = 150
end
```

Use ease-in-out for general-purpose animations like moving views, resizing elements, or transitioning between states. It is the default curve for a reason.

## Bounce Curve

Curve::Bounce overshoots the target value and bounces back multiple times, like a ball hitting the ground.

```crystal
animate(duration: 0.8, curve: Curve::Bounce) do
  view.y = 400
end
```

Use bounce for playful animations like dropping an icon into place or completing an achievement. Do not overuse bounce. It draws attention, so reserve it for special moments.

## Elastic Curve

Curve::Elastic overshoots and oscillates before settling, like a rubber band stretching and snapping back.

```crystal
animate(duration: 0.7, curve: Curve::Elastic) do
  view.scale = 1.5
end
```

Use elastic for dramatic emphasis like scaling up a modal or highlighting a notification. Like bounce, elastic is attention-grabbing. Use it sparingly.

## Chaining Animations

Sometimes you want animations to run one after another. For example, fade a view in, then slide it, then fade it out.

The then Method

After defining animations, call then to run them sequentially:

```crystal
animate(duration: 0.3) do
  view.alpha = 1.0
end.then
animate(duration: 0.5) do
  view.x = 200
end.then
animate(duration: 0.3) do
  view.alpha = 0.0
end
```

The first animation runs. When it completes, the second animation starts. When the second completes, the third starts.

## Example: Sequential Animation

```crystal
class AnimatedCard < Native::App
  def setup
    @card = UI::View.new
    @card.width = 200
    @card.height = 300
    @card.background_color = Color.white
    @card.corner_radius = CornerRadius.all(16)
    @card.shadow = create_shadow
    
    # Start invisible
    @card.alpha = 0.0
    @card.scale = 0.5
    
    @root = @card
    
    # Animate sequence
    animate_card_in
  end
  
  def animate_card_in
    animate(duration: 0.4, curve: Curve::EaseOut) do
      @card.alpha = 1.0
    end.then
    animate(duration: 0.3, curve: Curve::EaseOut) do
      @card.scale = 1.0
    end
  end
  
  def draw
    @root.draw(renderer)
  end
end
```

The card fades in first, then scales to full size.

## Running Animations in Parallel

Sometimes you want multiple properties to animate at the same time. The DSL automatically runs all property changes within a single animate block in parallel.

```crystal
animate(duration: 0.5, curve: Curve::EaseInOut) do
  view.x = 200      # Moves right
  view.y = 300      # Moves down
  view.alpha = 0.5  # Fades to half
  view.scale = 1.2  # Grows slightly
end
```

All four changes happen simultaneously over the same 0.5 seconds.

### Parallel vs Sequential Comparison

```crystal
# Parallel - all move together
animate(duration: 0.5) do
  view1.x = 200
  view2.x = 200
end

# Sequential - move one, then the other
animate(duration: 0.5) do
  view1.x = 200
end.then
animate(duration: 0.5) do
  view2.x = 200
end
```

Animating Colors

Color animation interpolates each channel (red, green, blue, alpha) separately. The result is a smooth transition between colors.

```crystal
animate(duration: 0.5, curve: Curve::EaseInOut) do
  view.background_color = Color.red
end
```

The view's background color transitions from whatever it was to red.

Color Sequence Example

```crystal
def show_success
  animate(duration: 0.2, curve: Curve::EaseOut) do
    @button.background_color = Color.green
  end.then
  animate(duration: 0.5, curve: Curve::EaseOut) do
    @button.background_color = Color.blue
  end
end
```

The button flashes green briefly, then returns to blue.

### Animating Scale

Scale animation makes views grow or shrink. This is useful for emphasis, popup effects, or zooming.

```crystal
# Grow to 1.5x size
animate(duration: 0.3, curve: Curve::EaseOut) do
  view.scale = 1.5
end

# Shrink back to normal
animate(duration: 0.3, curve: Curve::EaseIn) do
  view.scale = 1.0
end
```

Scale values are multipliers. 1.0 is normal size. 2.0 is twice as large. 0.5 is half as large.

### Button Tap Feedback

```crystal
class FeedbackButton < UI::Button
  def on_touch_began(x, y)
    animate(duration: 0.1, curve: Curve::EaseOut) do
      self.scale = 0.95
    end
    super
  end
  
  def on_touch_ended(x, y)
    animate(duration: 0.1, curve: Curve::EaseOut) do
      self.scale = 1.0
    end
    super
  end
end
```

The button shrinks slightly when pressed and returns to normal when released.

## Animating Position

Position animation moves views around the screen. This is the most common type of animation.

```crystal
# Slide in from left
@view.x = -200
animate(duration: 0.4, curve: Curve::EaseOut) do
  @view.x = 20
end

# Slide out to right
animate(duration: 0.3, curve: Curve::EaseIn) do
  @view.x = screen_width
end
```

### Slide-in Menu Example

```crystal
class SlideMenu < Native::App
  def setup
    @menu = UI::View.new
    @menu.width = 250
    @menu.height = screen_height
    @menu.background_color = Color.gray(50)
    @menu.x = -250  # Hidden off-screen left
    
    @root = @menu
  end
  
  def show_menu
    animate(duration: 0.3, curve: Curve::EaseOut) do
      @menu.x = 0
    end
  end
  
  def hide_menu
    animate(duration: 0.3, curve: Curve::EaseIn) do
      @menu.x = -250
    end
  end
  
  def draw
    @root.draw(renderer)
  end
end
```

## Animating Transparency

Fading views in and out creates smooth transitions without jarring appearances.

```crystal
# Fade in
@view.alpha = 0.0
animate(duration: 0.4, curve: Curve::EaseOut) do
  @view.alpha = 1.0
end

# Fade out
animate(duration: 0.3, curve: Curve::EaseIn) do
  @view.alpha = 0.0
end.then do
  @view.visible = false
end
```

Notice the then block after fade out. The visibility change happens after the fade completes.

## Combining Multiple Animations

You can chain parallel animations together for complex sequences.

```crystal
# Fade in and slide up
@dialog.alpha = 0.0
@dialog.y = 100

animate(duration: 0.3, curve: Curve::EaseOut) do
  @dialog.alpha = 1.0
  @dialog.y = 0
end.then

# Pause (by animating nothing with a duration)
animate(duration: 1.0) do
  # Nothing changes, just wait
end.then

# Fade out and slide down
animate(duration: 0.3, curve: Curve::EaseIn) do
  @dialog.alpha = 0.0
  @dialog.y = 100
end
```

The dialog fades in while sliding up, pauses for one second, then fades out while sliding down.

## Repeating Animations

To repeat an animation, use the repeat_count parameter in the animation configuration.

```crystal
config = AnimationConfig.new
config.duration = 0.5
config.repeat_count = 3

animator = ValueAnimator.new(0.0, 1.0, config)
animator.on_update do |value|
  @view.alpha = value.to_f32
end
animator.start
```

This fades the view in and out three times.

### Infinite Pulsing Effect

```crystal
def start_pulse
  config = AnimationConfig.new
  config.duration = 0.8
  config.repeat_count = -1  # Infinite repeat
  config.auto_reverse = true
  
  animator = ValueAnimator.new(1.0, 0.5, config)
  animator.on_update do |value|
    @button.alpha = value.to_f32
  end
  animator.start
end
```

The button continuously pulses between full opacity and half opacity.

### Auto-Reversing Animations

The auto_reverse property makes an animation play forward, then immediately backward, creating a loop.

```crystal
config = AnimationConfig.new
config.duration = 0.3
config.auto_reverse = true
config.repeat_count = 2

animator = ValueAnimator.new(0.0, 100.0, config)
animator.on_update do |value|
  @view.x = value.to_i
end
animator.start
```

The view moves from 0 to 100 (0.3 seconds), then back to 0 (0.3 seconds), then repeats twice.

## Delaying Animations

To start an animation after a delay, use the delay property.

```crystal
config = AnimationConfig.new
config.duration = 0.5
config.delay = 1.0

animator = ValueAnimator.new(0.0, 200.0, config)
animator.on_update do |value|
  @view.x = value.to_i
end
animator.start
```

The animation waits one second, then runs for 0.5 seconds.

### Practical Examples

Dialog Popup Animation

```crystal
def show_dialog
  @dialog.visible = true
  @dialog.alpha = 0.0
  @dialog.scale = 0.8
  
  animate(duration: 0.3, curve: Curve::EaseOut) do
    @dialog.alpha = 1.0
  end.then
  animate(duration: 0.2, curve: Curve::EaseOut) do
    @dialog.scale = 1.0
  end
end

def hide_dialog
  animate(duration: 0.2, curve: Curve::EaseIn) do
    @dialog.scale = 0.8
  end.then
  animate(duration: 0.2, curve: Curve::EaseIn) do
    @dialog.alpha = 0.0
  end.then do
    @dialog.visible = false
  end
end
```

Card Flip Animation

```crystal
def flip_card
  animate(duration: 0.2, curve: Curve::EaseOut) do
    @card.scale = 0.95
  end.then
  animate(duration: 0.1) do
    @card.scale = 1.0
  end
end
```

Loading Spinner Pulse

```crystal
def animate_loading
  config = AnimationConfig.new
  config.duration = 0.6
  config.repeat_count = -1
  config.auto_reverse = true
  
  animator = ValueAnimator.new(0.3, 1.0, config)
  animator.on_update do |value|
    @spinner.alpha = value.to_f32
    @spinner.scale = value.to_f32
  end
  animator.start
end
```

## Performance Tips

Use hardware-accelerated properties - Properties like x, y, alpha, and scale are hardware-accelerated and perform well. Animating width and height can cause layout recalculations and may be slower.

Keep animations short - Most UI animations should last between 0.2 and 0.5 seconds. Longer animations feel slow and frustrate users.

Avoid animating too many views at once - Animating 10 views simultaneously may drop frames. Test on older devices.

Use EaseInOut for most animations - It feels the most natural. Reserve Bounce and Elastic for special moments.

### Common Mistakes

Forgetting to set initial values - Before animating to a new position, ensure the starting position is set.

```crystal
# Wrong - view starts at whatever x was
animate(duration: 0.3) do
  view.x = 200
end

# Right - explicitly set starting position first
view.x = 0
animate(duration: 0.3) do
  view.x = 200
end
```

Animating invisible views - If visible is false, you cannot see the animation, but it still runs and consumes CPU.

```crystal
# Wrong - animating a hidden view
view.visible = false
animate(duration: 0.3) do
  view.x = 200  # Wasted work
end

# Right - make visible first
view.visible = true
view.alpha = 0.0
animate(duration: 0.3) do
  view.alpha = 1.0
end
```

Over-animating - Not every UI change needs animation. Reserve animations for state transitions and user feedback. Constant animation distracts users.

## Next Steps

Now that you understand animations, learn about:
- · UI Components - Build complex interfaces
- Events & Gestures - Handle user interaction
- Networking - Load and display data
