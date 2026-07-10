# Layouts and Styling

Position views, create responsive layouts, and apply consistent styling.

---

## Layout Fundamentals

Layouts determine how child views are positioned and sized. native.cr provides several layout types.

---

## LinearLayout

Arranges children in a single direction.

### Vertical Layout

Stack children top-to-bottom:

```crystal
container = Native::UI::LinearLayout.new
container.orientation = Native::UI::LinearLayout::Orientation::Vertical
container.padding = 16

container.addView(header)
container.addView(content)
container.addView(footer)
```

### Horizontal Layout

Arrange children left-to-right:

```crystal
row = Native::UI::LinearLayout.new
row.orientation = Native::UI::LinearLayout::Orientation::Horizontal

row.addView(icon)
row.addView(label)
row.addView(button)
```

### Layout Weight

Distribute space proportionally:

```crystal
row = Native::UI::LinearLayout.new
row.orientation = Native::UI::LinearLayout::Orientation::Horizontal
row.width = Native::UI::Layout::MatchParent

left = Native::UI::TextView.new("Left")
left.layout_weight = 1.0  # Gets 50% of space

right = Native::UI::TextView.new("Right")
right.layout_weight = 1.0  # Gets 50% of space

row.addView(left)
row.addView(right)
```

Weight ratios:

```crystal
# 2:1 ratio
view1.layout_weight = 2.0  # 2/3 of space
view2.layout_weight = 1.0  # 1/3 of space
```

### Gravity in LinearLayout

Align children within the layout:

```crystal
layout.gravity = Native::UI::Gravity::CENTER       # Center both axes
layout.gravity = Native::UI::Gravity::CENTER_VERTICAL
layout.gravity = Native::UI::Gravity::END          # Right align
```

---

## FrameLayout

Stack children on top of each other. Last child on top.

```crystal
frame = Native::UI::FrameLayout.new

# Background
bg = Native::UI::ImageView.new
bg.load("assets/background.png")
frame.addView(bg)

# Foreground
overlay = Native::UI::TextView.new("Welcome")
overlay.gravity = Native::UI::Gravity::CENTER
frame.addView(overlay)
```

---

## ScrollView

Makes content scrollable when it exceeds screen bounds.

### Vertical Scroll

```crystal
scroll = Native::UI::ScrollView.new
scroll.width = Native::UI::Layout::MatchParent
scroll.height = Native::UI::Layout::MatchParent

content = Native::UI::LinearLayout.new
content.orientation = Native::UI::LinearLayout::Orientation::Vertical

# Add lots of content...
100.times { content.addView(create_item) }

scroll.addView(content)
```

### Programmatic Scrolling

```crystal
scroll.scroll_to(0, 500)    # Scroll to position
scroll.scroll_to_top
scroll.scroll_to_bottom
scroll.scroll_to_view(target_view)
```

---

## RelativeLayout

Position children relative to each other or parent edges.

```crystal
relative = Native::UI::RelativeLayout.new

# Center in parent
centered = Native::UI::TextView.new("Center")
centered.layout_center_in_parent = true

# Align parent bottom
bottom = Native::UI::Button.new("OK")
bottom.layout_align_parent_bottom = true

# Right of another view
badge = Native::UI::TextView.new("3")
badge.layout_to_right_of(icon)

relative.addView(centered)
relative.addView(bottom)
relative.addView(badge)
```

---

## ConstraintLayout

Flat layouts with constraints (coming soon).

---

## Dimension Units

native.cr uses pixels for dimensions. The framework handles density conversion.

```crystal
view.width = 200   # 200 pixels (scaled for density)
view.height = 100

# For responsive design, use screen dimensions
screen_width = Native::Platform.screen_width
view.width = (screen_width * 0.8).to_i32  # 80% of screen
```

---

## Sizing Options

```crystal
# Match parent (fill available space)
view.width = Native::UI::Layout::MatchParent
view.height = Native::UI::Layout::MatchParent

# Wrap content (size to content)
view.width = Native::UI::Layout::WrapContent
view.height = Native::UI::Layout::WrapContent

# Fixed size
view.width = 200
view.height = 150
```

---

## Margins and Padding

```crystal
# Padding (space inside the view)
view.padding = 16           # All sides
view.padding_top = 8
view.padding_bottom = 8
view.padding_left = 16
view.padding_right = 16

# Margins (space outside the view)
view.margin = 8             # All sides
view.margin_top = 16
view.margin_bottom = 16
view.margin_left = 8
view.margin_right = 8
```

---

## Colors

Colors are ARGB (Alpha, Red, Green, Blue) 32-bit integers.

```crystal
# Format: 0xAARRGGBB
view.background_color = 0xFFFFFFFF  # White
view.background_color = 0xFF000000  # Black
view.background_color = 0xFF3366CC  # Blue
view.background_color = 0x80FF0000  # Semi-transparent red

# Using the Color struct
color = Native::Math::Color.from_rgba(255, 128, 0, 255)  # Orange
view.background_color = color.to_hex
```

---

## Text Styling

