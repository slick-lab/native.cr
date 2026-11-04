# spec/dsl_spec.cr
#
# The layout DSL surface the examples and docs rely on:
# Column/Row, spacing/alignment, add_child/add_view aliases,
# on_click = proc form, color= alias, CornerRadius, set_background_color.

require "./spec_helper"

class DslSpecApp < Native::App
  def setup : Nil
  end
end

describe "layout DSL" do
  it "Column is a vertical LinearLayout" do
    column = Native::UI::Column.new
    column.orientation.should eq(Native::UI::LinearLayout::Orientation::Vertical)
  end

  it "Row is a horizontal LinearLayout" do
    row = Native::UI::Row.new
    row.orientation.should eq(Native::UI::LinearLayout::Orientation::Horizontal)
  end

  it "Column accepts a setup block" do
    column = Native::UI::Column.new do |c|
      c.spacing = 16
    end
    column.spacing.should eq(16)
  end

  it "alignment maps onto gravity" do
    column = Native::UI::Column.new
    column.alignment = Native::UI::Alignment::Center
    column.alignment.should eq(Native::UI::LinearLayout::Gravity::Center)
    column.alignment.should eq(Native::UI::Alignment::Center)
  end

  it "add_child / add_view are aliases of addView" do
    column = Native::UI::Column.new
    column.add_child(Native::UI::TextView.new("one"))
    column.add_view(Native::UI::TextView.new("two"))
    column.childCount.should eq(2)

    row = Native::UI::Row.new
    row.add_child(Native::UI::Button.new("three"))
    row.childCount.should eq(1)
  end

  it "spacing stores and is introspectable" do
    column = Native::UI::Column.new
    column.spacing = 24
    column.spacing.should eq(24)
  end
end

describe "widget DSL" do
  it "TextView color= aliases text_color=" do
    tv = Native::UI::TextView.new("hi")
    tv.color = Native::Math::Color.from_hex(0x336699)
    tv.color.r.should be_close(0x33 / 255.0, 1e-9)
    tv.text_color.should eq(tv.color)
  end

  it "Button on_click= accepts a proc" do
    button = Native::UI::Button.new("go")
    fired = false
    button.on_click = ->{ fired = true; nil }
    fired.should be_false
  end

  it "corner_radius accepts Int and CornerRadius" do
    button = Native::UI::Button.new("rounded")
    button.corner_radius = 24
    button.corner_radius.uniform?.should be_true
    button.corner_radius.max.should eq(24.0_f32)

    button.corner_radius = Native::UI::CornerRadius.all(12)
    button.corner_radius.max.should eq(12.0_f32)
  end

  it "CornerRadius.all builds a uniform radius" do
    r = Native::UI::CornerRadius.all(8)
    r.top_left.should eq(8.0_f32)
    r.bottom_right.should eq(8.0_f32)
    r.uniform?.should be_true
  end
end

describe "Color shortcuts" do
  it "from_rgb takes floats" do
    c = Native::Math::Color.from_rgb(0.5, 0.25, 0.75)
    c.r.should be_close(0.5, 1e-9)
    c.g.should be_close(0.25, 1e-9)
    c.b.should be_close(0.75, 1e-9)
    c.a.should eq(1.0)
  end

  it "from_rgb accepts alpha" do
    c = Native::Math::Color.from_rgb(1.0, 1.0, 1.0, 0.5)
    c.a.should be_close(0.5, 1e-9)
  end
end

describe "App helpers" do
  it "set_background_color stores a pending color until root= lands" do
    app = DslSpecApp.new
    app.set_background_color(240, 240, 245)
    # desktop: nothing crashes, no root yet
    app.root.should be_nil
  end

  it "set_background_color applies via root=" do
    app = DslSpecApp.new
    app.set_background_color(10, 20, 30)
    layout = Native::UI::Column.new
    app.root = layout
  end
end
