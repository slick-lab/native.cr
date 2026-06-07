---
title: Welcome to native.cr
---

# Welcome to native.cr

## What is native.cr?

native.cr is a framework for building native mobile applications using the [Crystal programming language](https://crystal-lang.org/).

Write your app logic once in Crystal. Compile directly to ARM64 code for Android and iOS. No JavaScript bridge. No embedded interpreters. Just Crystal calling native APIs through FFI.

## Why native.cr?

| Problem | Solution |
|---------|----------|
| React Native has a slow JS bridge | Direct native calls, no serialization |
| Flutter uses Dart, not Crystal | Write Crystal everywhere |
| Kotlin Multiplatform requires platform UI | Full UI framework in Crystal |
| Building mobile apps in Crystal wasn't possible | Now it is |


## Features

- **UI Components** - View, Text, Button, Column, Row, Container, Image
- **Styling** - Colors, fonts, themes, edge insets, corner radius
- **Events** - Touch, gestures, key events
- **Animations** - Smooth transitions with curves
- **Camera** - Photo capture, video recording, preview
- **Network** - HTTP client, WebSocket
- **Storage** - Preferences, file storage, SQLite
- **Audio** - Sound effects, music playback, recording
- **Platform** - Device info, battery, sensors, geolocation
- **Biometric** - Fingerprint and Face ID authentication
- **Payments** - In-app purchases
- **Game Loop** - Fixed and variable timestep

## Quick Example

```crystal
class MyApp < Native::App
  @[Preserve]
  property counter : Int32 = 0

  def setup
    set_background_color(240, 240, 245)
    
    label = UI::Text.new
    label.text = "Hello, native.cr!"
    label.text_size = 24
    
    button = UI::Button.new
    button.text = "Tap me"
    button.on_click = ->{ increment_counter }
    
    column = UI::Column.new
    column.spacing = 20
    column.add_child(label)
    column.add_child(button)
    
    @root = column
  end
  
  def increment_counter
    @counter += 1
    change_color(100 + (@counter * 10) % 155, 100, 100)
  end
end

Native::App.start(MyApp)
```

## Next Steps

- Installation
- First App
- UI Components
