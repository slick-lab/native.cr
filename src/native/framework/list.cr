# src/native/framework/list.cr

module Native
  module List
    enum ListOrientation
      Vertical
      Horizontal
    end

    struct ListConfig
      property orientation : ListOrientation = ListOrientation::Vertical
      property item_spacing : Int32 = 0
      property line_spacing : Int32 = 0
      property padding : Styling::EdgeInsets = Styling::EdgeInsets.new
      property shows_scroll_indicators : Bool = true
      property bounces : Bool = true
      property infinite_scroll : Bool = false
      property infinite_scroll_threshold : Int32 = 200

      def initialize
      end
    end

    abstract class ListAdapter
      abstract def item_count : Int32
      abstract def create_item(index : Int32) : UI::View
      abstract def update_item(item : UI::View, index : Int32) : Nil
      
      def get_item_id(index : Int32) : Int64
        index.to_i64
      end
      
      def has_stable_ids? : Bool
        false
      end
      
      def on_item_clicked(index : Int32) : Nil
      end
      
      def on_item_long_pressed(index : Int32) : Nil
      end
    end

    class SimpleListAdapter < ListAdapter
      @items : Array(UI::View)
      
      def initialize(@items : Array(UI::View))
      end
      
      def item_count : Int32
        @items.size
      end
      
      def create_item(index : Int32) : UI::View
        @items[index]
      end
      
      def update_item(item : UI::View, index : Int32) : Nil
        # Simple adapter doesn't update
      end
    end

    class DataListAdapter(T) < ListAdapter
      @data : Array(T)
      @item_builder : (T, Int32 -> UI::View)
      @item_updater : (UI::View, T, Int32 -> Nil)?
      
      def initialize(@data : Array(T), &builder : T, Int32 -> UI::View)
        @item_builder = builder
        @item_updater = nil
      end
      
      def initialize(@data : Array(T), 
                     &builder : T, Int32 -> UI::View,
                     &updater : UI::View, T, Int32 -> Nil)
        @item_builder = builder
        @item_updater = updater
      end
      
      def item_count : Int32
        @data.size
      end
      
      def create_item(index : Int32) : UI::View
        @item_builder.call(@data[index], index)
      end
      
      def update_item(item : UI::View, index : Int32) : Nil
        if updater = @item_updater
          updater.call(item, @data[index], index)
        end
      end
      
      def update_data(new_data : Array(T)) : Nil
        @data = new_data
      end
      
      def get_item(index : Int32) : T
        @data[index]
      end
    end

    class RecyclerView < UI::View
      @config : ListConfig
      @adapter : ListAdapter?
      @recycled_pool : Array(UI::View) = [] of UI::View
      @visible_items : Hash(Int32, UI::View) = {} of Int32 => UI::View
      @first_visible_index : Int32 = 0
      @last_visible_index : Int32 = -1
      @total_height : Int32 = 0
      @scroll_y : Int32 = 0
      @is_dragging : Bool = false
      @velocity : Float64 = 0.0
      @last_touch_y : Int32 = 0
      @last_touch_time : Float64 = 0.0
      @on_item_click : (Int32 -> Nil)?
      @on_item_long_press : (Int32 -> Nil)?
      @on_scroll : (Int32 -> Nil)?
      @on_scroll_end : ( -> Nil)?
      @infinite_scroll_loading : Bool = false
      @on_load_more : ( -> Nil)?

      def initialize(config : ListConfig = ListConfig.new)
        super()
        @config = config
        @clips_to_bounds = true
      end

      def set_adapter(adapter : ListAdapter) : Nil
        @adapter = adapter
        calculate_total_height
        recycle_all
        layout_visible_items
      end

      def adapter : ListAdapter?
        @adapter
      end

      def notify_data_changed : Nil
        calculate_total_height
        recycle_all
        layout_visible_items
      end

      def notify_item_changed(index : Int32) : Nil
        if item = @visible_items[index]?
          @adapter.try(&.update_item(item, index))
        end
      end

      def notify_item_inserted(index : Int32) : Nil
        calculate_total_height
        recycle_all
        layout_visible_items
      end

      def notify_item_removed(index : Int32) : Nil
        calculate_total_height
        recycle_all
        layout_visible_items
      end

      def scroll_to_position(index : Int32, animated : Bool = true) : Nil
        return unless adapter = @adapter
        
        if index < 0 || index >= adapter.item_count
          return
        end
        
        target_y = calculate_item_position(index)
        
        if animated
          animate_scroll_to(target_y)
        else
          @scroll_y = target_y
          layout_visible_items
        end
      end

      def scroll_to_top(animated : Bool = true) : Nil
        scroll_to_position(0, animated)
      end

      def scroll_to_bottom(animated : Bool = true) : Nil
        return unless adapter = @adapter
        scroll_to_position(adapter.item_count - 1, animated)
      end

      def current_scroll_position : Int32
        @scroll_y
      end

      def on_item_click(&block : Int32 -> Nil) : Nil
        @on_item_click = block
      end

      def on_item_long_press(&block : Int32 -> Nil) : Nil
        @on_item_long_press = block
      end

      def on_scroll(&block : Int32 -> Nil) : Nil
        @on_scroll = block
      end

      def on_scroll_end(&block : -> Nil) : Nil
        @on_scroll_end = block
      end

      def on_load_more(&block : -> Nil) : Nil
        @on_load_more = block
      end

      def layout(x : Int32, y : Int32, width : Int32, height : Int32) : Nil
        super(x, y, width, height)
        layout_visible_items
      end

      def draw(renderer : Void*) : Nil
        return unless @visible
        
        if @clips_to_bounds
          save_clipping(renderer, absolute_x, absolute_y, @width, @height)
          draw_children(renderer)
          restore_clipping(renderer)
        else
          draw_children(renderer)
        end
        
        draw_scroll_indicators(renderer)
      end

      def on_touch_began(x : Int32, y : Int32) : Bool
        return false unless hit_test(x, y)
        
        @is_dragging = true
        @last_touch_y = y
        @last_touch_time = now
        @velocity = 0.0
        
        check_item_click(x, y)
        
        true
      end

      def on_touch_moved(x : Int32, y : Int32) : Bool
        return false unless @is_dragging
        
        delta = y - @last_touch_y
        new_scroll = @scroll_y - delta
        
        if @config.bounces
          set_scroll_position_with_bounce(new_scroll)
        else
          set_scroll_position(clamp(new_scroll, 0, max_scroll))
        end
        
        @velocity = delta / (now - @last_touch_time)
        
        @last_touch_y = y
        @last_touch_time = now
        
        check_infinite_scroll
        
        true
      end

      def on_touch_ended(x : Int32, y : Int32) : Bool
        return false unless @is_dragging
        
        @is_dragging = false
        start_deceleration
        
        @on_scroll_end.try &.call
        
        true
      end

      private def set_scroll_position(scroll : Int32) : Nil
        @scroll_y = scroll
        layout_visible_items
        @on_scroll.try &.call(@scroll_y)
      end

      private def set_scroll_position_with_bounce(scroll : Int32) : Nil
        @scroll_y = scroll
        layout_visible_items
        @on_scroll.try &.call(@scroll_y)
      end

      private def animate_scroll_to(target_y : Int32) : Nil
        start_y = @scroll_y
        start_time = now
        duration = 0.3
        
        spawn do
          while true
            elapsed = now - start_time
            if elapsed >= duration
              set_scroll_position(target_y)
              break
            end
            
            t = elapsed / duration
            eased = 1.0 - (1.0 - t) * (1.0 - t)
            current_y = start_y + (target_y - start_y) * eased
            
            set_scroll_position(current_y.to_i)
            sleep(0.016)
          end
        end
      end

      private def start_deceleration : Nil
        return if @velocity.abs < 0.1
        
        spawn do
          vel = @velocity
          deceleration = 0.998
          
          60.times do
            vel *= deceleration
            
            new_scroll = @scroll_y - vel.to_i
            
            if @config.bounces
              set_scroll_position_with_bounce(new_scroll)
            else
              set_scroll_position(clamp(new_scroll, 0, max_scroll))
            end
            
            break if vel.abs < 0.1
            sleep(0.016)
          end
        end
      end

      private def calculate_total_height : Nil
        return unless adapter = @adapter
        
        @total_height = 0
        adapter.item_count.times do |i|
          @total_height += get_item_height(i)
          @total_height += @config.line_spacing if i < adapter.item_count - 1
        end
      end

      private def get_item_height(index : Int32) : Int32
        # Default height - can be overridden for variable heights
        50
      end

      private def calculate_item_position(index : Int32) : Int32
        position = 0
        index.times do |i|
          position += get_item_height(i)
          position += @config.line_spacing
        end
        position
      end

      private def layout_visible_items : Nil
        return unless adapter = @adapter
        return if @height <= 0
        
        recycle_off_screen_items
        
        start_index = find_first_visible_index
        end_index = find_last_visible_index(start_index)
        
        if start_index != @first_visible_index || end_index != @last_visible_index
          @first_visible_index = start_index
          @last_visible_index = end_index
          fill_visible_items(start_index, end_index)
        end
        
        update_visible_item_positions(start_index)
      end

      private def find_first_visible_index : Int32
        return 0 unless adapter = @adapter
        
        current_y = @scroll_y
        index = 0
        
        while index < adapter.item_count && current_y > 0
          current_y -= get_item_height(index) + @config.line_spacing
          index += 1
        end
        
        [index, adapter.item_count - 1].min
      end

      private def find_last_visible_index(start_index : Int32) : Int32
        return start_index unless adapter = @adapter
        
        current_y = @scroll_y
        index = start_index
        visible_height = 0
        
        while index < adapter.item_count && visible_height < @height
          visible_height += get_item_height(index) + @config.line_spacing
          index += 1
        end
        
        [index - 1, adapter.item_count - 1].min
      end

      private def fill_visible_items(start_index : Int32, end_index : Int32) : Nil
        return unless adapter = @adapter
        
        (start_index..end_index).each do |index|
          unless @visible_items.has_key?(index)
            item = get_recycled_item
            if item
              adapter.update_item(item, index)
            else
              item = adapter.create_item(index)
            end
            @visible_items[index] = item
            @container.add_child(item)
          end
        end
      end

      private def update_visible_item_positions(start_index : Int32) : Nil
        current_y = -@scroll_y + @config.padding.top
        
        start_index.times do |i|
          current_y += get_item_height(i) + @config.line_spacing
        end
        
        @visible_items.each do |index, item|
          item.x = @config.padding.left
          item.y = current_y
          item.width = @width - @config.padding.left - @config.padding.right
          item.height = get_item_height(index)
          current_y += item.height + @config.line_spacing
        end
      end

      private def recycle_off_screen_items : Nil
        @visible_items.each do |index, item|
          item_y = item.y
          if item_y + item.height < 0 || item_y > @height
            @visible_items.delete(index)
            @container.remove_child(item)
            @recycled_pool << item
          end
        end
      end

      private def recycle_all : Nil
        @visible_items.each do |index, item|
          @container.remove_child(item)
          @recycled_pool << item
        end
        @visible_items.clear
      end

      private def get_recycled_item : UI::View?
        @recycled_pool.pop
      end

      private def max_scroll : Int32
        [0, @total_height - @height].max
      end

      private def clamp(value : Int32, min : Int32, max : Int32) : Int32
        return min if value < min
        return max if value > max
        value
      end

      private def check_item_click(x : Int32, y : Int32) : Nil
        local_y = y - absolute_y
        
        @visible_items.each do |index, item|
          if local_y >= item.y && local_y <= item.y + item.height
            @on_item_click.try &.call(index)
            break
          end
        end
      end

      private def check_infinite_scroll : Nil
        return if !@config.infinite_scroll || @infinite_scroll_loading
        
        if adapter = @adapter
          if @last_visible_index >= adapter.item_count - @config.infinite_scroll_threshold
            @infinite_scroll_loading = true
            @on_load_more.try &.call
            @infinite_scroll_loading = false
          end
        end
      end

      private def draw_scroll_indicators(renderer : Void*) : Nil
        return unless @config.shows_scroll_indicators
        return if @total_height <= @height
        
        indicator_height = (@height.to_f * (@height.to_f / @total_height.to_f)).to_i
        indicator_y = (@scroll_y.to_f / (@total_height - @height).to_f * (@height - indicator_height)).to_i
        
        draw_rect(renderer,
                  absolute_x + @width - 4,
                  absolute_y + indicator_y,
                  3,
                  indicator_height,
                  150, 150, 150, 150)
      end

      private def now : Float64
        Time.utc.to_unix_f
      end
    end
  end
end