```crystal
label = Native::UI::TextView.new("Hello")

# Font size
label.text_size = 18.0

# Color
label.text_color = 0xFF333333

# Alignment
label.gravity = Native::UI::Gravity::CENTER

# Bold
label.text_style = Native::UI::TextStyle::BOLD

# Italic
label.text_style = Native::UI::TextStyle::ITALIC

# Max lines with ellipsis
label.max_lines = 2
label.ellipsize = true
```

---

## Backgrounds

### Solid Color

```crystal
view.background_color = 0xFFFFFFFF
```

### Rounded Corners

```crystal
view.background_color = 0xFFFFFFFF
view.radius = 12
```

### Drawable Resources

```crystal
view.background = R.drawable.ripple_background
```

### Elevation (Shadow)

```crystal
card.elevation = 4  # 4dp shadow
card.radius = 8
```

---

## Responsive Design

### Screen Dimensions

```crystal
width = Native::Platform.screen_width
height = Native::Platform.screen_height
density = Native::Platform.screen_density
```

### Density-Independent Calculations

```crystal
# Convert dp to pixels
def dp(value : Int32) : Int32
  density = Native::Platform.screen_density
  (value * density).to_i32
end

view.padding = dp(16)
view.radius = dp(8)
```

### Percentage-Based Layouts

```crystal
screen_width = Native::Platform.screen_width

# 80% width
view.width = (screen_width * 0.8).to_i32

# 3-column grid
column_width = (screen_width - dp(32)) / 3
```

---

## Theming

### Define a Theme

```crystal
module AppTheme
  # Colors
  PRIMARY        = 0xFF3366CC
  PRIMARY_DARK   = 0xFF2255AA
  SECONDARY      = 0xFF66CC99
  BACKGROUND     = 0xFFF5F5F5
  SURFACE        = 0xFFFFFFFF
  TEXT_PRIMARY   = 0xFF212121
  TEXT_SECONDARY = 0xFF757575
  ERROR          = 0xFFE53935

  # Spacing
  def self.spacing_xs; dp(4); end
  def self.spacing_sm; dp(8); end
  def self.spacing_md; dp(16); end
  def self.spacing_lg; dp(24); end
  def self.spacing_xl; dp(32); end

  # Typography
  FONT_SIZE_H1 = 32.0
  FONT_SIZE_H2 = 24.0
  FONT_SIZE_H3 = 20.0
  FONT_SIZE_BODY = 16.0
  FONT_SIZE_CAPTION = 12.0
end
```

### Apply Theme

```crystal
def create_heading(text : String) : Native::UI::TextView
  label = Native::UI::TextView.new(text)
  label.text_size = AppTheme::FONT_SIZE_H1
  label.text_color = AppTheme::TEXT_PRIMARY
  label.padding_bottom = AppTheme.spacing_md
  label
end

def create_card(&block) : Native::UI::CardView
  card = Native::UI::CardView.new
  card.background_color = AppTheme::SURFACE
  card.radius = dp(8)
  card.elevation = 2
  card.padding = AppTheme.spacing_md
  card
end
```

---

## Common Layout Patterns

### Header with Back Button

```crystal
def build_header(title : String) : Native::UI::View
  row = Native::UI::LinearLayout.new
  row.orientation = Native::UI::LinearLayout::Orientation::Horizontal
  row.background_color = AppTheme::PRIMARY
  row.padding = AppTheme.spacing_sm

  back = Native::UI::Button.new("←")
  back.text_color = 0xFFFFFFFF
  back.on_click { go_back }
  row.addView(back)

  label = Native::UI::TextView.new(title)
  label.text_color = 0xFFFFFFFF
  label.text_size = 20.0
  label.gravity = Native::UI::Gravity::CENTER_VERTICAL
  label.layout_weight = 1.0
  row.addView(label)

  row
end
```

### Form Input with Label

```crystal
def build_form_field(label_text : String, hint : String) : Native::UI::View
  container = Native::UI::LinearLayout.new
  container.orientation = Native::UI::LinearLayout::Orientation::Vertical
  container.padding_bottom = dp(16)

  label = Native::UI::TextView.new(label_text)
  label.text_size = 12.0
  label.text_color = AppTheme::TEXT_SECONDARY
  container.addView(label)

  input = Native::UI::EditText.new
  input.hint = hint
  input.margin_top = dp(4)
  container.addView(input)

  container
end
```

### Two-Column Grid

```crystal
def build_grid(items : Array(Item)) : Native::UI::View
  container = Native::UI::LinearLayout.new
  container.orientation = Native::UI::LinearLayout::Orientation::Vertical

  items.each_slice(2) do |slice|
    row = Native::UI::LinearLayout.new
    row.orientation = Native::UI::LinearLayout::Orientation::Horizontal

    slice.each do |item|
      card = build_item_card(item)
      card.layout_weight = 1.0
      card.margin = dp(4)
      row.addView(card)
    end

    # Fill remaining space if odd number
    if slice.size == 1
      spacer = Native::UI::View.new
      spacer.layout_weight = 1.0
      row.addView(spacer)
    end

    container.addView(row)
  end

  container
end
```

---

## Next Steps

- [UI Components](ui-components.md) — All available widgets
- [Navigation](navigation.md) — Building multi-screen apps
- [Theming Deep Dive](theming.md) — Advanced styling
