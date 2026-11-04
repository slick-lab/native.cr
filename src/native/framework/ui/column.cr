# src/native/framework/ui/column.cr
#
# Composable layout DSL on top of LinearLayout:
#
#   column = UI::Column.new
#   column.spacing   = 20
#   column.alignment = Alignment::Center
#   column.add_child(title)
#   column.add_child(button)
#
# Column = vertical LinearLayout, Row = horizontal LinearLayout.
# `spacing` inserts a gap between children (margins under the hood, so it
# works on every platform LinearLayout works on), and `alignment` maps
# the Alignment enum onto layout gravity.

module Native::UI
  module Alignment
    # Values map 1:1 onto LinearLayout::Gravity (left 0 / top 1 ...).
    # Exposed as a flat module so `Alignment::Center` reads naturally in
    # layout code — that is the form every example and the docs use.
    Center     = LinearLayout::Gravity::Center
    CenterHorizontal = LinearLayout::Gravity::CenterHorizontal
    CenterVertical = LinearLayout::Gravity::CenterVertical
    Top        = LinearLayout::Gravity::Top
    Bottom     = LinearLayout::Gravity::Bottom
    Left       = LinearLayout::Gravity::Left
    Right      = LinearLayout::Gravity::Right
    Fill       = LinearLayout::Gravity::Fill
  end

  class Column < LinearLayout
    def initialize
      super(Orientation::Vertical)
    end

    def initialize(&block : Column -> Nil)
      super(Orientation::Vertical)
      block.call(self)
    end
  end

  class Row < LinearLayout
    def initialize
      super(Orientation::Horizontal)
    end

    def initialize(&block : Row -> Nil)
      super(Orientation::Horizontal)
      block.call(self)
    end
  end

  # Uniform corner rounding — the `CornerRadius.all(24)` form used by the
  # examples. Per-corner radii are stored and applied where the platform
  # supports them (iOS CALayer is uniform; Android GradientDrawable is
  # per-corner, applied when background_color is also set).
  struct CornerRadius
    property top_left : Float32
    property top_right : Float32
    property bottom_right : Float32
    property bottom_left : Float32

    def initialize(@top_left = 0.0_f32, @top_right = 0.0_f32,
                   @bottom_right = 0.0_f32, @bottom_left = 0.0_f32)
    end

    def self.all(radius : Int32 | Float32) : CornerRadius
      r = radius.to_f32
      CornerRadius.new(r, r, r, r)
    end

    def uniform? : Bool
      top_left == top_right == bottom_right == bottom_left
    end

    def max : Float32
      {top_left, top_right, bottom_right, bottom_left}.max
    end
  end
end
