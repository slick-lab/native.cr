# src/native/framework/styling.cr

module Native
  module Styling
    struct Color
      property r : UInt8
      property g : UInt8
      property b : UInt8
      property a : UInt8

      def initialize(@r = 0, @g = 0, @b = 0, @a = 255)
      end

      def self.black : Color
        new(0, 0, 0)
      end

      def self.white : Color
        new(255, 255, 255)
      end

      def self.red : Color
        new(255, 0, 0)
      end

      def self.green : Color
        new(0, 255, 0)
      end

      def self.blue : Color
        new(0, 0, 255)
      end

      def self.gray(level : UInt8) : Color
        new(level, level, level)
      end

      def self.rgb(r : UInt8, g : UInt8, b : UInt8) : Color
        new(r, g, b)
      end

      def self.rgba(r : UInt8, g : UInt8, b : UInt8, a : UInt8) : Color
        new(r, g, b, a)
      end

      def self.hex(hex : UInt32) : Color
        r = ((hex >> 16) & 0xFF).to_u8
        g = ((hex >> 8) & 0xFF).to_u8
        b = (hex & 0xFF).to_u8
        a = ((hex >> 24) & 0xFF).to_u8
        new(r, g, b, a)
      end

      def to_hex : UInt32
        (r.to_u32 << 16) | (g.to_u32 << 8) | b.to_u32
      end

      def with_alpha(a : UInt8) : Color
        Color.new(@r, @g, @b, a)
      end

      def lighten(amount : UInt8) : Color
        Color.new(
          (@r + amount).clamp(0, 255).to_u8,
          (@g + amount).clamp(0, 255).to_u8,
          (@b + amount).clamp(0, 255).to_u8,
          @a
        )
      end

      def darken(amount : UInt8) : Color
        Color.new(
          (@r - amount).clamp(0, 255).to_u8,
          (@g - amount).clamp(0, 255).to_u8,
          (@b - amount).clamp(0, 255).to_u8,
          @a
        )
      end
    end

    struct EdgeInsets
      property top : Int32
      property left : Int32
      property bottom : Int32
      property right : Int32

      def initialize(@top = 0, @left = 0, @bottom = 0, @right = 0)
      end

      def self.all(value : Int32) : EdgeInsets
        new(value, value, value, value)
      end

      def self.horizontal(value : Int32) : EdgeInsets
        new(0, value, 0, value)
      end

      def self.vertical(value : Int32) : EdgeInsets
        new(value, 0, value, 0)
      end
    end

    struct CornerRadius
      property top_left : Int32
      property top_right : Int32
      property bottom_left : Int32
      property bottom_right : Int32

      def initialize(@top_left = 0, @top_right = 0, @bottom_left = 0, @bottom_right = 0)
      end

      def self.all(value : Int32) : CornerRadius
        new(value, value, value, value)
      end
    end

    enum FontWeight
      Normal
      Bold
      Light
      Medium
      Semibold
    end

    struct Font
      property name : String
      property size : Int32
      property weight : FontWeight

      def initialize(@name = "System", @size = 16, @weight = FontWeight::Normal)
      end

      def self.system(size : Int32, weight : FontWeight = FontWeight::Normal) : Font
        new("System", size, weight)
      end

      def self.bold(size : Int32) : Font
        new("System", size, FontWeight::Bold)
      end
    end

    struct Shadow
      property color : Color
      property offset_x : Int32
      property offset_y : Int32
      property blur : Int32

      def initialize(@color = Color.black, @offset_x = 0, @offset_y = 2, @blur = 4)
      end
    end

    module Theme
      class_property primary_color : Color = Color.blue
      class_property secondary_color : Color = Color.gray(100)
      class_property background_color : Color = Color.white
      class_property text_color : Color = Color.black
      class_property error_color : Color = Color.red
      class_property success_color : Color = Color.green
      class_property font : Font = Font.system(16)
      class_property heading_font : Font = Font.bold(24)
      class_property corner_radius : CornerRadius = CornerRadius.all(8)
      class_property spacing : Int32 = 16
    end

    module Style
      def self.button_primary : UI::Button
        btn = UI::Button.new
        btn.background_color = Theme.primary_color
        btn.text_color = Color.white
        btn.corner_radius = Theme.corner_radius
        btn
      end

      def self.button_secondary : UI::Button
        btn = UI::Button.new
        btn.background_color = Theme.secondary_color
        btn.text_color = Theme.text_color
        btn.corner_radius = Theme.corner_radius
        btn
      end

      def self.card : UI::Container
        container = UI::Container.new
        container.background_color = Theme.background_color
        container.corner_radius = Theme.corner_radius
        container.shadow = Shadow.new
        container.padding = EdgeInsets.all(Theme.spacing)
        container
      end

      def self.heading(text : String) : UI::Text
        label = UI::Text.new
        label.text = text
        label.font = Theme.heading_font
        label.color = Theme.text_color
        label
      end

      def self.body(text : String) : UI::Text
        label = UI::Text.new
        label.text = text
        label.font = Theme.font
        label.color = Theme.text_color
        label
      end
    end
  end
end
