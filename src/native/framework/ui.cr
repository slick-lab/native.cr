# src/native/framework/ui.cr

module Native
  module UI
    enum Alignment
      Start
      Center
      End
      Stretch
    end

    enum Axis
      Horizontal
      Vertical
    end

    abstract class View
      property x : Int32 = 0
      property y : Int32 = 0
      property width : Int32 = 0
      property height : Int32 = 0
      property visible : Bool = true
      property alpha : Float32 = 1.0
      property background_r : UInt8 = 0
      property background_g : UInt8 = 0
      property background_b : UInt8 = 0
      property background_a : UInt8 = 255
      property parent : View? = nil
      
      def initialize
        @children = [] of View
      end
      
      def add_child(child : View) : Nil
        child.parent = self
        @children << child
      end
      
      def remove_child(child : View) : Nil
        child.parent = nil
        @children.delete(child)
      end
      
      def children : Array(View)
        @children.dup
      end
      
      def absolute_x : Int32
        px = @x
        parent.try { |p| px += p.absolute_x }
        px
      end
      
      def absolute_y : Int32
        py = @y
        parent.try { |p| py += p.absolute_y }
        py
      end
      
      def measure(max_width : Int32, max_height : Int32) : {Int32, Int32}
        {width, height}
      end
      
      def layout(x : Int32, y : Int32, width : Int32, height : Int32) : Nil
        @x = x
        @y = y
        @width = width
        @height = height
      end
      
      def draw(renderer : Void*) : Nil
        return unless @visible && @alpha > 0
        draw_background(renderer)
        @children.each { |child| child.draw(renderer) }
      end
      
      protected def draw_background(renderer : Void*) : Nil
        if @background_a > 0
          draw_rect(renderer, absolute_x, absolute_y, width, height, 
                    @background_r, @background_g, @background_b, @background_a)
        end
      end
      
      protected def draw_rect(renderer : Void*, x : Int32, y : Int32, w : Int32, h : Int32,
                               r : UInt8, g : UInt8, b : UInt8, a : UInt8) : Nil
        {% if flag?(:android)%}
          LibAndroid.draw_rect(renderer, x, y, w, h, r, g, b, a)
        {% elsif flag?(:ios)%}
          LibIOS.draw_rect(renderer, x, y, w, h, r.to_f / 255, g.to_f / 255, b.to_f / 255, a.to_f / 255)
        {% end %}
      end
      
      protected def draw_text(renderer : Void*, text : String, x : Int32, y : Int32, size : Int32,
                               r : UInt8, g : UInt8, b : UInt8) : Nil
        {% if flag?(:android)%}
          LibAndroid.draw_text(renderer, text.to_utf8, x, y, size, r, g, b)
        {% elsif flag?(:ios)%}
          LibIOS.draw_text(renderer, text.to_utf8, x, y, size, r.to_f / 255, g.to_f / 255, b.to_f / 255)
        {% end %}
      end
      
      def on_touch_began(x : Int32, y : Int32) : Bool
        return false unless hit_test(x, y)
        @children.each { |c| return true if c.on_touch_began(x, y) }
        false
      end
      
      def on_touch_moved(x : Int32, y : Int32) : Bool
        return false unless hit_test(x, y)
        @children.each { |c| return true if c.on_touch_moved(x, y) }
        false
      end
      
      def on_touch_ended(x : Int32, y : Int32) : Bool
        return false unless hit_test(x, y)
        @children.each { |c| return true if c.on_touch_ended(x, y) }
        false
      end
      
      def hit_test(x : Int32, y : Int32) : Bool
        return false unless @visible
        ax = absolute_x
        ay = absolute_y
        x >= ax && x < ax + @width && y >= ay && y < ay + @height
      end
    end
    
    class Text < View
      property text : String = ""
      property text_size : Int32 = 16
      property text_r : UInt8 = 0
      property text_g : UInt8 = 0
      property text_b : UInt8 = 0
      
      def draw(renderer : Void*) : Nil
        return unless @visible && @alpha > 0
        draw_text(renderer, @text, absolute_x, absolute_y, @text_size, @text_r, @text_g, @text_b)
      end
      
      def measure(max_width : Int32, max_height : Int32) : {Int32, Int32}
        {% if flag?(:android)%}
          w = LibAndroid.measure_text(@text.to_utf8, @text_size)
        {% elsif flag?(:ios) %}
          w = LibIOS.measure_text(@text.to_utf8, @text_size)
        {% end %}
        {w, @text_size}
      end
    end
    
    class Button < View
      property text : String = ""
      property text_size : Int32 = 16
      property text_r : UInt8 = 255
      property text_g : UInt8 = 255
      property text_b : UInt8 = 255
      property on_click : (-> Nil)?
      
      def initialize
        super
        @background_r = 100
        @background_g = 100
        @background_b = 100
        @width = 100
        @height = 40
      end
      
      def draw(renderer : Void*) : Nil
        return unless @visible && @alpha > 0
        draw_background(renderer)
        draw_text(renderer, @text, absolute_x + 10, absolute_y + @height // 2 - @text_size // 2,
                  @text_size, @text_r, @text_g, @text_b)
      end
      
      def on_touch_ended(x : Int32, y : Int32) : Bool
        if hit_test(x, y)
          @on_click.try &.call
          return true
        end
        false
      end
      
      def measure(max_width : Int32, max_height : Int32) : {Int32, Int32}
        {% if flag?(:android) %}
          w = LibAndroid.measure_text(@text.to_utf8, @text_size)
        {% elsif flag?(:ios) %}
          w = LibIOS.measure_text(@text.to_utf8, @text_size)
        {% end %}
        {[w + 20, 100].max, 40}
      end
    end
    
    class Column < View
      property spacing : Int32 = 8
      property alignment : Alignment = Alignment::Start
      
      def layout(x : Int32, y : Int32, width : Int32, height : Int32) : Nil
        @x = x
        @y = y
        @width = width
        @height = height
        
        current_y = y
        @children.each do |child|
          child_w, child_h = child.measure(width, height - (current_y - y))
          child_x = case @alignment
                    when Alignment::Start
                      x
                    when Alignment::Center
                      x + (width - child_w) // 2
                    when Alignment::End
                      x + width - child_w
                    when Alignment::Stretch
                      x
                      child_w = width
                    end
          child.layout(child_x, current_y, child_w, child_h)
          current_y += child_h + @spacing
        end
      end
      
      def measure(max_width : Int32, max_height : Int32) : {Int32, Int32}
        total_height = 0
        max_child_width = 0
        
        @children.each do |child|
          child_w, child_h = child.measure(max_width, max_height - total_height)
          max_child_width = [max_child_width, child_w].max
          total_height += child_h + @spacing
        end
        
        total_height -= @spacing if @children.size > 0
        {max_child_width, total_height}
      end
    end
    
    class Row < View
      property spacing : Int32 = 8
      property alignment : Alignment = Alignment::Start
      
      def layout(x : Int32, y : Int32, width : Int32, height : Int32) : Nil
        @x = x
        @y = y
        @width = width
        @height = height
        
        current_x = x
        @children.each do |child|
          child_w, child_h = child.measure(width - (current_x - x), height)
          child_y = case @alignment
                    when Alignment::Start
                      y
                    when Alignment::Center
                      y + (height - child_h) // 2
                    when Alignment::End
                      y + height - child_h
                    when Alignment::Stretch
                      y
                      child_h = height
                    end
          child.layout(current_x, child_y, child_w, child_h)
          current_x += child_w + @spacing
        end
      end
      
      def measure(max_width : Int32, max_height : Int32) : {Int32, Int32}
        total_width = 0
        max_child_height = 0
        
        @children.each do |child|
          child_w, child_h = child.measure(max_width - total_width, max_height)
          max_child_height = [max_child_height, child_h].max
          total_width += child_w + @spacing
        end
        
        total_width -= @spacing if @children.size > 0
        {total_width, max_child_height}
      end
    end
    
    class Container < View
      property padding : Int32 = 0
      
      def layout(x : Int32, y : Int32, width : Int32, height : Int32) : Nil
        @x = x
        @y = y
        @width = width
        @height = height
        
        @children.each do |child|
          child.layout(x + @padding, y + @padding, width - @padding * 2, height - @padding * 2)
        end
      end
    end
  end
end
