# UI Components

native.cr's UI system is a thin Crystal wrapper around Android's native View system and iOS's UIKit. Every widget is a Crystal class in the `Native::UI` namespace. You compose them into a tree and assign the root to `@root`.

---

## How the UI tree works

```
@root (LinearLayout — vertical)
├── TextView      "Welcome"
├── ImageView     logo.png
└── LinearLayout  (horizontal row)
    ├── Button    "Cancel"
    └── Button    "OK"
```

Only `@root` is rendered. Everything else must be a descendant of `@root` via `addView`.

---

## Colours — `Native::Math::Color`

```crystal
Native::Math::Color.white
Native::Math::Color.black
Native::Math::Color.red
Native::Math::Color.blue
Native::Math::Color.green
Native::Math::Color.gray(128)          # grey by brightness (0–255)
Native::Math::Color.from_hex(0x007AFF) # hex, no alpha
Native::Math::Color.from_rgba(255, 0, 0, 255)  # R, G, B, A (0–255)
```

---

## Base view — `Native::UI::View`

All widgets inherit from `Native::UI::View`. These properties are available on every widget:

| Property | Type | Description |
|---|---|---|
| `x=` / `x` | `Int32` | Horizontal offset (points) |
| `y=` / `y` | `Int32` | Vertical offset (points) |
| `width=` / `width` | `Int32` | Width in points |
| `height=` / `height` | `Int32` | Height in points |
| `visible=` / `visible?` | `Bool` | Show or hide |
| `enabled=` / `enabled?` | `Bool` | Enable or disable interaction |
| `background_color=` | `Native::Math::Color` | Background fill |
| `tag=` / `tag` | `String?` | Arbitrary label for lookup |
| `native_ptr` | `Int64` | Raw platform pointer (advanced) |

```crystal
view = Native::UI::View.new
view.width = 200
view.height = 100
view.background_color = Native::Math::Color.from_hex(0xEEEEEE)
view.visible = false     # hide it
view.enabled = false     # grey it out (won't receive taps)
```

---

## TextView — text label

`Native::UI::TextView` displays one or more lines of text.

```crystal
label = Native::UI::TextView.new            # empty
label = Native::UI::TextView.new("Hello!")  # with initial text

label.text      = "Tap count: 0"
label.text_size = 24            # font size in points
label.text_color = Native::Math::Color.from_hex(0x333333)
label.max_lines = 2             # wrap and truncate after 2 lines (0 = unlimited)
label.ellipsize_end             # add "…" at the end when text overflows

# Alignment shortcuts
label.center             # horizontally + vertically centred
label.center_horizontal  # horizontally centred only
label.center_vertical    # vertically centred only
label.left               # left aligned
label.right              # right aligned
```

---

## Button — tappable button

`Native::UI::Button` is a tappable button.

```crystal
btn = Native::UI::Button.new           # empty label
btn = Native::UI::Button.new("Save")  # with label

btn.text        = "Tap Me"
btn.text_size   = 18
btn.text_color  = Native::Math::Color.white
btn.background_color = Native::Math::Color.from_hex(0x007AFF)
btn.width       = 200
btn.height      = 50
btn.all_caps    = false   # Android: prevent automatic UPPERCASE

# Callbacks — both block and proc syntax work
btn.on_click { do_something }
btn.on_long_click { show_context_menu }
```

> **Note:** Use `{ }` block syntax for `on_click`. You can also assign a proc:
> `btn.on_click = -> { do_something }`

---

## ImageView — image display

`Native::UI::ImageView` displays an image from a file, from raw bytes, or from an app resource.

```crystal
img = Native::UI::ImageView.new
img.width  = 300
img.height = 200
img.background_color = Native::Math::Color.gray(230)  # placeholder while loading

# Load from a file path
img.setImagePath("assets/photo.jpg")

# Load from raw bytes (e.g. downloaded or captured)
img.setImageData(jpeg_bytes)

# Load from an Android resource ID
img.setImageResource(R::drawable::icon)

# Scale behaviour
img.scale_type = Native::UI::ImageView::ScaleType::FitCenter    # letterbox (default)
img.scale_type = Native::UI::ImageView::ScaleType::CenterCrop   # fill and crop
img.scale_type = Native::UI::ImageView::ScaleType::FitXY        # stretch to fill
img.scale_type = Native::UI::ImageView::ScaleType::Center       # no scaling, centred
img.scale_type = Native::UI::ImageView::ScaleType::FitStart     # fit, align top/left
img.scale_type = Native::UI::ImageView::ScaleType::FitEnd       # fit, align bottom/right
img.scale_type = Native::UI::ImageView::ScaleType::CenterInside # shrink to fit, never enlarge

img.alpha = 0.5_f32   # transparency (0.0 invisible – 1.0 opaque)
```

