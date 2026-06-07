
---
title: Events & Gestures
---

# Events & Gestures

User interaction is the heart of any mobile app. Native.cr provides a comprehensive event system that handles touch input, gestures, and keyboard events. Understanding how events work is essential for creating responsive, interactive applications.

## The Event System Overview

Events flow through your app in a specific order. When a user touches the screen, the following happens:

1. The operating system detects the touch at a specific screen position
2. Native.cr receives the touch event from the platform (Android or iOS)
3. The event is converted into a native.cr touch object
4. Your app's touch methods are called (`on_touch_began`, `on_touch_moved`, `on_touch_ended`)
5. If you have gesture recognizers attached to views, they also receive the event
6. You decide how to respond

You do not need to worry about the low-level details. Native.cr handles platform differences. You just override methods or attach gesture recognizers.

## Touch Events

Touch events are the most basic form of user input. Every time a finger touches, moves, or leaves the screen, a touch event occurs.

### Touch Object

When a touch occurs, native.cr creates a `Touch` object containing information about that touch:

| Property | Type | Description |
|----------|------|-------------|
| `id` | Int32 | Unique identifier for this finger (useful for multi-touch) |
| `x` | Float32 | X coordinate relative to the screen |
| `y` | Float32 | Y coordinate relative to the screen |
| `pressure` | Float32 | How hard the finger is pressing (0.0 to 1.0) |

The `id` is important for multi-touch scenarios. Each finger gets a unique ID when it touches down. That ID stays the same as the finger moves and ends. You can track individual fingers across the entire touch sequence.

### Touch Actions

Touches have four possible actions:

| Action | Description | When It Happens |
|--------|-------------|-----------------|
| `TouchAction::Began` | Finger touches screen | First contact |
| `TouchAction::Moved` | Finger moves while touching | During movement |
| `TouchAction::Ended` | Finger lifts off screen | Release |
| `TouchAction::Cancelled` | System interrupts touch | Alert appears, app backgrounds, etc. |

The `Cancelled` action is rare but important. It happens when the system takes over, such as when an incoming call appears or a system alert shows. You should treat it like `Ended` but possibly ignore the final position.

### App-Level Touch Methods

Your app class can override these methods to receive all touch events:

```crystal
class MyApp < Native::App
  def on_touch_began(x : Float32, y : Float32)
    puts "Touch started at (#{x}, #{y})"
  end

  def on_touch_moved(x : Float32, y : Float32)
    puts "Touch moved to (#{x}, #{y})"
  end

  def on_touch_ended(x : Float32, y : Float32)
    puts "Touch ended at (#{x}, #{y})"
  end

  def on_touch_cancelled(x : Float32, y : Float32)
    puts "Touch was cancelled"
  end
end
```

These methods receive the raw touch coordinates. They are called for every touch, regardless of which view was touched. This is useful for global gestures or custom drawing apps.

### View-Level Touch Methods

Views also have touch methods. When a view is touched, its hit_test method determines if the touch falls within its bounds. If yes, the view's touch methods are called.

```crystal
class TapView < UI::View
  def on_touch_began(x : Int32, y : Int32) : Bool
    puts "View tapped at (#{x}, #{y})"
    return true  # Indicates the touch was handled
  end
end
```

The touch methods return a boolean. Return true if you handled the touch and do not want it to propagate to parent views. Return false to let the touch continue to the next view.

Why Coordinates Are Different Types

Notice that app-level touch methods use Float32 while view-level touch methods use Int32. This is intentional:

- App-level coordinates are floating point for precise raw input from the system
- View-level coordinates are integers because views use integer pixel positions

You can convert between them using .to_i or .to_f32 as needed.

Gesture Recognizers

Raw touch events give you exact finger positions, but most user interactions are not raw touches. Users tap, swipe, pinch, and rotate. Implementing these from scratch requires complex math and state management.

Gesture recognizers handle this complexity for you. They analyze sequences of touch events and determine when a specific gesture has occurred.

Available Gesture Recognizers

