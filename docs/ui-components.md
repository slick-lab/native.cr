# UI Components

native.cr comes with a full set of ready-to-use UI widgets. Every widget lives in the `Native::UI` namespace (also accessible as just `UI::` inside your app class).

---

## Common properties

Almost every widget shares these properties:

| Property | Type | Description |
|---|---|---|
| `width` | `Int32` | Width in points |
| `height` | `Int32` | Height in points |
| `background_color` | `Color` | Background fill |
| `corner_radius` | `CornerRadius` | Rounded corners |
| `visible` | `Bool` | Show or hide |
| `alpha` | `Float32` | Transparency (0.0–1.0) |

---

## Colors

```crystal
Color.white
Color.black
Color.red
Color.from_hex(0x007AFF)        # hex colour (no alpha)
Color.from_rgba(255, 0, 0, 255) # R, G, B, Alpha (0-255)
```

## Corner radius

```crystal
CornerRadius.all(12)            # all 4 corners = 12pt
CornerRadius.new(8, 8, 0, 0)   # top-left, top-right, bottom-right, bottom-left
```

---

## Text (`UI::Text` / `UI::TextView`)

Displays a line (or paragraph) of text.

```crystal
label = UI::Text.new
label.text = "Hello!"
label.text_size = 24           # font size in points
label.color = Color.from_hex(0x333333)
label.bold = true
label.italic = false
label.alignment = TextAlignment::Center  # Left, Center, Right
label.max_lines = 2            # wrap after 2 lines (0 = unlimited)
```

---

## Button (`UI::Button`)

A tappable button.

```crystal
btn = UI::Button.new
btn.text = "Click Me"
btn.text_size = 18
btn.text_color = Color.white
btn.background_color = Color.from_hex(0x007AFF)
btn.width = 200
btn.height = 50
btn.corner_radius = CornerRadius.all(25)
btn.disabled = false

# Respond to taps
btn.on_click = -> { puts "tapped!" }

# Block syntax (inside a class method)
btn.on_click { do_something }
```

---

## Image (`UI::Image` / `UI::ImageView`)

Displays an image from a file or bytes.

```crystal
img = UI::Image.new
img.width = 300
img.height = 200
img.corner_radius = CornerRadius.all(12)
img.background_color = Color.from_hex(0xEEEEEE)  # placeholder colour

# Load from asset file
img.load("photo.jpg")

# Scale modes
img.scale_mode = Native::Image::ScaleMode::AspectFit    # fit inside bounds
img.scale_mode = Native::Image::ScaleMode::AspectFill   # fill bounds, may crop
img.scale_mode = Native::Image::ScaleMode::FitXY        # stretch
```

---

## Layouts

Layouts arrange children in a row or column.

### Column (`UI::Column`)

Stacks children **vertically**.

```crystal
col = UI::Column.new
col.spacing = 16               # gap between children
col.alignment = Alignment::Center  # Center, Start (left), End (right)
col.padding = Padding.all(24)      # space around the edges

col.add_child(label)
col.add_child(button)
col.add_child(image)

@root = col
```

### Row (`UI::Row` / `UI::LinearLayout`)

Arranges children **horizontally**.

```crystal
row = UI::LinearLayout.new
row.orientation = Native::UI::LinearLayout::Orientation::Horizontal
row.addView(icon)
row.addView(label)
```

### Scroll (`UI::ScrollView`)

Wraps any layout and makes it scrollable.

```crystal
scroll = UI::ScrollView.new
scroll.add_child(very_tall_column)

@root = scroll
```

---

## Input fields (`UI::EditText`)

A text input the user can type into.

```crystal
input = UI::EditText.new
input.hint = "Enter your name…"   # placeholder text
input.text = ""
input.text_size = 16
input.width = 300
input.height = 48

# Get the current value
puts input.text

# React to changes as the user types
input.on_text_change { |text| puts "User typed: #{text}" }
```

---

## Checkbox (`UI::Checkbox`)

A toggle checkbox.

```crystal
cb = UI::Checkbox.new
cb.text = "I agree to the terms"
cb.checked = false
cb.on_change { |checked| puts "Checked: #{checked}" }
```

---

## Switch (`UI::Switch`)

An iOS-style toggle switch.

```crystal
sw = UI::Switch.new
sw.on = true
sw.on_change { |is_on| puts "Switch is now: #{is_on}" }
```

---

## Progress bar (`UI::ProgressBar`)

Shows progress from 0 to 100.

```crystal
bar = UI::ProgressBar.new
bar.width = 280
bar.progress = 65   # 65%
```

---

## Seek bar / Slider (`UI::SeekBar`)

A draggable slider.

```crystal
slider = UI::SeekBar.new
slider.width = 280
slider.max = 100
slider.progress = 50
slider.on_progress_change { |value| puts "Value: #{value}" }
```

---

## Spinner / Dropdown (`UI::Spinner`)

A dropdown picker.

```crystal
spinner = UI::Spinner.new
spinner.items = ["Apple", "Banana", "Cherry"]
spinner.selected_index = 0
spinner.on_item_selected { |index, text| puts "Picked: #{text}" }
```

---

## Radio buttons (`UI::RadioButton`)

```crystal
radio = UI::RadioButton.new
radio.text = "Option A"
radio.checked = false
radio.on_change { |checked| puts "Radio: #{checked}" }
```

---

## List (`UI::RecyclerView`)

Efficiently displays a scrollable list of items. Good for long lists.

```crystal
list = UI::RecyclerView.new
list.items = ["Item 1", "Item 2", "Item 3"]
list.on_item_click { |index, text| puts "Tapped: #{text}" }
```

---

## Web view (`UI::WebView`)

Embeds a full web browser inside your app.

```crystal
web = UI::WebView.new
web.width = 400
web.height = 600
web.load_url("https://example.com")

# Or load raw HTML
web.load_html("<h1>Hello from HTML!</h1>")
```

---

## Card (`UI::CardView`)

A container with a shadow/elevation, useful for cards.

```crystal
card = UI::CardView.new
card.corner_radius = CornerRadius.all(12)
card.elevation = 4
card.padding = Padding.all(16)
card.add_child(content_view)
```

---

## Icon (`UI::Icon`)

Displays a vector icon from the built-in icon set.

```crystal
icon = UI::Icon.new
icon.name = "heart"
icon.size = 32
icon.color = Color.red
```

---

## Putting it all together

A typical `setup` method builds a layout tree and assigns it to `@root`:

```crystal
def setup
  set_background_color(255, 255, 255)

  title = UI::Text.new
  title.text = "My App"
  title.text_size = 28
  title.bold = true

  subtitle = UI::Text.new
  subtitle.text = "Tap the button below"
  subtitle.text_size = 16
  subtitle.color = Color.from_hex(0x888888)

  action_btn = UI::Button.new
  action_btn.text = "Go"
  action_btn.width = 160
  action_btn.height = 48
  action_btn.background_color = Color.from_hex(0x34C759)
  action_btn.text_color = Color.white
  action_btn.corner_radius = CornerRadius.all(24)
  action_btn.on_click { do_action }

  col = UI::Column.new
  col.spacing = 20
  col.alignment = Alignment::Center
  col.add_child(title)
  col.add_child(subtitle)
  col.add_child(action_btn)

  @root = col
end
```
