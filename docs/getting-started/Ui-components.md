
---
title: UI Components
---

# UI Components

Native.cr provides a set of UI components for building mobile interfaces. Every component inherits from `UI::View`, which provides common properties like position, size, visibility, and background color.

## The View Base Class

`UI::View` is the foundation of every UI component. It provides properties and methods that all other components inherit.

### Position and Size

Every view has an `x` and `y` position relative to its parent. The top-left corner of the parent is (0, 0). Positive x moves right. Positive y moves down.

```crystal
view = UI::View.new
view.x = 10    # 10 pixels from left edge of parent
view.y = 20    # 20 pixels from top edge of parent
```

Every view also has width and height. These determine how much space the view occupies.

```crystal
view.width = 200   # 200 pixels wide
view.height = 100  # 100 pixels tall
```

If you do not set width and height, some components calculate their own size based on their content. A UI::Text component automatically sizes itself to fit its text. A UI::Button has default dimensions but can be overridden.

## Visibility

The visible property controls whether a view appears on screen. Invisible views still exist in memory and still have positions, but they are not drawn and do not receive touch events.

```crystal
view.visible = true   # View is visible (default)
view.visible = false  # View is hidden
```

This is useful for temporarily hiding UI elements without destroying them.

## Opacity

The alpha property controls transparency. A value of 1.0 means fully opaque (solid). A value of 0.0 means fully transparent (invisible). Values between make the view partially transparent.

```crystal
view.alpha = 1.0   # Fully opaque (default)
view.alpha = 0.5   # 50% transparent
view.alpha = 0.0   # Fully transparent
```

When a view has transparency, its children are also affected. The entire view hierarchy becomes partially see-through.

## Background Color

The background_color property sets the fill color behind the view's content.

```crystal
view.background_color = Color.red
view.background_color = Color.rgb(100, 150, 200)
view.background_color = Color.hex(0x3366FF)
```

By default, views have no background color (transparent). If you want to see a view's bounds, set a background color.

## Corner Radius

The corner_radius property rounds the corners of the view and its background.

```crystal
view.corner_radius = CornerRadius.all(8)
view.corner_radius = CornerRadius.new(top_left: 8, top_right: 8, bottom_left: 0, bottom_right: 0)
```

This is useful for creating rounded buttons, cards, or image frames.

## Shadow

The shadow property adds a drop shadow behind the view.

```crystal
shadow = Shadow.new
shadow.color = Color.black
shadow.offset_x = 0
shadow.offset_y = 2
shadow.blur = 4

view.shadow = shadow
```

Shadows give visual depth and help separate UI layers. They are computationally expensive, so use them sparingly.

## View Hierarchy

Views can contain other views. This creates a hierarchy called the view tree. The root view at the top contains children, which may contain their own children.

```crystal
parent = UI::View.new
child = UI::View.new

parent.add_child(child)
```

When a parent moves, its children move with it. When a parent becomes invisible, its children become invisible. When a parent is destroyed, its children are destroyed.

To add a child:

```crystal
parent.add_child(child)
```

To remove a child:

```crystal
parent.remove_child(child)
```

To get all children:

```crystal
children = parent.children
```

The order of children matters. Children added first draw first (behind). Children added later draw later (in front). This is called the painter's algorithm.

## Absolute Position

Every view has an absolute_x and absolute_y property. These return the view's position relative to the screen, not relative to its parent. The calculation adds up the positions of all ancestors.

```crystal
screen_x = view.absolute_x
screen_y = view.absolute_y
```

This is useful for hit testing and manual drawing calculations.

## Hit Testing

Views can detect whether a point falls inside their bounds using hit_test.

```crystal
inside = view.hit_test(x, y)
```

This method checks if the point is within the view's visible area and within its frame. It returns true if the point is inside, false otherwise.

Text Component

UI::Text displays a string of text on the screen.

Properties

Property Type Description
text String The text to display
text_size Int32 Font size in points
color Color Text color
font Font Font configuration
text_alignment Alignment Left, center, or right alignment

## Creating Text

```crystal
label = UI::Text.new
label.text = "Hello, World!"
label.text_size = 24
label.color = Color.black
```

Setting Font

```crystal
label.font = Font.system(24)
label.font = Font.bold(24)
label.font = Font.new("Roboto", 24, FontWeight::Medium)
```

Alignment

```crystal
label.text_alignment = Alignment::Left    # Default
label.text_alignment = Alignment::Center
label.text_alignment = Alignment::Right
```

## Automatic Sizing

A UI::Text component automatically calculates its width and height based on the text content and text size. You do not need to set width and height manually unless you want to override them.

```crystal
label = UI::Text.new
label.text = "This is a long sentence"
# width and height are automatically calculated
```

If you set width manually, the text will wrap to fit.

```crystal
label.width = 200
label.text = "This long sentence will wrap to multiple lines"
```

## Button Component

UI::Button is a tappable component that responds to clicks. It combines a text label with a clickable area and visual feedback.

Properties

Property Type Description
text String Button label
text_size Int32 Font size
text_color Color Label color
background_color Color Button fill color
on_click -> Nil Callback when tapped

## Creating a Button

```crystal
button = UI::Button.new
button.text = "Submit"
button.width = 120
button.height = 44
button.background_color = Color.blue
button.text_color = Color.white
button.corner_radius = CornerRadius.all(8)
```

## Setting Click Handler

There are two ways to set a click handler.

Using a proc with a method reference:

```crystal
button.on_click = ->{ handle_click }

def handle_click
  puts "Button clicked"
end
```

Using a block (Crystal syntax):

```crystal
button.on_click = ->{
  puts "Button clicked"
}
```

Default Button Sizing

If you do not set width and height, a button uses default values of 100 pixels wide and 40 pixels tall. You should typically set explicit dimensions for buttons.

## Button States

Buttons do not have built-in pressed, hovered, or disabled states in the current version. You can implement these yourself by changing properties in the click handler.

```crystal
def handle_click
  @button.background_color = Color.green
  # Perform action
  @button.background_color = Color.blue
end
```

## Column Component

UI::Column arranges its children vertically from top to bottom. Each child appears below the previous child.

Properties

Property Type Description
spacing Int32 Pixels between children
alignment Alignment Horizontal alignment of children

## Creating a Column

```crystal
column = UI::Column.new
column.spacing = 16
column.alignment = Alignment::Center
```

## Adding Children

```crystal
column.add_child(first_view)
column.add_child(second_view)
column.add_child(third_view)
```

How Column Calculates Layout

When you call layout on a column, it does the following:

1. Measures each child to get its natural size
2. Positions children one below another
3. Adds spacing between children
4. Aligns children horizontally based on the alignment setting

You do not need to set y positions manually. The column handles everything.

Alignment Options

Alignment Effect
Alignment::Start Children align to the left
Alignment::Center Children center horizontally
Alignment::End Children align to the right
Alignment::Stretch Children stretch to fill column width

Row Component

UI::Row arranges its children horizontally from left to right. Each child appears to the right of the previous child.

Properties

Property Type Description
spacing Int32 Pixels between children
alignment Alignment Vertical alignment of children

## Creating a Row

```crystal
row = UI::Row.new
row.spacing = 8
row.alignment = Alignment::Center
```

## Adding Children

```crystal
row.add_child(first_button)
row.add_child(second_button)
row.add_child(third_button)
```

## Alignment Options

Alignment Effect
Alignment::Start Children align to the top
Alignment::Center Children center vertically
Alignment::End Children align to the bottom
Alignment::Stretch Children stretch to fill row height

Container Component

UI::Container wraps a single child with padding. Padding adds empty space around the child inside the container.

Properties

Property Type Description
padding EdgeInsets Space around the child

## Creating a Container

```crystal
container = UI::Container.new
container.padding = EdgeInsets.all(20)
container.add_child(content)
```

Padding Options

```crystal
# Same padding on all sides
padding = EdgeInsets.all(16)

# Different padding per side
padding = EdgeInsets.new(top: 10, left: 20, bottom: 10, right: 20)

# Horizontal only
padding = EdgeInsets.horizontal(20)

# Vertical only
padding = EdgeInsets.vertical(20)
```

## How Container Works

The container reserves space for padding, then places its child inside the remaining area. The child does not need to know about the padding. The container handles everything.

## Image Component

UI::Image displays raster images from files or memory.

## Properties

Property Type Description
image ImageData The image data to display
scale_mode ScaleMode How to fit image within bounds

## Loading an Image

### From a file:

```crystal
image = UI::Image.new
if image.load("/assets/photo.png")
  puts "Image loaded successfully"
else
  puts "Failed to load image"
end
```

### From memory:

```crystal
image = UI::Image.new
image.load(bytes, "png")
```

## Scale Modes

Mode Description
ScaleMode::Fill Stretch to fill exactly (may distort)
ScaleMode::AspectFit Scale to fit within bounds, preserving aspect ratio (may leave empty space)
ScaleMode::AspectFill Scale to fill bounds, preserving aspect ratio (may crop)
ScaleMode::Stretch Stretch to fill exactly (same as Fill)

```crystal
image.scale_mode = ScaleMode::AspectFit
```

## Image Dimensions

Set width and height to control the display size. The original image dimensions do not affect display size unless you set scale mode accordingly.

```crystal
image.width = 200
image.height = 200
image.scale_mode = ScaleMode::AspectFit
```

## Putting It All Together

Here is a complete example using multiple components:

```crystal
class MyApp < Native::App
  def setup
    # Create components
    title = UI::Text.new
    title.text = "Welcome"
    title.text_size = 28
    title.color = Color.dark_gray
    
    description = UI::Text.new
    description.text = "This is a description that spans multiple lines and explains what the user should do next."
    description.text_size = 16
    description.color = Color.gray(100)
    
    image = UI::Image.new
    image.load("/assets/logo.png")
    image.width = 100
    image.height = 100
    image.scale_mode = ScaleMode::AspectFit
    
    button = UI::Button.new
    button.text = "Get Started"
    button.width = 160
    button.height = 44
    button.background_color = Color.blue
    button.text_color = Color.white
    button.corner_radius = CornerRadius.all(8)
    button.on_click = ->{ start_app }
    
    # Arrange in column
    column = UI::Column.new
    column.spacing = 24
    column.alignment = Alignment::Center
    column.add_child(title)
    column.add_child(image)
    column.add_child(description)
    column.add_child(button)
    
    # Add padding around everything
    container = UI::Container.new
    container.padding = EdgeInsets.all(20)
    container.add_child(column)
    
    @root = container
  end

  def start_app
    puts "App started!"
  end

  def draw
    @root.draw(renderer)
  end
end
```

## Next Steps

Now that you understand UI components, learn about:

- Styling & Themes - Make your UI beautiful
- Events & Gestures - Handle user interaction
- Animations - Add motion to your UI
