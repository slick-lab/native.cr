
---
title: Styling & Themes
---

# Styling & Themes

Every app needs to look good. Native.cr provides a comprehensive styling system that lets you control colors, fonts, spacing, and more. You can style individual components or define global themes that apply to your entire app.

## Colors

Colors are the most basic building block of visual design. Native.cr represents colors using the `Color` struct, which stores red, green, blue, and alpha (transparency) values.

### How Color Works

A color is made of four components: red, green, blue, and alpha. Each component is a number between 0 and 255. Zero means none of that component. Two hundred fifty-five means the maximum amount.

Red, green, and blue combine to create any color. For example:

- Red only: (255, 0, 0) produces pure red
- Green only: (0, 255, 0) produces pure green
- Blue only: (0, 0, 255) produces pure blue
- All equal: (128, 128, 128) produces gray
- All maximum: (255, 255, 255) produces white
- All zero: (0, 0, 0) produces black

Alpha controls transparency. 255 means fully opaque (solid). 0 means fully transparent (invisible). Values in between create partial transparency.

### Creating Colors

There are several ways to create a color in native.cr.

**Using RGB values:**

```crystal
color = Color.new(255, 100, 50)
```

This creates a color with full red, medium green, and low blue. The alpha defaults to 255 (fully opaque).

Using RGBA values:

```crystal
color = Color.new(255, 100, 50, 128)
```

This creates a semi-transparent color. The alpha of 128 means it is about 50% transparent.

Using the rgb helper:

```crystal
color = Color.rgb(255, 100, 50)
```

This is exactly the same as Color.new but more explicit about what the numbers mean.

Using the rgba helper:

```crystal
color = Color.rgba(255, 100, 50, 128)
```

Using hex values:

Web developers are familiar with hex colors like #FF6432. Native.cr supports hex format using the hex method.

```crystal
color = Color.hex(0xFF6432)
```

The hex value uses 24 bits: 8 bits for red, 8 for green, 8 for blue. The most significant two digits are red, the next two are green, the last two are blue.

You can also include alpha:

```crystal
color = Color.hex(0xFF643280)
```

Now the most significant two digits are alpha, followed by red, green, blue.

Preset Colors

Native.cr provides common colors as convenience methods:

```crystal
Color.black      # (0, 0, 0, 255)
Color.white      # (255, 255, 255, 255)
Color.red        # (255, 0, 0, 255)
Color.green      # (0, 255, 0, 255)
Color.blue       # (0, 0, 255, 255)
Color.transparent # (0, 0, 0, 0)
```

The gray method creates a gray color with a specific brightness level:

```crystal
Color.gray(50)   # Very dark gray
Color.gray(128)  # Middle gray
Color.gray(200)  # Light gray
```

The argument is the brightness level from 0 (black) to 255 (white). All three color channels are set to the same value.

Modifying Colors

Once you have a color, you can create new colors by modifying the existing one.

Changing alpha:

```crystal
solid = Color.red
transparent = solid.with_alpha(128)
```

The with_alpha method returns a new color with the same red, green, blue but a different alpha value. The original color remains unchanged.

Lightening a color:

```crystal
dark_blue = Color.blue
light_blue = dark_blue.lighten(50)
```

Lightening adds the specified amount to each color channel. If the result would exceed 255, it stops at 255.

Darkening a color:

```crystal
light_gray = Color.gray(200)
dark_gray = light_gray.darken(50)
```

Darkening subtracts the specified amount from each color channel. If the result would go below 0, it stops at 0.

Converting to hex:

```crystal
color = Color.rgb(255, 100, 50)
hex = color.to_hex  # Returns 0xFF6432FF (includes alpha)
```

Where Colors Are Used

Colors appear throughout the framework:

- Background color of views: view.background_color = color
- Text color: label.color = color
- Button text color: button.text_color = color
- Border color: view.border_color = color
- Shadow color: shadow.color = color
- Theme colors: Theme.primary_color = color

## Edge Insets

Edge insets represent space around a view's content. They are used for padding (space inside a view) and margins (space outside a view).

Understanding Edge Insets

Think of a picture frame. The frame has thickness on all four sides. That thickness is padding. It pushes the picture inward from the edge of the frame.

Edge insets have four components:

- Top: space above the content
- Left: space to the left of the content
- Bottom: space below the content
- Right: space to the right of the content

Each component is measured in pixels.

Creating Edge Insets

Individual sides:

```crystal
insets = EdgeInsets.new(top: 10, left: 20, bottom: 10, right: 20)
```

This creates 10 pixels of padding at the top and bottom, and 20 pixels at the left and right.

All sides the same:

```crystal
insets = EdgeInsets.all(16)
```

This creates 16 pixels of padding on all four sides.

Horizontal only:

```crystal
insets = EdgeInsets.horizontal(20)
```

This creates 20 pixels of padding on the left and right. Top and bottom are zero.

Vertical only:

```crystal
insets = EdgeInsets.vertical(20)
```

This creates 20 pixels of padding at the top and bottom. Left and right are zero.

Accessing Components

Once you have an edge insets object, you can read each component:

```crystal
top = insets.top
left = insets.left
bottom = insets.bottom
right = insets.right
```

Where Edge Insets Are Used

The primary use of edge insets is in the Container component:

```crystal
container = UI::Container.new
container.padding = EdgeInsets.all(20)
```

The container reserves space for padding, then places its child inside the remaining area.

## Corner Radius

Corner radius rounds the corners of rectangular views. Without corner radius, all views have sharp 90-degree corners. With corner radius, the corners become rounded.

Understanding Corner Radius

The corner radius value determines how rounded the corners appear. A radius of 0 produces sharp corners. A radius of 10 produces slightly rounded corners. A radius of 50 produces very rounded corners. If the radius equals half the view's width or height, the ends become fully circular.

Corner radius can be applied independently to each corner:

- Top-left
- Top-right
- Bottom-left
- Bottom-right

### Creating Corner Radius

All corners the same:

```crystal
radius = CornerRadius.all(8)
```

This creates 8-pixel rounding on all four corners.

Individual corners:

```crystal
radius = CornerRadius.new(
  top_left: 8,
  top_right: 8,
  bottom_left: 0,
  bottom_right: 0
)
```

This creates rounded top corners but sharp bottom corners. This is common for cards that sit flush against the bottom of the screen.

Where Corner Radius Is Used

Corner radius applies to the view's background and border:

```crystal
view.background_color = Color.blue
view.corner_radius = CornerRadius.all(8)
```

The background will have rounded corners. Any child views are clipped to the rounded shape.

## Fonts

Fonts control how text looks: the typeface, size, and weight (boldness).

Font Properties

A font has three properties:

- Name: the typeface name like "System", "Arial", "Roboto", or "San Francisco"
- Size: the point size (typical text is 16 points)
- Weight: how bold the text appears

Font Weights

Native.cr provides five font weights:

Weight Description
FontWeight::Normal Regular text (400)
FontWeight::Light Light text (300)
FontWeight::Medium Medium text (500)
FontWeight::Semibold Semi-bold text (600)
FontWeight::Bold Bold text (700)

## Creating Fonts

System font (default):

```crystal
font = Font.system(16)
```

This creates the platform's default system font at 16 points with normal weight.

System font with weight:

```crystal
font = Font.system(16, FontWeight::Bold)
```

System bold font (shortcut):

```crystal
font = Font.bold(16)
```

This is equivalent to Font.system(16, FontWeight::Bold).

Custom font by name:

```crystal
font = Font.new("Roboto", 16, FontWeight::Normal)
```

This loads a custom font. You must include the font file in your app's assets.

Where Fonts Are Used

Fonts are used primarily in text components:

```crystal
label = UI::Text.new
label.text = "Hello"
label.font = Font.bold(24)
```

If you do not set a font, the component uses Theme.font (system font at 16 points).

## Shadows

Shadows add depth to views by creating the illusion that the view floats above the background.

Shadow Properties

A shadow has four components:

- Color: the color of the shadow (typically black with some transparency)
- Offset X: how far to the right the shadow appears (negative moves left)
- Offset Y: how far down the shadow appears (negative moves up)
- Blur: how soft or sharp the shadow edges appear

Creating a Shadow

```crystal
shadow = Shadow.new
shadow.color = Color.black.with_alpha(128)
shadow.offset_x = 0
shadow.offset_y = 4
shadow.blur = 8
```

This creates a shadow that appears 4 pixels directly below the view with 8 pixels of blur.

## Shadow Effects

Bottom shadow (most common):

```crystal
shadow = Shadow.new
shadow.offset_y = 4
shadow.blur = 8
```

This creates a shadow dropping downward, making the view appear to float above the background.

Top shadow:

```crystal
shadow = Shadow.new
shadow.offset_y = -4
shadow.blur = 8
```

This creates a shadow rising upward.

No offset (glow effect):

```crystal
shadow = Shadow.new
shadow.offset_x = 0
shadow.offset_y = 0
shadow.blur = 16
```

This creates a glow effect around the view.

Where Shadows Are Used

Shadows apply to any view:

```crystal
card = UI::View.new
card.background_color = Color.white
card.corner_radius = CornerRadius.all(12)
card.shadow = shadow
```

## Theme System

The theme system provides global styling defaults. Instead of setting the same properties on every component, you set them once in the theme and all components inherit them.

Theme Properties

The theme contains these properties:

Property Type Default Description
primary_color Color Blue Main brand color
secondary_color Color Gray(100) Secondary brand color
background_color Color White Default app background
text_color Color Black Default text color
error_color Color Red Color for error messages
success_color Color Green Color for success messages
font Font System(16) Default body font
heading_font Font Bold(24) Default heading font
corner_radius CornerRadius All(8) Default corner rounding
spacing Int32 16 Default spacing between elements

Setting Theme Values

You can change any theme property at app startup:

```crystal
def setup
  Theme.primary_color = Color.hex(0x6200EE)
  Theme.background_color = Color.gray(245)
  Theme.font = Font.system(14)
  Theme.spacing = 24
  
  # Rest of setup...
end
```

## Using Theme Values

When you create components, you can reference theme values:

```crystal
button = UI::Button.new
button.background_color = Theme.primary_color

label = UI::Text.new
label.font = Theme.font
```

Theme Inheritance

Components do not automatically inherit theme values. You must explicitly apply theme values when creating components. The style helpers (described below) handle this for you.

## Style Helpers

Style helpers are pre-configured components that follow the current theme. They save you from writing repetitive styling code.

Creating a Primary Button

```crystal
button = Style.button_primary
button.text = "Submit"
```

The primary button uses Theme.primary_color for its background and Color.white for its text.

Creating a Secondary Button

```crystal
button = Style.button_secondary
button.text = "Cancel"
```

The secondary button uses Theme.secondary_color for its background and Theme.text_color for its text.

Creating a Card Container

```crystal
card = Style.card
card.add_child(content)
```

The card has a white background, rounded corners, a shadow, and padding based on Theme.spacing.

Creating Headings

```crystal
heading = Style.heading("Welcome")
```

The heading uses Theme.heading_font and Theme.text_color.

Creating Body Text

```crystal
body = Style.body("This is regular text.")
```

The body text uses Theme.font and Theme.text_color.

## Complete Styling Example

Here is an example that demonstrates all styling concepts together:

```crystal
class StyledApp < Native::App
  def setup
    # Set global theme
    Theme.primary_color = Color.hex(0x6200EE)
    Theme.background_color = Color.gray(245)
    Theme.font = Font.system(16)
    Theme.heading_font = Font.bold(24)
    Theme.spacing = 20
    
    # Apply theme background
    set_background_color(Theme.background_color)
    
    # Create card
    card = Style.card
    
    # Card heading
    heading = Style.heading("Welcome to Styled App")
    
    # Card body text
    body = Style.body("This card demonstrates the styling system. All colors, fonts, and spacing come from the theme.")
    
    # Custom colored text
    accent = UI::Text.new
    accent.text = "This text uses the primary color."
    accent.text_size = 14
    accent.color = Theme.primary_color
    
    # Primary button
    button = Style.button_primary
    button.text = "Get Started"
    button.on_click = ->{ on_start }
    
    # Arrange in column
    column = UI::Column.new
    column.spacing = Theme.spacing
    column.add_child(heading)
    column.add_child(body)
    column.add_child(accent)
    column.add_child(button)
    
    card.add_child(column)
    @root = card
  end

  def on_start
    puts "Started!"
  end

  def draw
    @root.draw(renderer)
  end
end

Native::App.start(StyledApp)
```

## Best Practices

Use Theme for Consistency

Set theme values once at app startup. Use them throughout your app. This makes global design changes easy.

Create Custom Style Helpers

If you have repeated styling patterns, create your own helpers:

```crystal
module MyStyles
  def self.danger_button
    button = UI::Button.new
    button.background_color = Color.red
    button.text_color = Color.white
    button.corner_radius = CornerRadius.all(4)
    button
  end
end

# Usage
delete_button = MyStyles.danger_button
delete_button.text = "Delete"
```

## Avoid Hardcoding Values

Do not scatter magic numbers throughout your code:

```crystal
# Bad
label.text_size = 16

# Good
label.text_size = Theme.font.size
```

Use Semantic Colors

Name your colors by purpose, not value:

```crystal
# Bad
button.background_color = Color.hex(0x6200EE)

# Good
Theme.primary_color = Color.hex(0x6200EE)
button.background_color = Theme.primary_color
```

## Next Steps

Now that you understand styling, learn about:

- Events & Gestures - Handle user interaction
- Animations - Add motion to your UI
- Networking - Load data from the internet
