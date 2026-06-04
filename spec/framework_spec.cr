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

  it "converts hex with alpha to color" do
    color = Native::Styling::Color.hex(0xFF336680)
    color.a.should eq(128)
  end

  it "converts color to hex" do
    color = Native::Styling::Color.new(255, 51, 102)
    color.to_hex.should eq(0xFF3366FF)
  end

  it "creates color with new alpha" do
    color = Native::Styling::Color.red.with_alpha(128)
    color.a.should eq(128)
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
    insets.top.should eq(0)
    insets.bottom.should eq(0)
  end

  it "creates vertical insets" do
    insets = Native::Styling::EdgeInsets.vertical(20)
    insets.top.should eq(20)
    insets.bottom.should eq(20)
    insets.left.should eq(0)
    insets.right.should eq(0)
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

  it "allows changing primary color" do
    original = Native::Styling::Theme.primary_color
    Native::Styling::Theme.primary_color = Native::Styling::Color.red
    Native::Styling::Theme.primary_color.should eq(Native::Styling::Color.red)
    Native::Styling::Theme.primary_color = original
  end

  it "has default spacing" do
    Native::Styling::Theme.spacing.should eq(16)
  end
end

# ============================================================================
# Events Tests
# ============================================================================

describe Native::Events::Touch do
  it "creates touch with defaults" do
    touch = Native::Events::Touch.new
    touch.id.should eq(0)
    touch.x.should eq(0.0)
    touch.y.should eq(0.0)
  end

  it "creates touch with custom values" do
    touch = Native::Events::Touch.new(1, 100.0, 200.0, 0.5)
    touch.id.should eq(1)
    touch.x.should eq(100.0)
    touch.y.should eq(200.0)
    touch.pressure.should eq(0.5)
  end
end

describe Native::Events::KeyEvent do
  it "creates key event with defaults" do
    event = Native::Events::KeyEvent.new
    event.key_code.should eq(Native::Events::KeyCode::Unknown)
    event.action.should eq(Native::Events::TouchAction::Began)
  end

  it "detects press" do
    event = Native::Events::KeyEvent.new(action: Native::Events::TouchAction::Began)
    event.is_pressed?.should be_true
  end

  it "detects release" do
    event = Native::Events::KeyEvent.new(action: Native::Events::TouchAction::Ended)
    event.is_released?.should be_true
  end
end

# ============================================================================
# Animation Tests
# ============================================================================

describe Native::Animation::ValueAnimator do
  it "animates value between start and end" do
    values = [] of Float64
    animator = Native::Animation::ValueAnimator.new(0.0, 100.0)
    animator.on_update { |v| values << v }
    animator.start

    # Force immediate completion
    animator.update(Time.utc.to_unix_f + 1.0)

    values.size.should be > 0
    values.last.should eq(100.0)
  end
end

# ============================================================================
# Image Tests
# ============================================================================

describe Native::Image::ImageData do
  it "creates empty image" do
    img = Native::Image::ImageData.new(100, 100)
    img.width.should eq(100)
    img.height.should eq(100)
    img.channels.should eq(4)
  end

  it "sets and gets pixel" do
    img = Native::Image::ImageData.new(10, 10)
    img.set_pixel(5, 5, 255, 0, 0, 255)
    r, g, b, a = img.pixel(5, 5)
    r.should eq(255)
    g.should eq(0)
    b.should eq(0)
    a.should eq(255)
  end

  it "fills image with color" do
    img = Native::Image::ImageData.new(10, 10)
    img.fill(128, 128, 128, 255)
    r, g, b, a = img.pixel(5, 5)
    r.should eq(128)
    g.should eq(128)
    b.should eq(128)
  end

  it "resizes image" do
    img = Native::Image::ImageData.new(10, 10)
    img.fill(255, 0, 0, 255)
    resized = img.resize(20, 20)
    resized.width.should eq(20)
    resized.height.should eq(20)
  end

  it "crops image" do
    img = Native::Image::ImageData.new(10, 10)
    cropped = img.crop(2, 2, 5, 5)
    cropped.width.should eq(5)
    cropped.height.should eq(5)
  end
end

# ============================================================================
# Storage Tests
# ============================================================================