| Gesture | Description | Common Use |
| ----- | ----- | ----- |
| TapGestureRecognizer | Single or multiple taps | Button presses,  selecting items |
| LongPressGestureRecognizer | Touch held in place | Context menus,drag initiation |
| PanGestureRecognizer | Drag movement | Scrolling, dragging objects |
| PinchGestureRecognizer | Two fingers moving apart/together | Zooming images, maps | 
| RotationGestureRecognizer | Two fingers rotating  |Rotating images, dials |
| SwipeGestureRecognizer | Quick flick in a direction | Navigation, dismissing items |

## How Gesture Recognizers Work

A gesture recognizer goes through several states:

1. Possible - The recognizer has not decided yet
2. Began - The gesture has started
3. Changed - The gesture is ongoing (movement, scale change, etc.)
4. Ended - The gesture completed successfully
5. Cancelled - The gesture was interrupted
6. Failed - The recognizer determined this was not its gesture

You usually only care about Began, Changed, and Ended. The recognizer handles the state machine internally.

## Gesture View Container

To use gesture recognizers, you attach them to a GestureView (or any view, but GestureView provides convenient methods):

```crystal
gesture_view = Gesture::GestureView.new
```

The GestureView inherits from UI::View, so it has all the same properties (position, size, background, etc.).

## Tap Gesture

A tap is a quick touch and release. Users expect buttons to respond to taps. The tap gesture recognizer detects single or multiple taps.

Single Tap

```crystal
view = Gesture::GestureView.new
view.width = 200
view.height = 200
view.background_color = Color.blue

view.add_tap_gesture do |point|
  puts "Tapped at x=#{point.x}, y=#{point.y}"
end
```

The callback receives a Point object containing the tap location relative to the view.

## Double Tap

```crystal
view.add_tap_gesture(taps: 2) do |point|
  puts "Double tapped!"
end
```

Multiple Taps

You can require any number of taps:

```crystal
view.add_tap_gesture(taps: 3) do |point|
  puts "Triple tapped!"
end
```

## Multiple Touches Required

You can also require multiple fingers to tap simultaneously:

```crystal
view.add_tap_gesture(taps: 1, touches: 2) do |point|
  puts "Two-finger tap!"
end
```

This requires two fingers to tap at the same time.

Complete Example

```crystal
class TapDemo < Native::App
  def setup
    set_background_color(245, 245, 250)
    
    @label = UI::Text.new
    @label.text = "Tap anywhere"
    @label.text_size = 24
    
    # Create a gesture view that covers the whole screen
    @gesture_view = Gesture::GestureView.new
    @gesture_view.width = screen_width
    @gesture_view.height = screen_height
    
    # Add single tap
    @gesture_view.add_tap_gesture do |point|
      @label.text = "Single tap at #{point.x.to_i}, #{point.y.to_i}"
    end
    
    # Add double tap
    @gesture_view.add_tap_gesture(taps: 2) do |point|
      @label.text = "Double tap!"
      set_background_color(200, 100, 100)
    end
    
    @root = @gesture_view
    @root.add_child(@label)
  end

  def draw
    @root.draw(renderer)
  end
end
```

### Long Press Gesture

A long press happens when the user touches and holds in place for a period of time. This is commonly used for context menus or to initiate drag operations.

Basic Long Press

```crystal
view.add_long_press_gesture do |point|
  puts "Long press at #{point.x}, #{point.y}"
end
```

Customizing Duration

The default duration is 0.5 seconds (500 milliseconds). You can change this:

```crystal
view.add_long_press_gesture(duration: 1.0) do |point|
  puts "Pressed for 1 second"
end
```

The duration is in seconds. A value of 0.3 means 300 milliseconds.

Long Press with Movement

Long press gestures normally fail if the finger moves beyond a small threshold (10 pixels). If you want to allow movement, you need to adjust the configuration directly:

```crystal
recognizer = LongPressGestureRecognizer.new
recognizer.minimum_press_duration = 0.5
recognizer.allowable_movement = 50.0  # Allow 50 pixels of movement

recognizer.on_long_press do |point|
  puts "Long press with movement allowed"
end
```

## Pan Gesture

A pan gesture (also called drag) happens when the user touches and moves their finger across the screen. This is how users scroll lists, drag objects, or draw with their finger.

