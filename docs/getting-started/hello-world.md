
---
title: Hello World
---

# Hello World

This guide walks you through creating your first native.cr application. We will start with nothing and build a complete working app line by line. Every concept is explained before you see any code.

## What You Are Building

You are building a mobile app that displays text on the screen. When the user taps the screen, a counter increases and the display updates. This teaches you the fundamental patterns of every native.cr app: the App class, UI components, state preservation, and event handling.

## The App Class

Every native.cr application starts with a class that inherits from `Native::App`. This base class provides everything your app needs to run on Android and iOS. Your job is to override two methods: `setup` and `draw`.

The `setup` method runs once when your app starts. You use it to create your user interface, set background colors, load data, and prepare anything else your app needs.

The `draw` method runs every frame, typically 60 times per second. You use it to draw your user interface on the screen. For simple apps, you just tell your root view to draw itself.

Here is the smallest possible native.cr application:

```crystal
class HelloApp < Native::App
  def setup
    # This runs once at startup
  end

  def draw
    # This runs every frame
  end
end

Native::App.start(HelloApp)
```

This app does nothing because setup and draw are empty. Let us add something visible.

## Adding a Text Label

To show something on screen, you need a UI component. The most basic component is UI::Text. It displays a string of text with a specific size and color.

A UI::Text object has several properties you can set:

· text - The string to display
· text_size - Font size in points
· color - The text color
· x and y - Position on screen

In setup, you create the text label and store it in an instance variable so you can access it later. Then you assign it to @root. The draw method will call draw on whatever view is stored in @root.

```crystal
class HelloApp < Native::App
  def setup
    @label = UI::Text.new
    @label.text = "Hello, World!"
    @label.text_size = 32
    @label.color = Color.white
    
    @root = @label
  end

  def draw
    @root.draw(renderer)
  end
end

Native::App.start(HelloApp)
```

If you run this app, you will see white text that says "Hello, World!" on a black background. The background is black because we did not set a background color yet.

## Setting Background Color

A plain black background works but looks boring. You can change the background color using the set_background_color method. It takes three numbers between 0 and 255 representing red, green, and blue.

Call this method in setup before creating your UI components.

```crystal
class HelloApp < Native::App
  def setup
    set_background_color(100, 150, 200)
    
    @label = UI::Text.new
    @label.text = "Hello, World!"
    @label.text_size = 32
    @label.color = Color.white
    
    @root = @label
  end

  def draw
    @root.draw(renderer)
  end
end

Native::App.start(HelloApp)
```

Now your app has a pleasant blue background. The numbers (100, 150, 200) produce a medium blue color. Lower numbers make darker colors. Higher numbers make brighter colors.

## Making the App Interactive

A static text label is not very interesting. Let us make the app respond when the user taps the screen. When the user taps, we will change the text.

Native.cr provides several lifecycle methods you can override. One of them is on_touch_began. This method runs whenever the user touches the screen. It receives the x and y coordinates of the touch as Float32 values.

You do not need to do anything with the coordinates for this example. You just need to change the text when a tap happens.

To change the text, you access the text property of your label and assign a new string.

```crystal
class HelloApp < Native::App
  def setup
    set_background_color(100, 150, 200)
    
    @label = UI::Text.new
    @label.text = "Hello, World!"
    @label.text_size = 32
    @label.color = Color.white
    
    @root = @label
  end

  def on_touch_began(x : Float32, y : Float32)
    @label.text = "You tapped the screen!"
  end

  def draw
    @root.draw(renderer)
  end
end

Native::App.start(HelloApp)
```

Now when you tap anywhere on the screen, the text changes from "Hello, World!" to "You tapped the screen!". The text stays changed until you tap again.

Adding a Counter

Changing to a fixed message works, but what if you want to count how many times the user tapped? You need to store a number that increases each time.

Create an instance variable called @count and set it to 0 in setup. Then in on_touch_began, increase it by 1 and update the label to show the current count.

```crystal
class HelloApp < Native::App
  def setup
    set_background_color(100, 150, 200)
    
    @count = 0
    
    @label = UI::Text.new
    @label.text = "Taps: 0"
    @label.text_size = 32
    @label.color = Color.white
    
    @root = @label
  end

  def on_touch_began(x : Float32, y : Float32)
    @count += 1
    @label.text = "Taps: #{@count}"
  end

  def draw
    @root.draw(renderer)
  end
end

Native::App.start(HelloApp)
```

Each tap increases the count. The label updates to show the new number.

Preserving State Across Restarts

You might have noticed that native.cr reload recompiles and restarts your app when you save a file. During development, this happens frequently. By default, your @count variable would reset to 0 every time because the app starts fresh.

However, native.cr has a feature called state preservation. When you mark an instance variable with @[Preserve], the framework saves its value before restart and restores it after restart.

Add @[Preserve] above your @count declaration:

```crystal
class HelloApp < Native::App
  def setup
    set_background_color(100, 150, 200)
    
    @label = UI::Text.new
    @label.text = "Taps: #{@count}"
    @label.text_size = 32
    @label.color = Color.white
    
    @root = @label
  end

  @[Preserve]
  property count : Int32 = 0

  def on_touch_began(x : Float32, y : Float32)
    @count += 1
    @label.text = "Taps: #{@count}"
  end

  def draw
    @root.draw(renderer)
  end
end

Native::App.start(HelloApp)
```

Notice we changed @count to a property with a default value of 0. The @[Preserve] annotation works on properties. Now when you edit your code and save, the app restarts but your tap count remains.

Improving the Display with Proper English

