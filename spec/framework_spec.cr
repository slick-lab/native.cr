# spec/framework_spec.cr

require "./spec_helper"

# ============================================================================
# Styling Tests
# ============================================================================

describe Native::Styling::Color do
  it "creates color with RGB values" do
    color = Native::Styling::Color.new(255, 128, 64)
    color.r.should eq(255)
    color.g.should eq(128)
    color.b.should eq(64)
    color.a.should eq(255)
  end

  it "creates color with RGBA values" do
    color = Native::Styling::Color.new(255, 128, 64, 128)
    color.a.should eq(128)
  end

  it "returns black" do
    color = Native::Styling::Color.black
    color.r.should eq(0)
    color.g.should eq(0)
    color.b.should eq(0)
  end

  it "returns white" do
    color = Native::Styling::Color.white
    color.r.should eq(255)
    color.g.should eq(255)
    color.b.should eq(255)
  end

  it "returns red" do
    color = Native::Styling::Color.red
    color.r.should eq(255)
    color.g.should eq(0)
    color.b.should eq(0)
  end

  it "returns green" do
    color = Native::Styling::Color.green
    color.r.should eq(0)
    color.g.should eq(255)
    color.b.should eq(0)
  end

  it "returns blue" do
    color = Native::Styling::Color.blue
    color.r.should eq(0)
    color.g.should eq(0)
    color.b.should eq(255)
  end

  it "creates gray color" do
    color = Native::Styling::Color.gray(128)
    color.r.should eq(128)
    color.g.should eq(128)
    color.b.should eq(128)
  end

  it "creates color from RGB" do
    color = Native::Styling::Color.rgb(100, 150, 200)
    color.r.should eq(100)
    color.g.should eq(150)
    color.b.should eq(200)
  end

  it "creates color from RGBA" do
    color = Native::Styling::Color.rgba(100, 150, 200, 128)
    color.a.should eq(128)
  end

  it "converts hex to color" do
    color = Native::Styling::Color.hex(0xFF3366)
    color.r.should eq(255)
    color.g.should eq(51)
    color.b.should eq(102)
  end

  pending "converts hex with alpha to color" do
    color = Native::Styling::Color.hex(0xFF336680)
    color.a.should eq(128)
  end

  pending "converts color to hex" do
    color = Native::Styling::Color.new(255, 51, 102)
    color.to_hex.should eq(0xFF3366FF)
  end

  it "creates color with new alpha" do
    color = Native::Styling::Color.red.with_alpha(128)
    color.a.should eq(128)
    color.r.should eq(255)
  end

  it "lightens color" do
    color = Native::Styling::Color.gray(100).lighten(50)
    color.r.should eq(150)
  end

  it "darkens color" do
    color = Native::Styling::Color.gray(100).darken(50)
    color.r.should eq(50)
  end
end

describe Native::Styling::EdgeInsets do
  it "creates insets with all values" do
    insets = Native::Styling::EdgeInsets.new(10, 20, 30, 40)
    insets.top.should eq(10)
    insets.left.should eq(20)
    insets.bottom.should eq(30)
    insets.right.should eq(40)
  end

  it "creates insets with same value on all sides" do
    insets = Native::Styling::EdgeInsets.all(15)
    insets.top.should eq(15)
    insets.left.should eq(15)
    insets.bottom.should eq(15)
    insets.right.should eq(15)
  end

  it "creates horizontal insets" do
    insets = Native::Styling::EdgeInsets.horizontal(20)
    insets.left.should eq(20)
    insets.right.should eq(20)
  end

  it "creates vertical insets" do
    insets = Native::Styling::EdgeInsets.vertical(20)
    insets.top.should eq(20)
    insets.bottom.should eq(20)
  end
end

describe Native::Styling::CornerRadius do
  it "creates radius with all values" do
    radius = Native::Styling::CornerRadius.new(5, 10, 15, 20)
    radius.top_left.should eq(5)
    radius.top_right.should eq(10)
    radius.bottom_left.should eq(15)
    radius.bottom_right.should eq(20)
  end

  it "creates radius with same value on all corners" do
    radius = Native::Styling::CornerRadius.all(8)
    radius.top_left.should eq(8)
    radius.top_right.should eq(8)
    radius.bottom_left.should eq(8)
    radius.bottom_right.should eq(8)
  end
end

describe Native::Styling::Font do
  it "creates font with defaults" do
    font = Native::Styling::Font.new
    font.name.should eq("System")
    font.size.should eq(16)
    font.weight.should eq(Native::Styling::FontWeight::Normal)
  end

  it "creates system font" do
    font = Native::Styling::Font.system(24)
    font.size.should eq(24)
  end

  it "creates bold font" do
    font = Native::Styling::Font.bold(24)
    font.weight.should eq(Native::Styling::FontWeight::Bold)
  end
end

describe Native::Styling::Theme do
  it "has default primary color" do
    Native::Styling::Theme.primary_color.should eq(Native::Styling::Color.blue)
  end

  it "has default spacing" do
    Native::Styling::Theme.spacing.should eq(16)
  end
end

# ============================================================================
# Storage Tests
# ============================================================================

pending "Native::Storage::Preferences" do
  it "sets and gets string" do
    skip "Requires Android/iOS backend"
  end

  it "sets and gets integer" do
    skip "Requires Android/iOS backend"
  end

  it "sets and gets boolean" do
    skip "Requires Android/iOS backend"
  end

  it "returns default when key not found" do
    skip "Requires Android/iOS backend"
  end
end

# ============================================================================
# Platform Tests
# ============================================================================

pending "Native::Platform::Device" do
  it "returns device info" do
    skip "Requires device"
  end
end

# ============================================================================
# Dialog Tests
# ============================================================================

describe Native::Dialog::AlertConfig do
  it "creates config with defaults" do
    config = Native::Dialog::AlertConfig.new
    config.title.should eq("")
    config.message.should eq("")
    config.cancelable.should be_true
  end
end

describe Native::Dialog::DialogButton do
  it "creates button with title and action" do
    callback_called = false
    button = Native::Dialog::DialogButton.new("OK", Native::Dialog::DialogAction::Positive)
    button.callback = -> { callback_called = true; nil }
    button.title.should eq("OK")
    button.action.should eq(Native::Dialog::DialogAction::Positive)
    button.callback.call
    callback_called.should be_true
  end
end

# ============================================================================
# GameLoop Tests
# ============================================================================

describe Native::GameLoop::LoopConfig do
  it "has default values" do
    config = Native::GameLoop::LoopConfig.new
    config.mode.should eq(Native::GameLoop::LoopMode::Adaptive)
    config.target_fps.should eq(60)
  end
end

# ============================================================================
# TextInput Tests
# ============================================================================

describe Native::Text::TextInputConfig do
  it "creates config with defaults" do
    config = Native::Text::TextInputConfig.new
    config.placeholder.should eq("")
    config.max_length.should eq(0)
    config.keyboard_type.should eq(Native::Text::KeyboardType::Default)
    config.secure.should be_false
  end
end

describe Native::Text::TextUtils do
  it "validates email" do
    Native::Text::TextUtils.validate_email("test@example.com").should be_true
    Native::Text::TextUtils.validate_email("invalid").should be_false
  end

  it "validates phone" do
    Native::Text::TextUtils.validate_phone("1234567890").should be_true
  end

  it "truncates text" do
    Native::Text::TextUtils.truncate("hello world", 5).should eq("hello...")
  end
end