describe Native::Storage::Preferences do
  it "sets and gets string" do
    prefs = Native::Storage::Preferences.new
    prefs.set("test_key", "test_value")
    prefs.get_string("test_key").should eq("test_value")
  end

  it "sets and gets integer" do
    prefs = Native::Storage::Preferences.new
    prefs.set("test_int", 123)
    prefs.get_int("test_int").should eq(123)
  end

  it "sets and gets boolean" do
    prefs = Native::Storage::Preferences.new
    prefs.set("test_bool", true)
    prefs.get_bool("test_bool").should be_true
  end

  it "returns default when key not found" do
    prefs = Native::Storage::Preferences.new
    prefs.get_string("missing", "default").should eq("default")
  end

  it "deletes key" do
    prefs = Native::Storage::Preferences.new
    prefs.set("to_delete", "value")
    prefs.delete("to_delete")
    prefs.get_string("to_delete").should eq("")
  end
end

# ============================================================================
# Platform Tests
# ============================================================================

describe Native::Platform::Device do
  it "returns device info" do
    info = Native::Platform::Device.info
    info.model.should be_a(String)
    info.os_version.should be_a(String)
    info.screen_width.should be > 0
    info.screen_height.should be > 0
  end

  it "detects orientation" do
    orientation = Native::Platform::Device.orientation
    [Native::Platform::Orientation::Portrait, Native::Platform::Orientation::LandscapeLeft,
     Native::Platform::Orientation::LandscapeRight].should contain(orientation)
  end
end

describe Native::Platform::Battery do
  it "returns battery info" do
    info = Native::Platform::Battery.info
    info.level.should be >= 0
    info.level.should be <= 100
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

  it "sets title and message" do
    config = Native::Dialog::AlertConfig.new
    config.title = "Test Title"
    config.message = "Test Message"
    config.title.should eq("Test Title")
    config.message.should eq("Test Message")
  end
end

describe Native::Dialog::DialogButton do
  it "creates button with title and action" do
    callback_called = false
    button = Native::Dialog::DialogButton.new("OK", Native::Dialog::DialogAction::Positive)
    button.callback = ->{ callback_called = true; nil }
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
    config.fixed_update_rate.should eq(1.0 / 60.0)
  end

  it "allows custom configuration" do
    config = Native::GameLoop::LoopConfig.new
    config.mode = Native::GameLoop::LoopMode::Fixed
    config.target_fps = 30
    config.mode.should eq(Native::GameLoop::LoopMode::Fixed)
    config.target_fps.should eq(30)
  end
end

describe Native::GameLoop::GameLoop do
  it "creates game loop with default config" do
    loop = Native::GameLoop::GameLoop.new
    loop.is_running?.should be_false
  end

  it "starts and stops" do
    loop = Native::GameLoop::GameLoop.new
    loop.start
    sleep 0.1
    loop.is_running?.should be_true
    loop.stop
    loop.is_running?.should be_false
  end

  it "triggers on_start callback" do
    started = false
    loop = Native::GameLoop::GameLoop.new
    loop.on_start { started = true }
    loop.start
    sleep 0.1
    started.should be_true
    loop.stop
  end

  it "triggers on_update callback" do
    updated = false
    loop = Native::GameLoop::GameLoop.new
    loop.on_update { |delta| updated = true }
    loop.start
    sleep 0.1
    updated.should be_true
    loop.stop
  end

  it "returns FPS after running" do
    loop = Native::GameLoop::GameLoop.new
    loop.start
    sleep 0.5
    loop.fps.should be > 0
    loop.stop
  end

  it "pauses and resumes" do
    updated = 0
    loop = Native::GameLoop::GameLoop.new
    loop.on_update { |delta| updated += 1 }
    loop.start
    sleep 0.1
    loop.pause
    count_after_pause = updated
    sleep 0.1
    updated.should eq(count_after_pause)
    loop.resume
    sleep 0.1
    updated.should be > count_after_pause
    loop.stop
  end
end

describe Native::GameLoop::FixedGameLoop do
  it "creates fixed timestep loop" do
    loop = Native::GameLoop::FixedGameLoop.new(60)
    loop.target_fps = 60
    loop.start
    sleep 0.1
    loop.is_running?.should be_true
    loop.stop
  end
end

describe Native::GameLoop::VariableGameLoop do
  it "creates variable timestep loop" do
    loop = Native::GameLoop::VariableGameLoop.new(60)
    loop.start
    sleep 0.1
    loop.is_running?.should be_true
    loop.stop
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
    config.multiline.should be_false
  end

  it "configures keyboard type" do
    config = Native::Text::TextInputConfig.new
    config.keyboard_type = Native::Text::KeyboardType::Email
    config.keyboard_type.should eq(Native::Text::KeyboardType::Email)
  end

  it "configures return key" do
    config = Native::Text::TextInputConfig.new
    config.return_key_type = Native::Text::ReturnKeyType::Search
    config.return_key_type.should eq(Native::Text::ReturnKeyType::Search)
  end

  it "enables secure mode" do
    config = Native::Text::TextInputConfig.new
    config.secure = true
    config.secure.should be_true
  end

  it "enables multiline" do
    config = Native::Text::TextInputConfig.new
    config.multiline = true
    config.multiline.should be_true
  end