Basic Pan

```crystal
view.add_pan_gesture do |translation, velocity, point|
  # translation: total movement from start
  # velocity: speed of movement
  # point: current touch position
end
```

The callback receives three parameters:

Parameter Description
translation Total distance moved from the starting point (Point object)
velocity Current speed in pixels per second (Point object)
point Current touch position (Point object)

Moving a View with Pan

The most common use of pan is to drag a view around the screen:

```crystal
@draggable_view = UI::View.new
@draggable_view.width = 100
@draggable_view.height = 100
@draggable_view.background_color = Color.blue

@gesture_view.add_pan_gesture do |translation, velocity, point|
  # Move the view by the translation amount
  @draggable_view.x = @start_x + translation.x.to_i
  @draggable_view.y = @start_y + translation.y.to_i
end
```

But this has a problem: the translation resets to zero each time a new gesture starts. You need to track the view's position.

### Proper Dragging Implementation

```crystal
class DraggableDemo < Native::App
  def setup
    set_background_color(245, 245, 250)
    
    @draggable = UI::View.new
    @draggable.width = 100
    @draggable.height = 100
    @draggable.background_color = Color.blue
    @draggable.corner_radius = CornerRadius.all(12)
    
    # Store initial position as properties
    @draggable_x = 100
    @draggable_y = 200
    @draggable.x = @draggable_x
    @draggable.y = @draggable_y
    
    @gesture_view = Gesture::GestureView.new
    @gesture_view.width = screen_width
    @gesture_view.height = screen_height
    
    @gesture_view.add_pan_gesture do |translation, velocity, point|
      # Update position based on start plus movement
      @draggable.x = @draggable_x + translation.x.to_i
      @draggable.y = @draggable_y + translation.y.to_i
    end
    
    # When pan ends, update stored position
    # Note: This requires a more complex recognizer setup
    # See the advanced example below
    
    @gesture_view.add_child(@draggable)
    @root = @gesture_view
  end

  def draw
    @root.draw(renderer)
  end
end
```

### Getting Pan State

For complete control, you can access the pan recognizer's state:

```crystal
pan = PanGestureRecognizer.new
pan.on_state_change do |state|
  case state
  when GestureState::Began
    @start_x = @draggable.x
    @start_y = @draggable.y
  when GestureState::Changed
    # Update position during movement
  when GestureState::Ended
    # Save final position
    @draggable_x = @draggable.x
    @draggable_y = @draggable.y
  end
end
```

## Pinch Gesture

Pinch gestures use two fingers moving toward each other (pinch close) or away from each other (pinch open). This is the standard way to zoom content.

Basic Pinch

```crystal
view.add_pinch_gesture do |scale, center|
  # scale: zoom factor (1.0 = original size)
  # center: center point of the pinch
end
```

The scale value starts at 1.0 when the gesture begins. As the user pinches open, scale increases (2.0 means twice as big). As the user pinches closed, scale decreases (0.5 means half as big).

### Zooming a View

```crystal
@image_view = UI::Image.new
@image_view.load("/assets/photo.jpg")
@image_view.width = 300
@image_view.height = 300

@gesture_view.add_pinch_gesture do |scale, center|
  # Multiply current scale by the new scale factor
  @current_scale *= scale
  @image_view.scale = @current_scale.to_f32
end
```

### Resetting Scale After Pinch

The scale value is relative to the start of the gesture, not cumulative. To track total scale, maintain a variable:

```crystal
@total_scale = 1.0
@current_gesture_scale = 1.0

@gesture_view.add_pinch_gesture do |scale, center|
  @current_gesture_scale = scale
  @image_view.scale = (@total_scale * scale).to_f32
end

# When gesture ends, update total scale
# This requires a custom recognizer with state
```

## Rotation Gesture

Rotation gestures use two fingers rotating around a center point. This is used for rotating images, dials, or other content.

Basic Rotation

```crystal
view.add_rotation_gesture do |rotation, center|
  # rotation: angle in radians
  # center: center point of the rotation
end
```

The rotation value starts at 0 when the gesture begins. As the user rotates clockwise, rotation increases. Counter-clockwise rotation produces negative values.