---

## LinearLayout — rows and columns

`Native::UI::LinearLayout` is the primary layout container. It stacks children either vertically (a column) or horizontally (a row).

```crystal
# Vertical column (default)
col = Native::UI::LinearLayout.new
col.orientation = Native::UI::LinearLayout::Orientation::Vertical

# Horizontal row
row = Native::UI::LinearLayout.new(Native::UI::LinearLayout::Orientation::Horizontal)

# Add children
col.addView(label)
col.addView(button)
col.addView(image, 300, 200)    # add with explicit width × height

# Remove children
col.removeView(label)
col.removeAllViews

# Inspect children
col.childCount        # => Int32
col.getChildAt(0)     # => View?

# Alignment (gravity)
col.gravity = Native::UI::LinearLayout::Gravity::Center
col.gravity = Native::UI::LinearLayout::Gravity::CenterHorizontal
col.gravity = Native::UI::LinearLayout::Gravity::Top
col.gravity = Native::UI::LinearLayout::Gravity::Bottom

# Padding around edges (points)
col.set_padding(left: 16, top: 24, right: 16, bottom: 24)

# Proportional sizing with weights (like flexGrow in CSS)
col.weight_sum = 1.0_f32
col.addView(header, weight: 0.2_f32)   # takes 20% of height
col.addView(content, weight: 0.8_f32)  # takes 80% of height
```

### Gravity values

| Value | Effect |
|---|---|
| `Top` | Children stick to the top |
| `Bottom` | Children stick to the bottom |
| `Left` | Children stick to the left |
| `Right` | Children stick to the right |
| `Center` | Centred both ways |
| `CenterHorizontal` | Centred horizontally |
| `CenterVertical` | Centred vertically |
| `Fill` | Stretch to fill available space |

---

## ScrollView — scrollable container

`Native::UI::ScrollView` wraps a single child and makes it scrollable.

```crystal
# Vertical scroll (default)
scroll = Native::UI::ScrollView.new

# Horizontal scroll
hscroll = Native::UI::ScrollView.new(Native::UI::ScrollView::ScrollDirection::Horizontal)

# Add one child (typically a layout)
scroll.addView(tall_layout)
scroll.removeView(tall_layout)

# Scroll programmatically
scroll.scroll_to(0, 300)                 # jump to x=0, y=300 (no animation)
scroll.scroll_to(0, 300, animated: true) # smooth scroll
scroll.scroll_to_bottom                  # jump to end
scroll.scroll_to_top                     # jump to start

# Current scroll position
puts scroll.scroll_x    # horizontal offset (Int32)
puts scroll.scroll_y    # vertical offset   (Int32)
puts scroll.max_scroll_y

# Scroll events
scroll.on_scroll_changed { |x, y| puts "Scrolled to #{x}, #{y}" }
scroll.on_scroll_state_changed { |scrolling| puts "Scrolling: #{scrolling}" }
```

---

## EditText — text input

`Native::UI::EditText` is a single or multi-line text field.

```crystal
input = Native::UI::EditText.new
input = Native::UI::EditText.new("initial text")

input.hint       = "Enter your name…"   # placeholder text
input.hint_color = Native::Math::Color.gray(180)
input.text_size  = 16
input.text_color = Native::Math::Color.black
input.max_length = 50   # maximum characters

# Read the current value (always reads from the native control)
puts input.text

# Keyboard types — call these methods to switch input type
input.email        # email address keyboard
input.number       # numeric keypad
input.phone        # phone number keyboard
input.password     # password field (characters hidden)
input.multiline    # multi-line text area

# React to typing
input.on_text_changed { |text| validate(text) }
```

---

## RecyclerView — efficient scrolling list

`Native::UI::RecyclerView` is a high-performance scrolling list. It recycles views as the user scrolls, so it handles thousands of items smoothly.

### Using SimpleAdapter (easiest)

```crystal
items = ["Apple", "Banana", "Cherry", "Date", "Elderberry"]

adapter = Native::UI::SimpleAdapter.new(items)

adapter.on_bind do |text_view, text, index|
  text_view.text_size = 16
  text_view.text_color = Native::Math::Color.black
  # text_view is already pre-filled with text
end

list = Native::UI::RecyclerView.new
list.adapter = adapter
list.width  = 400
list.height = 600

# Tap callbacks
list.on_item_click { |index| puts "Tapped index #{index}" }
list.on_item_long_click { |index| show_delete_option(index) }

# After changing the data, call one of these:
adapter = Native::UI::SimpleAdapter.new(updated_items)
list.adapter = adapter
list.notify_data_changed                # refresh all rows
list.notify_item_inserted(items.size - 1)  # animate insertion
list.notify_item_removed(0)                 # animate removal

# Scroll
list.scroll_to_position(10)
list.scroll_to_position(10, smooth: true)
list.scroll_to_top
```

