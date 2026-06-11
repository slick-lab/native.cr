# spec/framework_core_spec.cr

require "./spec_helper"

# Define test classes at the top level
class TestApp < Native::App
  property value : Int32 = 0

  def setup : Nil
  end

  def state_to_json : String
    {value: @value}.to_json
  end

  def state_from_json(json : String) : Nil
    data = JSON.parse(json)
    @value = data["value"]?.try &.as_i || 0
  end
end

class TestView < Native::UI::View
end

describe Native::App do
  it "can save and load state" do
    app = TestApp.new
    app.value = 42
    json = app.state_to_json
    json.should contain("42")

    app2 = TestApp.new
    app2.state_from_json(json)
    app2.value.should eq(42)
  end
end

describe Native::UI::View do
  it "has position properties" do
    view = Native::UI::View.new
    view.x = 10
    view.y = 20
    view.x.should eq(10)
    view.y.should eq(20)
  end

  it "has size properties" do
    view = Native::UI::View.new
    view.width = 100
    view.height = 200
    view.width.should eq(100)
    view.height.should eq(200)
  end

  it "can add and remove children" do
    parent = Native::UI::View.new
    child = Native::UI::View.new
    parent.add_child(child)
    parent.children.size.should eq(1)
    parent.remove_child(child)
    parent.children.size.should eq(0)
  end

  it "calculates absolute position" do
    parent = Native::UI::View.new
    parent.x = 10
    parent.y = 20
    child = Native::UI::View.new
    child.x = 5
    child.y = 7
    parent.add_child(child)
    child.absolute_x.should eq(15)
    child.absolute_y.should eq(27)
  end

  it "detects hit test" do
    view = Native::UI::View.new
    view.x = 10
    view.y = 10
    view.width = 100
    view.height = 100
    view.hit_test(50, 50).should be_true
    view.hit_test(200, 200).should be_false
  end
end

describe Native::UI::TextView do
  it "sets and gets text" do
    text_view = Native::UI::TextView.new
    text_view.text = "Hello"
    text_view.text.should eq("Hello")
  end

  it "sets text size" do
    text_view = Native::UI::TextView.new
    text_view.text_size = 24
    text_view.text_size.should eq(24)
  end
end

describe Native::UI::Button do
  it "sets text" do
    button = Native::UI::Button.new
    button.text = "Click Me"
    button.text.should eq("Click Me")
  end

  it "has click callback" do
    clicked = false
    button = Native::UI::Button.new
    button.on_click { clicked = true }
    button.handleClick
    clicked.should be_true
  end
end

describe Native::UI::LinearLayout do
  it "sets orientation" do
    layout = Native::UI::LinearLayout.new(Native::UI::LinearLayout::Orientation::Vertical)
    layout.orientation.should eq(Native::UI::LinearLayout::Orientation::Vertical)
  end

  it "can add views" do
    layout = Native::UI::LinearLayout.new
    view = Native::UI::View.new
    layout.addView(view)
    layout.childCount.should eq(1)
  end
end

describe Native::UI::ScrollView do
  it "creates scroll view" do
    scroll = Native::UI::ScrollView.new(Native::UI::ScrollView::ScrollDirection::Vertical)
    scroll.should be_a(Native::UI::View)
  end

  it "scrolls to position" do
    scroll = Native::UI::ScrollView.new
    scroll.scroll_to(0, 100, false)
    scroll.scroll_y.should eq(100)
  end
end

describe Native::Storage::Preferences do
  it "sets and gets string" do
    prefs = Native::Storage::Preferences.new
    prefs.set("test", "value")
    prefs.get_string("test").should eq("value")
  end

  it "returns default when key missing" do
    prefs = Native::Storage::Preferences.new
    prefs.get_string("missing", "default").should eq("default")
  end

  it "deletes key" do
    prefs = Native::Storage::Preferences.new
    prefs.set("to_delete", "value")
    prefs.delete("to_delete")
    prefs.contains?("to_delete").should be_false
  end
end

