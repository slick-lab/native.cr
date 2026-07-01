# Navigation

Toolbar and screen navigation.

---

## Toolbar

Top app bar with title and menu:

```crystal
toolbar = Native::Navigation::Toolbar.new
toolbar.title = "My App"
toolbar.subtitle = "Settings"
toolbar.setupWithActivity
```

---

## Menu Items

Add action buttons:

```crystal
toolbar.add_menu_item(1, "Settings", icon: R.drawable.settings, show_as_action: true)
toolbar.add_menu_item(2, "Help")

toolbar.on_menu_item_click { |id|
  case id
  when 1 then open_settings
  when 2 then show_help
  end
}
```

---

## Navigation Icon

Back button or custom icon:

```crystal
toolbar.navigation_icon = R.drawable.back_arrow

toolbar.on_navigation_click { go_back }
```

---

## Properties

| Property | Type | Description |
|----------|------|-------------|
| `title` | String | Main title |
| `subtitle` | String | Secondary text |
| `navigation_icon` | Int32 | Resource ID for nav button |

---

## MenuItem

| Field | Type | Description |
|-------|------|-------------|
| `id` | Int32 | Identifier for click handling |
| `title` | String | Display text |
| `icon` | Int32 | Resource ID (0 = none) |
| `show_as_action` | Bool | Show in bar vs overflow |

---

## Example: Main Screen

```crystal
class MainApp < Native::App
  def setup
    build_toolbar
    @content = Native::UI::TextView.new("Welcome!")
    @root = layout
  end

  def build_toolbar
    @toolbar = Native::Navigation::Toolbar.new
    @toolbar.title = "My App"
    @toolbar.add_menu_item(1, "Settings", show_as_action: false)
    @toolbar.add_menu_item(2, "About", show_as_action: false)

    @toolbar.on_menu_item_click { |id| handle_menu(id) }
    @toolbar.setupWithActivity
  end

  def handle_menu(id)
    case id
    when 1 then open_settings
    when 2 then show_about
    end
  end
end
```

---

## Example: Detail Screen

```crystal
class DetailApp < Native::App
  def setup
    @toolbar = Native::Navigation::Toolbar.new
    @toolbar.title = "Item Details"
    @toolbar.navigation_icon = R.drawable.back
    @toolbar.on_navigation_click { go_back }

    @content = Native::UI::TextView.new(@item.name)
    @root = layout
  end

  def go_back
    # Navigate back or finish activity
  end
end
```

---

## Screen Stack Pattern

For multi-screen apps, manage a stack manually:

```crystal
class NavigationApp < Native::App
  @[Preserve]
  property screens : Array(String) = [] of String

  def push_screen(name)
    @screens.push(name)
    show_current_screen
  end

  def pop_screen
    @screens.pop?
    show_current_screen
  end

  def current_screen
    @screens.last? || "home"
  end

  def show_current_screen
    @content = build_screen(current_screen)
  end
end
```

---

## Platform Notes

**Android:** Uses `androidx.appcompat.widget.Toolbar`. Call `setupWithActivity` to set as ActionBar.

**iOS:** Uses `UINavigationBar`. The toolbar integrates with the navigation controller.