end

describe Native::Text::SecureTextInput do
  it "creates secure text input" do
    input = Native::Text::SecureTextInput.new
    input.should be_a(Native::Text::TextInput)
  end
end

describe Native::Text::MultilineTextInput do
  it "creates multiline text input" do
    input = Native::Text::MultilineTextInput.new
    input.should be_a(Native::Text::TextInput)
  end
end

describe Native::Text::TextUtils do
  it "validates email" do
    Native::Text::TextUtils.validate_email("test@example.com").should be_true
    Native::Text::TextUtils.validate_email("invalid").should be_false
  end

  it "validates phone" do
    Native::Text::TextUtils.validate_phone("1234567890").should be_true
    Native::Text::TextUtils.validate_phone("123").should be_false
  end

  it "validates password strength" do
    Native::Text::TextUtils.validate_password_strength("weak").should be < 5
    Native::Text::TextUtils.validate_password_strength("Str0ng!Pass").should eq(5)
  end

  it "truncates text" do
    Native::Text::TextUtils.truncate("hello world", 5).should eq("hello...")
  end

  it "capitalizes words" do
    Native::Text::TextUtils.capitalize_words("hello world").should eq("Hello World")
  end
end

# ============================================================================
# Scroll Tests
# ============================================================================

describe Native::Scroll::ScrollConfig do
  it "creates config with defaults" do
    config = Native::Scroll::ScrollConfig.new
    config.direction.should eq(Native::Scroll::ScrollDirection::Vertical)
    config.bounces.should be_true
    config.paging_enabled.should be_false
    config.zoom_enabled.should be_false
  end

  it "configures scroll direction" do
    config = Native::Scroll::ScrollConfig.new
    config.direction = Native::Scroll::ScrollDirection::Horizontal
    config.direction.should eq(Native::Scroll::ScrollDirection::Horizontal)
  end

  it "disables bounce" do
    config = Native::Scroll::ScrollConfig.new
    config.bounces = false
    config.bounces.should be_false
  end

  it "enables paging" do
    config = Native::Scroll::ScrollConfig.new
    config.paging_enabled = true
    config.paging_enabled.should be_true
  end
end

# ============================================================================
# List Tests
# ============================================================================

describe Native::List::ListConfig do
  it "creates config with defaults" do
    config = Native::List::ListConfig.new
    config.orientation.should eq(Native::List::ListOrientation::Vertical)
    config.item_spacing.should eq(0)
    config.line_spacing.should eq(0)
    config.shows_scroll_indicators.should be_true
  end

  it "configures horizontal orientation" do
    config = Native::List::ListConfig.new
    config.orientation = Native::List::ListOrientation::Horizontal
    config.orientation.should eq(Native::List::ListOrientation::Horizontal)
  end

  it "sets spacing values" do
    config = Native::List::ListConfig.new
    config.item_spacing = 10
    config.line_spacing = 20
    config.item_spacing.should eq(10)
    config.line_spacing.should eq(20)
  end

  it "enables infinite scroll" do
    config = Native::List::ListConfig.new
    config.infinite_scroll = true
    config.infinite_scroll_threshold = 300
    config.infinite_scroll.should be_true
    config.infinite_scroll_threshold.should eq(300)
  end
end

# ============================================================================
# Navigation Tests
# ============================================================================

describe Native::Navigation::TransitionConfig do
  it "creates config with defaults" do
    config = Native::Navigation::TransitionConfig.new
    config.type.should eq(Native::Navigation::TransitionType::Slide)
    config.duration.should eq(0.3)
  end

  it "configures fade transition" do
    config = Native::Navigation::TransitionConfig.new
    config.type = Native::Navigation::TransitionType::Fade
    config.type.should eq(Native::Navigation::TransitionType::Fade)
  end

  it "sets custom duration" do
    config = Native::Navigation::TransitionConfig.new
    config.duration = 0.5
    config.duration.should eq(0.5)
  end
end