describe Native::Network::Request do
  it "adds headers" do
    request = Native::Network::Request.new
    request.add_header("Authorization", "Bearer token")
    request.headers["Authorization"].should eq("Bearer token")
  end

  it "sets JSON body" do
    request = Native::Network::Request.new
    request.json = %({"name":"test"})
    request.headers["Content-Type"].should eq("application/json")
    request.body.should eq(%({"name":"test"}))
  end
end

describe Native::Math::Vector2 do
  it "adds vectors" do
    v1 = Native::Math::Vector2.new(1, 2)
    v2 = Native::Math::Vector2.new(3, 4)
    result = v1 + v2
    result.x.should eq(4)
    result.y.should eq(6)
  end

  it "subtracts vectors" do
    v1 = Native::Math::Vector2.new(5, 6)
    v2 = Native::Math::Vector2.new(3, 4)
    result = v1 - v2
    result.x.should eq(2)
    result.y.should eq(2)
  end

  it "multiplies by scalar" do
    v = Native::Math::Vector2.new(2, 3)
    result = v * 4
    result.x.should eq(8)
    result.y.should eq(12)
  end

  it "computes magnitude" do
    v = Native::Math::Vector2.new(3, 4)
    v.magnitude.should eq(5)
  end

  it "computes dot product" do
    v1 = Native::Math::Vector2.new(1, 2)
    v2 = Native::Math::Vector2.new(3, 4)
    v1.dot(v2).should eq(11)
  end

  it "normalizes vector" do
    v = Native::Math::Vector2.new(3, 4)
    normalized = v.normalize
    normalized.magnitude.should be_close(1.0, 0.0001)
  end
end

describe Native::Math::Color do
  it "creates color from RGB" do
    color = Native::Math::Color.from_rgba(255, 0, 0)
    color.r.should eq(1.0)
    color.g.should eq(0.0)
    color.b.should eq(0.0)
  end

  it "creates color from hex" do
    color = Native::Math::Color.from_hex(0xFF0000)
    color.r.should eq(1.0)
    color.g.should eq(0.0)
    color.b.should eq(0.0)
  end

  it "creates white color" do
    color = Native::Math::Color.white
    color.r.should eq(1.0)
    color.g.should eq(1.0)
    color.b.should eq(1.0)
  end

  it "creates black color" do
    color = Native::Math::Color.black
    color.r.should eq(0.0)
    color.g.should eq(0.0)
    color.b.should eq(0.0)
  end

  it "creates gray color" do
    color = Native::Math::Color.gray(128)
    color.r.should be_close(0.502, 0.001)
    color.g.should be_close(0.502, 0.001)
    color.b.should be_close(0.502, 0.001)
  end

  it "interpolates between colors" do
    c1 = Native::Math::Color.new(1.0, 0.0, 0.0)
    c2 = Native::Math::Color.new(0.0, 0.0, 1.0)
    result = c1.lerp(c2, 0.5)
    result.r.should eq(0.5)
    result.b.should eq(0.5)
  end

  it "lightens color" do
    color = Native::Math::Color.new(0.5, 0.5, 0.5)
    lighter = color.lighten(0.3)
    lighter.r.should eq(0.8)
  end

  it "darkens color" do
    color = Native::Math::Color.new(0.5, 0.5, 0.5)
    darker = color.darken(0.3)
    darker.r.should eq(0.2)
  end
end

describe Native::Platform do
  it "detects platform type" do
    Native::Platform.android?.should be_a(Bool)
    Native::Platform.ios?.should be_a(Bool)
    Native::Platform.desktop?.should be_a(Bool)
  end

  it "returns OS name" do
    name = Native::Platform.os_name
    name.should be_a(String)
    ["Android", "iOS", "Desktop"].should contain(name)
  end
end

describe Native::Clipboard do
  it "has clipboard manager" do
    manager = Native::Clipboard::ClipboardManager.instance
    manager.should be_a(Native::Clipboard::ClipboardManager)
  end

  it "checks if clipboard has text" do
    Native::Clipboard.has_text?.should be_a(Bool)
  end
end