### Using a custom adapter (full control)

```crystal
class ContactAdapter < Native::UI::RecyclerViewAdapter
  def initialize(@contacts : Array(Contact))
  end

  def item_count : Int32
    @contacts.size
  end

  def create_view(env : Void*, position : Int32) : Int64
    view = Native::UI::LinearLayout.new
    view.orientation = Native::UI::LinearLayout::Orientation::Horizontal
    view.set_padding(12, 8, 12, 8)
    view.native_ptr
  end

  def bind_view(env : Void*, view : Int64, position : Int32) : Void
    contact = @contacts[position]
    # populate the view with contact data
  end
end
```

### Layout managers

```crystal
list.layout_manager = Native::UI::RecyclerView::LayoutManager::Linear        # single column (default)
list.layout_manager = Native::UI::RecyclerView::LayoutManager::Grid          # 2-column grid
list.layout_manager = Native::UI::RecyclerView::LayoutManager::StaggeredGrid # Pinterest-style
```

---

## Checkbox

```crystal
cb = Native::UI::Checkbox.new
cb.text    = "I agree to the terms"
cb.checked = false

# Block callback when toggled
cb.on_change { |checked| puts "Agreed: #{checked}" }
```

---

## Switch (toggle)

```crystal
sw = Native::UI::Switch.new
sw.on_change { |is_on| save_setting(is_on) }
```

---

## ProgressBar

```crystal
bar = Native::UI::ProgressBar.new
bar.width    = 280
bar.progress = 65   # 0 to 100
```

---

## SeekBar (slider)

```crystal
slider = Native::UI::SeekBar.new
slider.width    = 280
slider.max      = 100
slider.progress = 50
slider.on_progress_change { |value| set_volume(value) }
```

---

## RadioButton

```crystal
rb = Native::UI::RadioButton.new
rb.text    = "Option A"
rb.checked = false
rb.on_change { |checked| handle_selection(checked) }
```

---

## Spinner (dropdown picker)

```crystal
sp = Native::UI::Spinner.new
sp.items          = ["Small", "Medium", "Large"]
sp.selected_index = 1     # pre-select "Medium"
sp.on_item_selected { |index, text| puts "Picked: #{text}" }
```

---

## CardView — elevated card

```crystal
card = Native::UI::CardView.new
card.width       = 340
card.height      = 120
card.elevation   = 4
card.set_padding(16, 16, 16, 16)

content = Native::UI::TextView.new("Card content here")
card.addView(content)
```

---

## WebView — embedded browser

```crystal
web = Native::UI::WebView.new
web.width  = 400
web.height = 600
web.load_url("https://example.com")

# Or load raw HTML
web.load_html("<h1>Hello from Crystal!</h1><p>Rendered in a WebView.</p>")
```

---

## Putting it all together

A real `setup` method for a login screen:

```crystal
def setup
  set_background_color(255, 255, 255)

  title = Native::UI::TextView.new("Sign In")
  title.text_size = 28
  title.center_horizontal

  @email_input = Native::UI::EditText.new
  @email_input.hint = "Email address"
  @email_input.email
  @email_input.width = 320

  @pass_input = Native::UI::EditText.new
  @pass_input.hint = "Password"
  @pass_input.password
  @pass_input.width = 320

  @error_label = Native::UI::TextView.new
  @error_label.text_color = Native::Math::Color.red
  @error_label.visible = false

  sign_in_btn = Native::UI::Button.new("Sign In")
  sign_in_btn.width = 320
  sign_in_btn.height = 52
  sign_in_btn.background_color = Native::Math::Color.from_hex(0x007AFF)
  sign_in_btn.text_color = Native::Math::Color.white
  sign_in_btn.on_click { sign_in }

  layout = Native::UI::LinearLayout.new
  layout.orientation = Native::UI::LinearLayout::Orientation::Vertical
  layout.gravity = Native::UI::LinearLayout::Gravity::Center
  layout.set_padding(24, 40, 24, 24)
  layout.addView(title)
  layout.addView(@email_input)
  layout.addView(@pass_input)
  layout.addView(@error_label)
  layout.addView(sign_in_btn)

  @root = layout
end

def sign_in
  email = @email_input.text
  pass  = @pass_input.text

  if email.empty? || pass.empty?
    @error_label.text    = "Please fill in all fields."
    @error_label.visible = true
  else
    authenticate(email, pass)
  end
end
```