describe Native::Navigation::Route do
  it "creates route with name and view" do
    view = Native::UI::View.new
    route = Native::Navigation::Route.new("home", view)
    route.name.should eq("home")
    route.view.should eq(view)
  end

  it "creates route with transition config" do
    view = Native::UI::View.new
    config = Native::Navigation::TransitionConfig.new
    config.type = Native::Navigation::TransitionType::Fade
    route = Native::Navigation::Route.new("home", view, config)
    route.transition.type.should eq(Native::Navigation::TransitionType::Fade)
  end

  it "stores additional data" do
    view = Native::UI::View.new
    data = {"id" => "123"}
    route = Native::Navigation::Route.new("profile", view, data: data)
    route.data.should eq(data)
  end
end

# ============================================================================
# Gesture Tests
# ============================================================================

describe Native::Gesture::Point do
  it "creates point with coordinates" do
    point = Native::Gesture::Point.new(10.0, 20.0)
    point.x.should eq(10.0)
    point.y.should eq(20.0)
  end

  it "calculates distance between points" do
    p1 = Native::Gesture::Point.new(0.0, 0.0)
    p2 = Native::Gesture::Point.new(3.0, 4.0)
    p1.distance_to(p2).should eq(5.0)
  end
end

describe Native::Gesture::TapGestureRecognizer do
  it "requires number of taps" do
    recognizer = Native::Gesture::TapGestureRecognizer.new
    recognizer.number_of_taps_required = 2
    recognizer.number_of_taps_required.should eq(2)
  end

  it "detects tap" do
    tapped = false
    recognizer = Native::Gesture::TapGestureRecognizer.new
    recognizer.on_tap { |point| tapped = true }
    recognizer.touches_began([Native::Gesture::Point.new(10.0, 20.0)])
    recognizer.touches_ended([Native::Gesture::Point.new(10.0, 20.0)])
    tapped.should be_true
  end
end

describe Native::Gesture::PanGestureRecognizer do
  it "tracks translation" do
    recognizer = Native::Gesture::PanGestureRecognizer.new
    last_translation = Native::Gesture::Point.new
    recognizer.on_pan { |trans, vel, point| last_translation = trans }
    recognizer.touches_began([Native::Gesture::Point.new(10.0, 10.0)])
    recognizer.touches_moved([Native::Gesture::Point.new(30.0, 40.0)])
    last_translation.x.should eq(20.0)
    last_translation.y.should eq(30.0)
  end
end

describe Native::Gesture::PinchGestureRecognizer do
  it "tracks scale" do
    last_scale = 1.0
    recognizer = Native::Gesture::PinchGestureRecognizer.new
    recognizer.on_pinch { |scale, center| last_scale = scale }

    p1 = Native::Gesture::Point.new(0.0, 0.0)
    p2 = Native::Gesture::Point.new(100.0, 0.0)
    recognizer.touches_began([p1, p2])

    p1 = Native::Gesture::Point.new(0.0, 0.0)
    p2 = Native::Gesture::Point.new(200.0, 0.0)
    recognizer.touches_moved([p1, p2])

    last_scale.should eq(2.0)
  end
end

# ============================================================================
# Video Tests
# ============================================================================

describe Native::Video::VideoConfig do
  it "creates config with defaults" do
    config = Native::Video::VideoConfig.new
    config.auto_play.should be_false
    config.loop.should be_false
    config.muted.should be_false
    config.volume.should eq(1.0)
    config.controls.should be_true
  end

  it "enables auto play" do
    config = Native::Video::VideoConfig.new
    config.auto_play = true
    config.auto_play.should be_true
  end

  it "enables looping" do
    config = Native::Video::VideoConfig.new
    config.loop = true
    config.loop.should be_true
  end

  it "mutes audio" do
    config = Native::Video::VideoConfig.new
    config.muted = true
    config.muted.should be_true
  end

  it "sets volume" do
    config = Native::Video::VideoConfig.new
    config.volume = 0.5
    config.volume.should eq(0.5)
  end

  it "hides controls" do
    config = Native::Video::VideoConfig.new
    config.controls = false
    config.controls.should be_false
  end

  it "sets fill mode" do
    config = Native::Video::VideoConfig.new
    config.fill_mode = "cover"
    config.fill_mode.should eq("cover")
  end
end

describe Native::Video::VideoState do
  it "has all states" do
    Native::Video::VideoState::Idle.should be_a(Native::Video::VideoState)
    Native::Video::VideoState::Loading.should be_a(Native::Video::VideoState)
    Native::Video::VideoState::Playing.should be_a(Native::Video::VideoState)
    Native::Video::VideoState::Paused.should be_a(Native::Video::VideoState)
    Native::Video::VideoState::Buffering.should be_a(Native::Video::VideoState)
    Native::Video::VideoState::Ended.should be_a(Native::Video::VideoState)
    Native::Video::VideoState::Error.should be_a(Native::Video::VideoState)
  end
end
