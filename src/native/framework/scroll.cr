# src/native/framework/scroll.cr

module Native
  module Scroll
    enum ScrollDirection
      Vertical
      Horizontal
      Both
    end

    enum ScrollBarVisibility
      Always
      Auto
      Never
    end

    struct ScrollConfig
      property direction : ScrollDirection = ScrollDirection::Vertical
      property scroll_bar_visibility : ScrollBarVisibility = ScrollBarVisibility::Auto
      property bounces : Bool = true
      property paging_enabled : Bool = false
      property zoom_enabled : Bool = false
      property shows_horizontal_indicator : Bool = true
      property shows_vertical_indicator : Bool = true
      property deceleration_rate : Float32 = 0.998
      property content_inset : Styling::EdgeInsets = Styling::EdgeInsets.new

      def initialize
      end
    end

    class ScrollView < UI::View
      @config : ScrollConfig
      @content_view : UI::View
      @scroll_x : Float64 = 0.0
      @scroll_y : Float64 = 0.0
      @content_width : Int32 = 0
      @content_height : Int32 = 0
      @is_dragging : Bool = false
      @velocity_x : Float64 = 0.0
      @velocity_y : Float64 = 0.0
      @last_touch_x : Float64 = 0.0
      @last_touch_y : Float64 = 0.0
      @last_touch_time : Float64 = 0.0
      @on_scroll : (Float64, Float64 -> Nil)?
      @on_scroll_end : (-> Nil)?

      def initialize(config : ScrollConfig = ScrollConfig.new)
        super()
        @config = config
        @content_view = UI::View.new
        @clips_to_bounds = true
        add_child(@content_view)
      end

      def content : UI::View
        @content_view
      end

      def add_child(child : UI::View) : Nil
        if @content_view
          @content_view.add_child(child)
        else
          super(child)
        end
      end

      def scroll_to(x : Float64, y : Float64, animated : Bool = true) : Nil
        target_x = clamp(x, 0.0, max_scroll_x)
        target_y = clamp(y, 0.0, max_scroll_y)

        if animated
          animate_scroll(target_x, target_y)
        else
          set_scroll_position(target_x, target_y)
        end
      end

      def scroll_to_bottom(animated : Bool = true) : Nil
        scroll_to(0.0, max_scroll_y, animated)
      end

      def scroll_to_top(animated : Bool = true) : Nil
        scroll_to(0.0, 0.0, animated)
      end

      def scroll_x : Float64
        @scroll_x
      end

      def scroll_y : Float64
        @scroll_y
      end

      def on_scroll(&block : Float64, Float64 -> Nil) : Nil
        @on_scroll = block
      end

      def on_scroll_end(&block : -> Nil) : Nil
        @on_scroll_end = block
      end

      def layout(x : Int32, y : Int32, width : Int32, height : Int32) : Nil
        super(x, y, width, height)

        calculate_content_size
        update_content_position
      end

      def draw(renderer : Void*) : Nil
        return unless @visible

        if @clips_to_bounds
          save_clipping(renderer, absolute_x, absolute_y, @width, @height)
          super(renderer)
          restore_clipping(renderer)
        else
          super(renderer)
        end

        draw_scroll_indicators(renderer)
      end

      def on_touch_began(x : Int32, y : Int32) : Bool
        return false unless hit_test(x, y)

        @is_dragging = true
        @last_touch_x = x.to_f64
        @last_touch_y = y.to_f64
        @last_touch_time = now
        @velocity_x = 0.0
        @velocity_y = 0.0

        true
      end

      def on_touch_moved(x : Int32, y : Int32) : Bool
        return false unless @is_dragging

        delta_x = (x.to_f64 - @last_touch_x)
        delta_y = (y.to_f64 - @last_touch_y)

        new_scroll_x = @scroll_x - delta_x
        new_scroll_y = @scroll_y - delta_y

        if @config.bounces
          set_scroll_position_with_bounce(new_scroll_x, new_scroll_y)
        else
          set_scroll_position(clamp(new_scroll_x, 0.0, max_scroll_x), clamp(new_scroll_y, 0.0, max_scroll_y))
        end

        @velocity_x = delta_x / (now - @last_touch_time)
        @velocity_y = delta_y / (now - @last_touch_time)

        @last_touch_x = x.to_f64
        @last_touch_y = y.to_f64
        @last_touch_time = now

        true
      end

      def on_touch_ended(x : Int32, y : Int32) : Bool
        return false unless @is_dragging

        @is_dragging = false
        start_deceleration

        @on_scroll_end.try &.call

        true
      end

      private def set_scroll_position(x : Float64, y : Float64) : Nil
        @scroll_x = x
        @scroll_y = y
        update_content_position
        @on_scroll.try &.call(@scroll_x, @scroll_y)
      end

      private def set_scroll_position_with_bounce(x : Float64, y : Float64) : Nil
        @scroll_x = x
        @scroll_y = y
        update_content_position
        @on_scroll.try &.call(@scroll_x, @scroll_y)
      end

      private def animate_scroll(target_x : Float64, target_y : Float64) : Nil
        start_x = @scroll_x
        start_y = @scroll_y
        start_time = now
        duration = 0.3

        spawn do
          while true
            elapsed = now - start_time
            if elapsed >= duration
              set_scroll_position(target_x, target_y)
              break
            end

            t = elapsed / duration
            eased = 1.0 - (1.0 - t) * (1.0 - t)

            current_x = start_x + (target_x - start_x) * eased
            current_y = start_y + (target_y - start_y) * eased

            set_scroll_position(current_x, current_y)
            sleep(0.016)
          end
        end
      end

      private def start_deceleration : Nil
        return if @velocity_x.abs < 0.1 && @velocity_y.abs < 0.1

        spawn do
          vel_x = @velocity_x
          vel_y = @velocity_y
          deceleration = @config.deceleration_rate

          60.times do
            vel_x *= deceleration
            vel_y *= deceleration

            new_x = @scroll_x - vel_x
            new_y = @scroll_y - vel_y

            if @config.bounces
              set_scroll_position_with_bounce(new_x, new_y)
            else
              set_scroll_position(clamp(new_x, 0.0, max_scroll_x), clamp(new_y, 0.0, max_scroll_y))
            end

            break if vel_x.abs < 0.1 && vel_y.abs < 0.1
            sleep(0.016)
          end
        end
      end

      private def calculate_content_size : Nil
        @content_view.measure(@width, @height)
        @content_width = @content_view.width
        @content_height = @content_view.height

        if @config.direction == ScrollDirection::Vertical
          @content_view.width = @width
        elsif @config.direction == ScrollDirection::Horizontal
          @content_view.height = @height
        end
      end

      private def update_content_position : Nil
        @content_view.x = -@scroll_x.to_i
        @content_view.y = -@scroll_y.to_i
      end

      private def max_scroll_x : Float64
        [0.0, @content_width - @width].max.to_f64
      end

      private def max_scroll_y : Float64
        [0.0, @content_height - @height].max.to_f64
      end

      private def draw_scroll_indicators(renderer : Void*) : Nil
        return if @config.scroll_bar_visibility == ScrollBarVisibility::Never

        if @config.shows_vertical_indicator && @content_height > @height
          draw_vertical_indicator(renderer)
        end

        if @config.shows_horizontal_indicator && @content_width > @width
          draw_horizontal_indicator(renderer)
        end
      end

      private def draw_vertical_indicator(renderer : Void*) : Void*
        indicator_height = (@height.to_f64 * (@height.to_f64 / @content_height.to_f64)).to_i
        indicator_y = (@scroll_y / (@content_height - @height).to_f64 * (@height - indicator_height)).to_i

        draw_rect(renderer,
          absolute_x + @width - 4,
          absolute_y + indicator_y,
          3,
          indicator_height,
          100, 100, 100, 150)
      end

      private def draw_horizontal_indicator(renderer : Void*) : Void*
        indicator_width = (@width.to_f64 * (@width.to_f64 / @content_width.to_f64)).to_i
        indicator_x = (@scroll_x / (@content_width - @width).to_f64 * (@width - indicator_width)).to_i

        draw_rect(renderer,
          absolute_x + indicator_x,
          absolute_y + @height - 4,
          indicator_width,
          3,
          100, 100, 100, 150)
      end

      private def clamp(value : Float64, min : Float64, max : Float64) : Float64
        return min if value < min
        return max if value > max
        value
      end

      private def now : Float64
        Time.utc.to_unix_f
      end
    end

    class ListView < ScrollView
      @items : Array(UI::View) = [] of UI::View
      @item_height : Int32 = 0
      @item_builder : (Int32 -> UI::View)?

      def initialize(item_height : Int32 = 50, config : ScrollConfig = ScrollConfig.new)
        super(config)
        @item_height = item_height
      end

      def set_items(count : Int32, &builder : Int32 -> UI::View) : Nil
        @item_builder = builder
        @items.clear

        count.times do |i|
          item = builder.call(i)
          @items << item
          @content_view.add_child(item)
        end

        calculate_content_size
      end

      def update_item(index : Int32) : Nil
        return if index < 0 || index >= @items.size

        if builder = @item_builder
          old_item = @items[index]
          @content_view.remove_child(old_item)

          new_item = builder.call(index)
          @items[index] = new_item
          @content_view.add_child(new_item)

          relayout_item(new_item, index)
        end
      end

      def reload : Nil
        return unless builder = @item_builder

        @items.each { |item| @content_view.remove_child(item) }
        @items.clear

        @items.size.times do |i|
          item = builder.call(i)
          @items << item
          @content_view.add_child(item)
          relayout_item(item, i)
        end

        calculate_content_size
      end

      private def relayout_item(item : UI::View, index : Int32) : Nil
        item.y = index * @item_height
        item.width = @width
        item.height = @item_height
      end

      private def calculate_content_size : Nil
        @content_height = @items.size * @item_height
        @content_width = @width
      end
    end
  end
end