The text "Taps: 1" is fine, but "Taps: 1 times" is grammatically incorrect. You should show "Taps: 1 time" for a single tap and "Taps: 2 times" for multiple taps.

Use a conditional expression to choose the correct word:

```crystal
def on_touch_began(x : Float32, y : Float32)
  @count += 1
  if @count == 1
    @label.text = "Taps: 1 time"
  else
    @label.text = "Taps: #{@count} times"
  end
end
```

You can make this cleaner by using a ternary operator:

```crystal
def on_touch_began(x : Float32, y : Float32)
  @count += 1
  @label.text = @count == 1 ? "Taps: 1 time" : "Taps: #{@count} times"
end
```

Adding Color Feedback

Make the app more visually interesting by changing the background color every few taps. For example, change color every 5 taps.

First, create a helper method that sets the background color based on the current count. Then call it whenever the count changes.

```crystal
class HelloApp < Native::App
  def setup
    set_background_color(100, 150, 200)
    update_background
    
    @label = UI::Text.new
    @label.text = "Taps: 0"
    @label.text_size = 32
    @label.color = Color.white
    
    @root = @label
  end

  @[Preserve]
  property count : Int32 = 0

  def update_background
    if @count % 5 == 0
      set_background_color(100, 150, 200)  # Blue
    elsif @count % 5 == 1
      set_background_color(100, 200, 100)  # Green
    elsif @count % 5 == 2
      set_background_color(200, 200, 100)  # Yellow
    elsif @count % 5 == 3
      set_background_color(200, 100, 100)  # Red
    else
      set_background_color(150, 100, 200)  # Purple
    end
  end

  def on_touch_began(x : Float32, y : Float32)
    @count += 1
    @label.text = @count == 1 ? "Taps: 1 time" : "Taps: #{@count} times"
    update_background
  end

  def draw
    @root.draw(renderer)
  end
end

Native::App.start(HelloApp)
```

The modulo operator (%) gives the remainder after division. So @count % 5 cycles through 0, 1, 2, 3, 4 repeatedly as the count increases. Each remainder value maps to a different color.

Adding a Button Instead of Screen Taps

Some users might expect a button rather than tapping anywhere. Native.cr provides a UI::Button component. A button has a text property and an on_click callback.

Instead of overriding on_touch_began, you create a button and set its on_click property to a block of code or a method reference.

```crystal
class HelloApp < Native::App
  def setup
    set_background_color(240, 240, 245)
    
    @label = UI::Text.new
    @label.text = "Taps: 0"
    @label.text_size = 24
    @label.color = Color.dark_gray
    
    @button = UI::Button.new
    @button.text = "Tap Me"
    @button.width = 120
    @button.height = 44
    @button.on_click = ->{ increment }
    
    column = UI::Column.new
    column.spacing = 20
    column.add_child(@label)
    column.add_child(@button)
    
    @root = column
  end

  @[Preserve]
  property count : Int32 = 0

  def update_display
    @label.text = @count == 1 ? "Taps: 1 time" : "Taps: #{@count} times"
  end

  def increment
    @count += 1
    update_display
  end

  def draw
    @root.draw(renderer)
  end
end

Native::App.start(HelloApp)
```

This example introduces UI::Column, which arranges its children vertically. The column has a spacing property that determines how many pixels appear between children. The label appears above the button.

## Complete Hello World Example

Here is the final version with everything we learned:

```crystal
class HelloApp < Native::App
  def setup
    set_background_color(245, 245, 250)
    
    # Create the title label
    @title = UI::Text.new
    @title.text = "Hello, World!"
    @title.text_size = 28
    @title.color = Color.dark_gray
    
    # Create the counter label
    @counter = UI::Text.new
    @counter.text_size = 24
    @counter.color = Color.blue
    update_counter_display
    
    # Create the button
    @button = UI::Button.new
    @button.text = "Tap Me"
    @button.width = 120
    @button.height = 44
    @button.on_click = ->{ increment_counter }
    
    # Arrange everything in a column
    column = UI::Column.new
    column.spacing = 24
    column.add_child(@title)
    column.add_child(@counter)
    column.add_child(@button)
    
    # Center the column on screen
    @root = column
  end

  @[Preserve]
  property count : Int32 = 0

  def update_counter_display
    if @count == 0
      @counter.text = "Not tapped yet"
    elsif @count == 1
      @counter.text = "Tapped 1 time"
    else
      @counter.text = "Tapped #{@count} times"
    end
  end

  def increment_counter
    @count += 1
    update_counter_display
  end

  def draw
    @root.draw(renderer)
  end
end

Native::App.start(HelloApp)
```

## What You Learned

- Every app inherits from Native::App and overrides setup and draw
- setup runs once at startup for creating UI
- draw runs every frame for rendering
- UI::Text displays strings with configurable size and color
- UI::Button creates tappable buttons with on_click callbacks
- UI::Column arranges children vertically with spacing
- set_background_color changes the screen color using RGB values
- @[Preserve] keeps variables alive across fast restarts
- on_touch_began responds to screen taps anywhere
- The modulo operator % creates repeating patterns

Running Your App

To run this app, save it as src/main.cr and run:

```bash
native.cr reload src/main.cr
```

Your app will start. Tap the button. Watch the counter increase. Edit the code and save to see fast restart in action with state preservation.

Next Steps

Now that you understand the basics, explore these guides:

- UI Components - Learn all available components
- Styling - Colors, fonts, themes, and layouts
- Events - Touch, gestures, and keyboard input
- Animations - Make your UI come alive

