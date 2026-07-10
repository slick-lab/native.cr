require "../src/native"

class CounterApp < Native::App
  @count : Int32 = 0
  @label : Native::UI::TextView
  @button : Native::UI::Button
  @reset_btn : Native::UI::Button
  @layout : Native::UI::LinearLayout
  @prefs : Native::Storage::Preferences

  def initialize
    super
    @label = Native::UI::TextView.new("Tap count: 0")
    @button = Native::UI::Button.new("Tap Me")
    @reset_btn = Native::UI::Button.new("Reset")
    @layout = Native::UI::LinearLayout.new
    @prefs = Native::Storage::Preferences.new("counter_app")
  end

  def setup : Nil
    @count = @prefs.get_int("count", 0)

    @label.text = "Tap count: #{@count}"
    @label.text_size = 24

    @button.text_size = 18
    @button.on_click { increment }

    @reset_btn.text_size = 16
    @reset_btn.on_click { reset }

    @layout.orientation = Native::UI::LinearLayout::Orientation::Vertical
    @layout.addView(@label)
    @layout.addView(@button)
    @layout.addView(@reset_btn)
  end

  private def increment : Nil
    @count += 1
    @label.text = "Tap count: #{@count}"
    @prefs.set("count", @count)

    color = @count % 2 == 0 ? Native::Math::Color.blue : Native::Math::Color.red
    @button.text_color = color
  end

  private def reset : Nil
    @count = 0
    @label.text = "Tap count: 0"
    @prefs.set("count", 0)
    @button.text_color = Native::Math::Color.white
  end
end

Native::App.registered_subclass = CounterApp
