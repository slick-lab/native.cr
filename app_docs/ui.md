# UI Components

Complete reference for all available UI widgets.

---

## Basic Components

### View

The base component. Use for containers or custom backgrounds.

```crystal
view = Native::UI::View.new
view.width = 200
view.height = 200
view.background_color = 0xFF3366CC
view.radius = 8  # Rounded corners
view.on_click { handle_tap }
```

| Property | Type | Description |
|----------|------|-------------|
| `width` | Int32 | Width in pixels |
| `height` | Int32 | Height in pixels |
| `background_color` | UInt32 | ARGB color |
| `alpha` | Float32 | Opacity 0-1 |
| `visible` | Bool | Show/hide |
| `enabled` | Bool | Enable/disable |
| `padding` | Int32 | Padding all sides |
| `radius` | Int32 | Corner radius |

### TextView

Display text.

```crystal
label = Native::UI::TextView.new("Hello, World!")
label.text_size = 18.0
label.text_color = 0xFF333333
label.gravity = Native::UI::Gravity::CENTER
```

| Property | Type | Description |
|----------|------|-------------|
| `text` | String | Display text |
| `text_size` | Float32 | Font size (sp) |
| `text_color` | UInt32 | Text color (ARGB) |
| `gravity` | Gravity | Text alignment |
| `max_lines` | Int32 | Maximum lines |
| `ellipsize` | Bool | Truncate with ... |

### Button

Tappable button.

```crystal
button = Native::UI::Button.new("Click Me")
button.on_click { handle_click }
```

### EditText

Text input field.

```crystal
input = Native::UI::EditText.new
input.hint = "Enter your name"
input.input_type = Native::UI::EditText::InputType::Text
input.on_text_change { |text| validate(text) }
input.on_enter { submit }
```

| Property | Type | Description |
|----------|------|-------------|
| `hint` | String | Placeholder text |
| `input_type` | InputType | Text, Number, Password, etc. |
| `max_length` | Int32 | Character limit |

### ImageView

Display images.

```crystal
image = Native::UI::ImageView.new
image.load("assets/photo.png")
# Or from URL
image.load_url("https://example.com/image.png")
# Or set dimensions
image.width = 200
image.height = 150
image.scale_type = Native::UI::ImageView::ScaleType::CenterCrop
```

---

## Layout Components

### LinearLayout

Arrange children in a row or column.

```crystal
layout = Native::UI::LinearLayout.new
layout.orientation = Native::UI::LinearLayout::Orientation::Vertical

# Add children
layout.addView(view1)
layout.addView(view2)
```

| Property | Type | Description |
|----------|------|-------------|
| `orientation` | Orientation | Vertical or Horizontal |
| `gravity` | Gravity | Children alignment |

Child views can use `layout_weight` to share space:

```crystal
left_view.layout_weight = 1.0  # Takes remaining space
right_view.layout_weight = 0.0  # Uses intrinsic width
```

### ScrollView

Scrollable container.

```crystal
scroll = Native::UI::ScrollView.new
scroll.orientation = Native::UI::ScrollView::Orientation::Vertical
scroll.addView(content_layout)

# Control scrolling
scroll.scroll_to(0, 500)
scroll.scroll_to_top
scroll.scroll_to_bottom
```

### RecyclerView

Efficient scrollable list.

```crystal
recycler = Native::UI::RecyclerView.new
recycler.adapter = MyAdapter.new(items)
```

See [Lists](lists.md) for detailed usage.

---

## Form Components

### Checkbox

Binary selection.

```crystal
checkbox = Native::UI::Checkbox.new("Remember me")
checkbox.checked = true
checkbox.on_check_change { |checked| handle_check(checked) }
```

### Switch

Toggle switch.

```crystal
switch = Native::UI::Switch.new
switch.checked = false
switch.on_check_change { |on| toggle_feature(on) }
```

### RadioButton

Mutually exclusive selection.

```crystal
radio1 = Native::UI::RadioButton.new("Option A")
radio2 = Native::UI::RadioButton.new("Option B")
radio1.on_select { select_option("A") }
radio2.on_select { select_option("B") }
# Group manually or use RadioGroup
```

### SeekBar

