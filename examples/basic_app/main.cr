require "native"

class BasicApp < Native::App
  @[Preserve]
  property count : Int32 = 0

  def setup
    set_background_color(240, 240, 245)

    @label = UI::Text.new
    @label.text = "Hello, native.cr!"
    @label.text_size = 28
    @label.color = Color.from_hex(0x333333)

    @counter = UI::Text.new
    @counter.text = "Tap count: 0"
    @counter.text_size = 18
    @counter.color = Color.from_hex(0x666666)

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
    column.add_child(@label)
    column.add_child(@counter)
    column.add_child(button)

    @root = column
  end

  def increment
    @count += 1
    @counter.text = "Tap count: #{@count}"

    if @count % 5 == 0
      set_background_color(200, 100, 100)
      Native::Platform::HapticFeedback.light
    else
      set_background_color(240, 240, 245)
    end
  end

  def draw
    @root.draw(renderer)
  end
end

Native::App.start(BasicApp)
