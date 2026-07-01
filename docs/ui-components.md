# UI Components

native.cr widgets are Crystal wrappers around real native views (Android Views, UIKit). Compose them into a tree and assign to `@root`.

---

## How It Works

```
@root (LinearLayout)
├── TextView    "Welcome"
├── ImageView   logo.png
└── LinearLayout (row)
    ├── Button  "Cancel"
    └── Button  "OK"
```

Only `@root` renders. Add children via `addView`.

---

## Colors

```crystal
Native::Math::Color.white
Native::Math::Color.black
Native::Math::Color.red
Native::Math::Color.from_hex(0x007AFF)
Native::Math::Color.from_rgba(255, 0, 0, 255)
Native::Math::Color.gray(128)
```

---

## View (Base)

All widgets inherit from `View`:

| Property | Type | Description |
|----------|------|-------------|
| `width`, `height` | Int32 | Size in points |
| `x`, `y` | Int32 | Position offset |
| `visible` | Bool | Show/hide |
| `enabled` | Bool | Enable/disable interaction |
| `background_color` | Color | Background fill |
| `alpha` | Float32 | Opacity (0.0–1.0) |

---

## TextView — Label

```crystal
label = Native::UI::TextView.new("Hello!")
label.text_size = 24
label.text_color = Native::Math::Color.black
label.max_lines = 2
label.ellipsize_end

# Alignment
label.center
label.center_horizontal
label.left
label.right
```

---

## Button

```crystal
btn = Native::UI::Button.new("Save")
btn.width = 200
btn.height = 50
btn.background_color = Native::Math::Color.from_hex(0x007AFF)
btn.text_color = Native::Math::Color.white
btn.on_click { do_something }
btn.on_long_click { show_menu }
```

---

## ImageView

```crystal
img = Native::UI::ImageView.new
img.width = 300
img.height = 200

# Load image
img.setImagePath("assets/photo.jpg")
img.setImageData(jpeg_bytes)

# Scale modes
img.scale_type = Native::UI::ImageView::ScaleType::FitCenter
img.scale_type = Native::UI::ImageView::ScaleType::CenterCrop
img.scale_type = Native::UI::ImageView::ScaleType::FitXY
```

---

## LinearLayout — Rows/Columns

```crystal
# Vertical
col = Native::UI::LinearLayout.new
col.orientation = Native::UI::LinearLayout::Orientation::Vertical

# Horizontal
row = Native::UI::LinearLayout.new(
  Native::UI::LinearLayout::Orientation::Horizontal
)

# Add children
col.addView(label)
col.addView(button)

# Alignment
col.gravity = Native::UI::LinearLayout::Gravity::Center

# Padding
col.set_padding(16, 24, 16, 24)

# Proportional sizing
col.weight_sum = 1.0_f32
col.addView(header, weight: 0.2_f32)
col.addView(content, weight: 0.8_f32)
```

---

## ScrollView

```crystal
scroll = Native::UI::ScrollView.new
scroll.addView(content)

# Scroll
scroll.scroll_to(0, 300)
scroll.scroll_to_bottom

# Position
scroll.scroll_x
scroll.scroll_y

# Events
scroll.on_scroll_changed { |x, y| puts "at #{x}, #{y}" }
```

---

## EditText — Input

```crystal
input = Native::UI::EditText.new
input.hint = "Enter name"
input.text_size = 16
input.max_length = 50

# Keyboard types
input.email
input.password
input.number
input.phone
input.multiline

# Read value
text = input.text

# Callback
input.on_text_changed { |text| validate(text) }
```

---

## RecyclerView — List

```crystal
items = ["Apple", "Banana", "Cherry"]

adapter = Native::UI::SimpleAdapter.new(items)
adapter.on_bind { |view, text, i| view.text_size = 16 }

list = Native::UI::RecyclerView.new
list.adapter = adapter
list.on_item_click { |i| puts "Tapped #{i}" }
```

---

## Checkbox, Switch, RadioButton

```crystal
cb = Native::UI::Checkbox.new
cb.text = "I agree"
cb.on_change { |checked| puts checked }

sw = Native::UI::Switch.new
sw.on_change { |on| toggle_feature(on) }
```

---

## ProgressBar, SeekBar

```crystal
bar = Native::UI::ProgressBar.new
bar.progress = 65

slider = Native::UI::SeekBar.new
slider.max = 100
slider.progress = 50
slider.on_progress_change { |v| set_volume(v) }
```

---

## Spinner — Dropdown

```crystal
sp = Native::UI::Spinner.new
sp.items = ["Small", "Medium", "Large"]
sp.selected_index = 1
sp.on_item_selected { |i, text| puts text }
```

---

## CardView, WebView

```crystal
card = Native::UI::CardView.new
card.elevation = 4
card.set_corner_radius(8)

web = Native::UI::WebView.new
web.load_url("https://example.com")
web.load_html("<h1>Hello</h1>")
```

---

## Example: Login Form

```crystal
def setup
  @email = Native::UI::EditText.new
  @email.hint = "Email"
  @email.email

  @password = Native::UI::EditText.new
  @password.hint = "Password"
  @password.password

  btn = Native::UI::Button.new("Sign In")
  btn.on_click { sign_in }

  layout = Native::UI::LinearLayout.new
  layout.orientation = Native::UI::LinearLayout::Orientation::Vertical
  layout.addView(@email)
  layout.addView(@password)
  layout.addView(btn)
  @root = layout
end
```
