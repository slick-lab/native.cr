# Navigation

Build multi-screen apps with navigation patterns.

---

## Navigation Concepts

Most apps have multiple screens. native.cr doesn't enforce a specific navigation architecture, giving you flexibility to choose what works best for your app.

Common patterns:

- **Screen Stack**: Push/pop screens like a browser history
- **Tab Navigation**: Bottom tabs for main sections
- **Drawer Navigation**: Side menu for navigation
- **Modal Screens**: Temporary overlays

---

## Simple Screen Switching

For apps with few screens, use conditional rendering:

```crystal
class MyApp < Native::App
  @[Preserve]
  property current_screen = :home

  def setup
    @root = build_ui
  end

  def build_ui
    @container = Native::UI::FrameLayout.new
    show_screen(@current_screen)
    @container
  end

  def show_screen(screen : Symbol)
    @container.clear
    case screen
    when :home
      @container.addView(build_home_screen)
    when :settings
      @container.addView(build_settings_screen)
    when :profile
      @container.addView(build_profile_screen)
    end
    @current_screen = screen
  end

  def navigate_to(screen : Symbol)
    show_screen(screen)
  end

  def go_back
    # Implement back stack logic
  end
end
```

---

## Screen Stack Manager

For complex navigation, manage a stack:

```crystal
class NavigationManager
  @screens = [] of Symbol
  @on_change : (Symbol -> Nil)?

  def initialize(@initial : Symbol)
    @screens << @initial
  end

  def on_screen_change(&callback : Symbol -> Nil)
    @on_change = callback
  end

  def push(screen : Symbol)
    @screens.push(screen)
    @on_change.try &.call(screen)
  end

  def pop : Bool
    return false if @screens.size <= 1
    @screens.pop
    @on_change.try &.call(@screens.last)
    true
  end

  def replace(screen : Symbol)
    @screens[-1] = screen
    @on_change.try &.call(screen)
  end

  def current : Symbol
    @screens.last
  end

  def can_go_back? : Bool
    @screens.size > 1
  end

  def reset_to(screen : Symbol)
    @screens = [screen]
    @on_change.try &.call(screen)
  end
end
```

Using the manager:

```crystal
class MyApp < Native::App
  @nav : NavigationManager

  def setup
    @nav = NavigationManager.new(:home)
    @nav.on_screen_change { |screen| render_screen(screen) }
    @root = build_ui
    render_screen(:home)
  end

  def render_screen(screen : Symbol)
    @container.clear

    view = case screen
           when :home then build_home
           when :detail then build_detail
           when :settings then build_settings
           else raise "Unknown screen: #{screen}"
           end

    @container.addView(view)
  end

  def navigate(screen : Symbol)
    @nav.push(screen)
  end

  def go_back
    @nav.pop
  end
end
```

---

## Toolbar

Display a title bar with navigation and actions.

```crystal
def build_toolbar(title : String) : Native::Navigation::Toolbar
  toolbar = Native::Navigation::Toolbar.new
  toolbar.title = title
  toolbar.subtitle = ""

  # Menu items
  toolbar.add_menu_item(1, "Settings", show_as_action: false)
  toolbar.add_menu_item(2, "About", show_as_action: false)

  toolbar.on_menu_item_click { |id| handle_menu(id) }

  # Back button if can go back
  if @nav.can_go_back?
    toolbar.navigation_icon = R.drawable.back
    toolbar.on_navigation_click { go_back }
  end

  toolbar.setupWithActivity
  toolbar
end
```

---

## Bottom Tab Navigation

A common pattern for main sections.

```crystal
class TabNavigation
  property tabs = [] of Tab
  property selected_index = 0
  @on_change : (Int32 -> Nil)?

  struct Tab
    property id : Symbol
    property title : String
    property icon : Int32
    property builder : -> Native::UI::View

    def initialize(@id, @title, @icon, @builder)
    end
  end

  def add_tab(id : Symbol, title : String, icon : Int32, &builder : -> Native::UI::View)
    @tabs << Tab.new(id, title, icon, builder)
  end

  def select(index : Int32)
    @selected_index = index
    @on_change.try &.call(index)
  end

  def on_tab_change(&callback : Int32 -> Nil)
    @on_change = callback
  end

  def current_view : Native::UI::View
    @tabs[@selected_index].builder.call
  end
end
```

Building the UI:

```crystal
class MyApp < Native::App
  def setup
    @tabs = TabNavigation.new
    @tabs.add_tab(:home, "Home", R.drawable.home) { build_home }
    @tabs.add_tab(:search, "Search", R.drawable.search) { build_search }
    @tabs.add_tab(:profile, "Profile", R.drawable.person) { build_profile }

    @tabs.on_tab_change { replace_content }
    @root = build_main_ui
  end

  def build_main_ui
    container = Native::UI::LinearLayout.new
    container.orientation = Native::UI::LinearLayout::Orientation::Vertical

    # Content area
    @content = Native::UI::FrameLayout.new
    @content.layout_weight = 1.0
    @content.addView(@tabs.current_view)
    container.addView(@content)

    # Tab bar
    container.addView(build_tab_bar)

    container
  end

  def build_tab_bar
    bar = Native::UI::LinearLayout.new
    bar.orientation = Native::UI::LinearLayout::Orientation::Horizontal
    bar.background_color = 0xFFFFFFFF
    bar.elevation = 8

    @tabs.tabs.each_with_index do |tab, index|
      btn = build_tab_button(tab, index)
      btn.layout_weight = 1.0
      bar.addView(btn)
    end

    bar
  end

  def build_tab_button(tab : TabNavigation::Tab, index : Int32)
    btn = Native::UI::LinearLayout.new
    btn.orientation = Native::UI::LinearLayout::Orientation::Vertical
    btn.padding = 8
    btn.gravity = Native::UI::Gravity::CENTER

    icon = Native::UI::ImageView.new
    icon.load_resource(tab.icon)
    icon.tint = @tabs.selected_index == index ? PRIMARY : GRAY
    btn.addView(icon)

    label = Native::UI::TextView.new(tab.title)
    label.text_size = 12.0
    label.text_color = @tabs.selected_index == index ? PRIMARY : GRAY
    btn.addView(label)

    btn.on_click { @tabs.select(index) }
    btn
  end

  def replace_content
    @content.clear
    @content.addView(@tabs.current_view)
  end
end
```

---

## Modal Screens

Display temporary screens that don't affect navigation stack.

### Alert Dialog

```crystal
def show_confirm_dialog(title : String, message : String, on_confirm : -> Nil)
  dialog = Native::Dialog::AlertDialog.new
  dialog.title = title
  dialog.message = message
  dialog.positive_button = "Confirm"
  dialog.negative_button = "Cancel"
  dialog.on_positive { on_confirm.call }
  dialog.show
end
```

### Custom Modal

```crystal
def show_modal(content : Native::UI::View)
  @modal_overlay = Native::UI::View.new
  @modal_overlay.background_color = 0x80000000  # Semi-transparent black
  @modal_overlay.on_click { dismiss_modal }
  @modal_overlay.width = Native::UI::Layout::MatchParent
  @modal_overlay.height = Native::UI::Layout::MatchParent

  # Center container
  center = Native::UI::FrameLayout.new
  center.gravity = Native::UI::Gravity::CENTER
  center.addView(content)

  @modal_overlay.addView(center)
  @root.addView(@modal_overlay)
end

def dismiss_modal
  @root.remove_view(@modal_overlay) if @modal_overlay
  @modal_overlay = nil
end
```

---

## Drawer Navigation

Side menu for navigation.

```crystal
def build_drawer_ui
  # Main container
  @drawer = Native::UI::LinearLayout.new
  @drawer.orientation = Native::UI::LinearLayout::Orientation::Horizontal
  @drawer.width = Native::UI::Layout::MatchParent
  @drawer.height = Native::UI::Layout::MatchParent

  # Sidebar (initially hidden off-screen)
  @sidebar = build_sidebar
  @sidebar.translation_x = -@sidebar_width.to_f32
  @drawer.addView(@sidebar)

  # Main content
  @main_content = Native::UI::LinearLayout.new
  @main_content.orientation = Native::UI::LinearLayout::Orientation::Vertical
  @main_content.addView(build_toolbar_with_menu)
  @main_content.addView(@content_area)
  @drawer.addView(@main_content)

  @drawer
end

def toggle_drawer
  if @drawer_open
    close_drawer
  else
    open_drawer
  end
end

def open_drawer
  animate = Native::Animation::ObjectAnimator.new(@sidebar, "translation_x", -@sidebar_width.to_f32, 0.0)
  animate.duration = 250
  animate.start
  @drawer_open = true
end

def close_drawer
  animate = Native::Animation::ObjectAnimator.new(@sidebar, "translation_x", 0.0, -@sidebar_width.to_f32)
  animate.duration = 250
  animate.start
  @drawer_open = false
end
```

---

## Passing Data Between Screens

Store data in your app class or use a dedicated state container:

```crystal
class MyApp < Native::App
  @[Preserve]
  property selected_item_id : String?

  def open_detail(item_id : String)
    @selected_item_id = item_id
    @nav.push(:detail)
  end

  def build_detail
    item = find_item(@selected_item_id)
    # Build detail UI with item data
  end
end
```

---

## Back Button Handling

Android has a hardware back button. Handle it:

```crystal
class MyApp < Native::App
  def on_back_pressed : Bool
    if @modal_open
      dismiss_modal
      return true  # Consumed
    end

    if @nav.can_go_back?
      go_back
      return true
    end

    false  # Let system handle (exit app)
  end
end
```

---

## Navigation Patterns Summary

| Pattern | Use Case |
|---------|----------|
| Screen Stack | Linear flows (wizard, onboarding) |
| Tab Navigation | Main app sections |
| Drawer | Settings, account, overflow |
| Modal | Confirmations, quick actions |
| Replace | Same-level screen switching |

---

## Next Steps

- [State Management](state-management.md) — Sharing data across screens
- [Animations](animations.md) — Screen transitions
- [Tutorial: Multi-Screen App](tutorial-navigation.md) — Full navigation example
