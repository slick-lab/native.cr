# Gestures

Touch handling and gesture recognition.

---

## Touch Callbacks

Every view has touch callbacks:

```crystal
view = Native::UI::View.new

view.on_touch_down { |x, y|
  puts "Finger down at #{x}, #{y}"
}

view.on_touch_move { |x, y|
  puts "Moving to #{x}, #{y}"
}

view.on_touch_up { |x, y|
  puts "Released at #{x}, #{y}"
}
```

---

## Click Listener

Simple tap detection:

```crystal
button.on_click { handle_tap }
card.on_click { open_details }
```

---

## Long Press

Detect long-press gestures:

```crystal
view.on_long_press { |x, y|
  show_context_menu
}
```

---

## Swipe Detection

Track movement direction:

```crystal
@start_x = 0.0
@start_y = 0.0

view.on_touch_down { |x, y|
  @start_x = x
  @start_y = y
}

view.on_touch_up { |x, y|
  dx = x - @start_x
  dy = y - @start_y

  if dx.abs > 100 && dy.abs < 50
    if dx > 0
      on_swipe_right
    else
      on_swipe_left
    end
  end
}
```

---

## Pinch/Zoom

Two-finger gestures:

```crystal
@last_distance = 0.0

view.on_touch_move { |x, y|
  # Track first touch
}

# For pinch, track two touch points and calculate distance
def handle_pinch(x1, y1, x2, y2)
  distance = Math.sqrt((x2 - x1)**2 + (y2 - y1)**2)

  if @last_distance > 0
    scale = distance / @last_distance
    apply_zoom(scale)
  end

  @last_distance = distance
end
```

---

## Touch Event Coordinates

All touch callbacks receive screen coordinates:

| Callback | Parameters |
|----------|------------|
| `on_touch_down` | x, y |
| `on_touch_move` | x, y |
| `on_touch_up` | x, y |
| `on_long_press` | x, y |

---

## Consuming Events

Return `true` to prevent event propagation:

```crystal
# In custom view implementations
def handle_touch(action, x, y) : Bool
  # Return true to consume, false to pass along
  true
end
```

---

## Example: Swipe Navigation

```crystal
class SwipeApp < Native::App
  THRESHOLD = 100.0

  def setup
    @page = 0
    @root = build_swipe_view
  end

  def build_swipe_view
    view = Native::UI::View.new
    view.on_touch_down { |x, y| @start_x = x }
    view.on_touch_up { |x, y| handle_swipe(x) }
    view
  end

  def handle_swipe(end_x)
    dx = end_x - @start_x

    if dx > THRESHOLD
      previous_page
    elsif dx < -THRESHOLD
      next_page
    end
  end

  def next_page
    @page += 1
    update_page
  end

  def previous_page
    @page -= 1 if @page > 0
    update_page
  end
end
```

---

## Example: Drag Object

```crystal
class DragApp < Native::App
  def setup
    @object_x = 100.0
    @object_y = 100.0

    view = Native::UI::View.new
    view.on_touch_down { |x, y| @dragging = true }
    view.on_touch_move { |x, y| drag_to(x, y) if @dragging }
    view.on_touch_up { @dragging = false }

    @root = view
  end

  def drag_to(x, y)
    @object_x = x
    @object_y = y
    update_position
  end

  def update_position
    @draggable.x = @object_x.to_i
    @draggable.y = @object_y.to_i
  end
end
```
