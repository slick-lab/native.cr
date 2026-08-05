require "../src/native"

# ─── Screen definitions ────────────────────────────────────────────────────────

class HomeScreen < Native::Navigation::Screen
  def initialize(@nav_ref : Native::Navigation::Navigator)
  end

  def build : Native::UI::View
    layout = Native::UI::LinearLayout.new(Native::UI::LinearLayout::Orientation::Vertical)
    layout.gravity = Native::UI::LinearLayout::Gravity::Center

    title = Native::UI::TextView.new("Welcome")
    title.text_size = 32
    title.color = Native::Math::Color.from_rgb(0.1, 0.1, 0.15)
    title.center

    subtitle = Native::UI::TextView.new("Select a page to navigate to")
    subtitle.text_size = 16
    subtitle.color = Native::Math::Color.from_rgb(0.4, 0.4, 0.4)
    subtitle.center

    btn_detail = Native::UI::Button.new("Go to Detail")
    btn_detail.width = 240
    btn_detail.height = 52
    btn_detail.on_click { @nav_ref.push(DetailScreen.new("Hello from Detail!", @nav_ref)) }

    btn_settings = Native::UI::Button.new("Go to Settings")
    btn_settings.width = 240
    btn_settings.height = 52
    btn_settings.on_click { @nav_ref.push(SettingsScreen.new(@nav_ref)) }

    layout.addView(title)
    layout.addView(subtitle)
    layout.addView(btn_detail)
    layout.addView(btn_settings)
    layout
  end
end

class DetailScreen < Native::Navigation::Screen
  def initialize(@message : String, @nav_ref : Native::Navigation::Navigator)
  end

  def build : Native::UI::View
    layout = Native::UI::LinearLayout.new(Native::UI::LinearLayout::Orientation::Vertical)
    layout.gravity = Native::UI::LinearLayout::Gravity::Center

    label = Native::UI::TextView.new("Detail Screen")
    label.text_size = 28
    label.color = Native::Math::Color.from_rgb(0.1, 0.1, 0.15)
    label.center

    msg = Native::UI::TextView.new(@message)
    msg.text_size = 16
    msg.color = Native::Math::Color.from_rgb(0.3, 0.3, 0.5)
    msg.center

    btn_back = Native::UI::Button.new("← Back")
    btn_back.width = 160
    btn_back.height = 48
    btn_back.on_click { @nav_ref.pop }

    layout.addView(label)
    layout.addView(msg)
    layout.addView(btn_back)
    layout
  end
end

class SettingsScreen < Native::Navigation::Screen
  def initialize(@nav_ref : Native::Navigation::Navigator)
  end

  def build : Native::UI::View
    layout = Native::UI::LinearLayout.new(Native::UI::LinearLayout::Orientation::Vertical)
    layout.gravity = Native::UI::LinearLayout::Gravity::Center

    label = Native::UI::TextView.new("Settings")
    label.text_size = 28
    label.color = Native::Math::Color.from_rgb(0.1, 0.1, 0.15)
    label.center

    btn_root = Native::UI::Button.new("Go to Root")
    btn_root.width = 200
    btn_root.height = 48
    btn_root.on_click { @nav_ref.pop_to_root }

    btn_back = Native::UI::Button.new("← Back")
    btn_back.width = 160
    btn_back.height = 48
    btn_back.on_click { @nav_ref.pop }

    layout.addView(label)
    layout.addView(btn_root)
    layout.addView(btn_back)
    layout
  end
end

# ─── App ───────────────────────────────────────────────────────────────────────

class ScreensApp < Native::App
  @navigator : Native::Navigation::Navigator? = nil

  def setup
    nav = Native::Navigation::Navigator.new(self)
    @navigator = nav
    nav.push(HomeScreen.new(nav))
  end

  # Route the hardware back button through the navigator
  def on_key_pressed(key : Int32) : Nil
    if key == 4 # KEYCODE_BACK on Android
      @navigator.try(&.back)
    end
  end
end

Native::App.registered_subclass = ScreensApp