Slider for numeric input.

```crystal
slider = Native::UI::SeekBar.new
slider.max = 100
slider.progress = 50
slider.on_progress_change { |value| update_value(value) }
```

### Spinner

Dropdown selector.

```crystal
spinner = Native::UI::Spinner.new
spinner.items = ["Red", "Green", "Blue"]
spinner.selected_index = 0
spinner.on_item_selected { |index| select_color(index) }
```

---

## Feedback Components

### ProgressBar

Loading indicator.

```crystal
progress = Native::UI::ProgressBar.new
progress.indeterminate = true  # Spinning

# Or determinate
progress.indeterminate = false
progress.max = 100
progress.progress = 75
```

### ProgressBar (Horizontal)

Progress bar.

```crystal
progress = Native::UI::ProgressBar.new
progress.style = Native::UI::ProgressBar::Style::Horizontal
progress.max = 100
progress.progress = 50
```

---

## Card Components

### CardView

Material-style card container.

```crystal
card = Native::UI::CardView.new
card.radius = 12
card.elevation = 4
card.padding = 16
card.add_content(my_layout)
```

---

## Advanced Components

### WebView

Embedded web content.

```crystal
web = Native::UI::WebView.new
web.load_url("https://example.com")
# Or HTML string
web.load_html("<h1>Hello</h1>")

# JavaScript bridge
web.on_js_message { |message| handle_from_js(message) }
web.run_javascript("alert('hi')")
```

### VideoView

Video player widget.

```crystal
video = Native::UI::VideoView.new
video.width = 400
video.height = 300
video.load("assets/video.mp4")
video.on_prepared { video.play }
```

---

## View Properties Reference

### Sizing

```crystal
view.width = 200          # Fixed width
view.height = 100         # Fixed height
view.layout_weight = 1.0  # Fill remaining in LinearLayout
view.min_width = 50
view.max_width = 500
```

### Margins and Padding

```crystal
view.padding = 16         # All sides
view.padding_top = 8
view.padding_bottom = 8
view.padding_left = 16
view.padding_right = 16
```

### Visibility

```crystal
view.visible = true       # Show
view.visible = false      # Hide (takes no space)
view.visibility = Native::UI::Visibility::Gone  # Remove from layout
view.visibility = Native::UI::Visibility::Invisible  # Hide but keep space
```

### Appearance

```crystal
view.background_color = 0xFFFFFFFF
view.alpha = 0.8
view.radius = 8  # Rounded corners
view.elevation = 4  # Shadow (Android 5+)
```

---

## Touch Events

All views support touch callbacks:

```crystal
view.on_touch_down { |x, y| start_drag(x, y) }
view.on_touch_move { |x, y| drag_to(x, y) }
view.on_touch_up { |x, y| end_drag(x, y) }
view.on_click { handle_tap }
view.on_long_press { |x, y| show_context_menu }
```

---

## Example: Contact Card

```crystal
def build_contact_card(name : String, email : String, avatar : String) : Native::UI::View
  card = Native::UI::CardView.new
  card.padding = 16
  card.radius = 8

  row = Native::UI::LinearLayout.new
  row.orientation = Native::UI::LinearLayout::Orientation::Horizontal

  # Avatar
  avatar_view = Native::UI::ImageView.new
  avatar_view.load(avatar)
  avatar_view.width = 60
  avatar_view.height = 60
  avatar_view.radius = 30  # Circular
  row.addView(avatar_view)

  # Info
  info = Native::UI::LinearLayout.new
  info.orientation = Native::UI::LinearLayout::Orientation::Vertical
  info.padding_left = 16

  name_view = Native::UI::TextView.new(name)
  name_view.text_size = 18.0
  name_view.text_color = 0xFF000000
  info.addView(name_view)

  email_view = Native::UI::TextView.new(email)
  email_view.text_size = 14.0
  email_view.text_color = 0xFF666666
  info.addView(email_view)

  row.addView(info)
  card.add_content(row)
  card
end
```

---

## Next Steps

- [Layouts and Styling](layouts-and-styling.md) — Positioning and theming
- [Lists](lists.md) — RecyclerView in depth
- [Navigation](navigation.md) — Multi-screen apps