### Rotating a View

```crystal
@image_view = UI::Image.new
@image_view.load("/assets/photo.jpg")

@total_rotation = 0.0

@gesture_view.add_rotation_gesture do |rotation, center|
  @image_view.rotation = (@total_rotation + rotation).to_f32
end
```

### Converting Radians to Degrees

If you prefer degrees, convert using the rad_to_deg helper:

```crystal
@gesture_view.add_rotation_gesture do |rotation, center|
  degrees = rotation * 180.0 / Math::PI
  puts "Rotated #{degrees.round(1)} degrees"
end
```

## Swipe Gesture

A swipe is a quick, fast movement in a specific direction. Swipes are typically used for navigation (swipe back, swipe to delete) or dismissing content.

Basic Swipe

```crystal
view.add_swipe_gesture do |direction|
  # direction: 1=right, 2=left, 3=down, 4=up
end
```

### Direction Constants

The direction parameter uses these values:

Value Direction
1 Right
2 Left
3 Down
4 Up

### Swipe Handlers

```crystal
@gesture_view.add_swipe_gesture do |direction|
  case direction
  when 1
    puts "Swiped right"
    navigate_to_next_page()
  when 2
    puts "Swiped left"
    go_back()
  when 3
    puts "Swiped down"
    dismiss_modal()
  when 4
    puts "Swiped up"
    show_menu()
  end
end
```

## Swipe Sensitivity

The default swipe detection requires 50 pixels of movement within 0.5 seconds. These values cannot be changed through the simple add_swipe_gesture method, but you can create a custom recognizer:

```crystal
swipe = SwipeGestureRecognizer.new
# Note: minimum_distance and maximum_duration are not directly exposed
# in the simple version. Use the gesture view's add method instead.
```

### Multiple Gestures on One View

You can attach multiple gesture recognizers to the same view. They will all receive the touch events and attempt to recognize their gestures simultaneously.

```crystal
view = Gesture::GestureView.new

view.add_tap_gesture do |point|
  puts "Tap"
end

view.add_long_press_gesture do |point|
  puts "Long press"
end

view.add_pan_gesture do |translation, velocity, point|
  puts "Pan"
end
```

When the user interacts, the correct gesture will trigger. Taps will not trigger long press. Long presses will not trigger taps. The recognizers handle disambiguation automatically.

## Gesture Priority and Conflicts

Sometimes gestures conflict. For example, a pan gesture and a swipe gesture both detect horizontal movement. The system resolves conflicts using a simple rule: the first gesture to recognize wins.

If you need more control, you can implement custom logic using the recognizer's state:

```crystal
pan = PanGestureRecognizer.new
pan.on_state_change do |state|
  case state
  when GestureState::Began
    # Pan started - maybe cancel other gestures
  when GestureState::Changed
    # Pan is active
  when GestureState::Ended
    # Pan finished
  end
end
```

## Hit Testing Explained

When you touch the screen, native.cr needs to determine which view received the touch. This process is called hit testing.

How Hit Testing Works

1. Start at the root view
2. Check if the touch point is inside the view's bounds
3. If yes, check each child from last to first (back to front)
4. The first child that returns true becomes the hit view
5. If no child accepts, the parent view is the hit view

## The Hit Test Method

You can override hit_test to customize hit detection:

```crystal
class CustomView < UI::View
  def hit_test(x : Int32, y : Int32) : Bool
    # Only respond to touches in the right half of the view
    return false if x < width // 2
    super(x, y)
  end
end
```

This view only responds to touches on its right half. Touches on the left half pass through to views behind it.

## Transparent Views

By default, transparent views (alpha = 0) still receive touches. If you want a transparent view to ignore touches, override hit_test:

```crystal
class TransparentView < UI::View
  def hit_test(x : Int32, y : Int32) : Bool
    return false if @alpha <= 0.01
    super(x, y)
  end
end
```

## Keyboard Events

While mobile apps primarily use touch, some devices have keyboards (external keyboards on iPads, or Android devices with keyboard cases).

Key Codes

Native.cr provides KeyCode constants for common keys:

Key Constant
Back KeyCode::Back
Home KeyCode::Home
Menu KeyCode::Menu
Enter KeyCode::Enter
Delete KeyCode::Delete
Space KeyCode::Space
Letters A-Z KeyCode::A through KeyCode::Z
Numbers 0-9 KeyCode::Num0 through KeyCode::Num9

## Handling Key Events

Override key methods in your app:

```crystal
class MyApp < Native::App
  def on_key_pressed(key : Int32)
    case key
    when KeyCode::Back
      go_back()
    when KeyCode::VolumeUp
      increase_volume()
    end
  end

  def on_key_released(key : Int32)
    puts "Key #{key} released"
  end
end
```

## Text Input and Keyboard

For text input, use the TextInput component. It automatically shows the keyboard when focused and handles key events for typing.

```crystal
input = UI::TextInput.new
input.on_change do |text|
  puts "Current text: #{text}"
end
input.on_submit do |text|
  puts "User submitted: #{text}"
end
```

Complete Example: Drawing App

This example combines multiple gesture recognizers to create a simple drawing app:

```crystal
class DrawingApp < Native::App
  def setup
    set_background_color(255, 255, 255)
    
    @canvas = Gesture::GestureView.new
    @canvas.width = screen_width
    @canvas.height = screen_height
    @lines = [] of Array({Int32, Int32})
    @current_line = [] of {Int32, Int32}
    
    @canvas.add_pan_gesture do |translation, velocity, point|
      x = point.x.to_i
      y = point.y.to_i
      
      if @current_line.empty?
        @current_line << {x, y}
      end
      
      @current_line << {x, y}
      needs_redraw()
    end
    
    @canvas.add_tap_gesture(taps: 2) do |point|
      if @current_line.any?
        @lines << @current_line
        @current_line = [] of {Int32, Int32}
        needs_redraw()
      end
    end
    
    @gesture_view = @canvas
    @root = @gesture_view
  end

  def draw
    @root.draw(renderer)
    
    # Draw all completed lines
    @lines.each do |line|
      draw_line(renderer, line)
    end
    
    # Draw current line
    draw_line(renderer, @current_line)
  end

  private def draw_line(renderer, line)
    return if line.size < 2
    
    line.each_cons(2) do |p1, p2|
      draw_line(renderer, p1[0], p1[1], p2[0], p2[1], 0, 0, 0, 255)
    end
  end

  def on_touch_began(x : Float32, y : Float32)
    @gesture_view.on_touch_began(x.to_i, y.to_i)
  end

  def on_touch_moved(x : Float32, y : Float32)
    @gesture_view.on_touch_moved(x.to_i, y.to_i)
  end

  def on_touch_ended(x : Float32, y : Float32)
    @gesture_view.on_touch_ended(x.to_i, y.to_i)
  end
end
```

## Performance Considerations

Too Many Gesture Recognizers

Each gesture recognizer adds computational overhead. Attaching dozens of recognizers to the same view can impact performance. Use only what you need.

Hit Testing Complexity

Deep view hierarchies with many children make hit testing slower. Keep your view tree reasonably flat.

Event Propagation

Return true from touch handlers when you handle the event. This stops propagation and saves processing time.

Drawing During Gestures

If you redraw the screen during every pan or pinch event, keep drawing operations fast. Avoid complex calculations in gesture callbacks.

### Best Practices

Use the Right Gesture

Do not reimplement pan when scroll view exists. Do not reimplement pinch when image view with zoom exists. Use built-in components when possible.

Provide Visual Feedback

When a gesture starts, provide immediate visual feedback. Users need to know their touch was recognized.

```crystal
view.add_tap_gesture do |point|
  @button.background_color = Color.blue.brighter
  # Then perform action
end
```

Set Appropriate Touch Targets

Apple recommends a minimum touch target size of 44x44 points. Android recommends 48x48 dp. Make your interactive views large enough to tap comfortably.

Handle Cancellation

Always handle the cancelled state for long-running gestures. If a system alert appears in the middle of a pan, your app should not think the pan completed successfully.

## Next Steps

Now that you understand events and gestures, learn about:

- Animations - Add motion to your UI
- UI Components - Build complex interfaces
- Camera - Capture photos and video
