require "native"

class BasicApp < Native::App
  @[Preserve]
  property count : Int32 = 0

  @label : UI::TextView?
  @counter : UI::TextView?

  def setup : Nil
    set_background_color(240, 240, 245)

    @label = UI::TextView.new
    @label.not_nil!.text = "Hello, native.cr!"
    @label.not_nil!.text_size = 28
    @label.not_nil!.color = Color.from_hex(0x333333)

    @counter = UI::TextView.new
    @counter.not_nil!.text = "Tap count: 0"
    @counter.not_nil!.text_size = 18
    @counter.not_nil!.color = Color.from_hex(0x666666)

    button = UI::Button.new
    button.text = "Tap Me"
    button.width = 160
    button.height = 48
    button.background_color = Color.from_hex(0x007AFF)
    button.text_color = Color.white
    button.corner_radius = CornerRadius.all(24)
    button.on_click = -> { increment }

    column = UI::Column.new
    column.spacing = 24
    column.alignment = Alignment::Center
    column.add_child(@label.not_nil!)
    column.add_child(@counter.not_nil!)
    column.add_child(button)

    @root = column
  end

  def increment
    @count += 1
    @counter.not_nil!.text = "Tap count: #{@count}"

    if @count % 5 == 0
      set_background_color(200, 100, 100)
      Native::Platform::HapticFeedback.light
    else
      set_background_color(240, 240, 245)
    end
  end
end

Native::App.registered_subclass = BasicApp
