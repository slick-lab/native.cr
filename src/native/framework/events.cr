# src/native/framework/events.cr

module Native
  module Events
    enum TouchAction
      Began
      Moved
      Ended
      Cancelled
    end

    struct Touch
      property id : Int32
      property x : Float32
      property y : Float32
      property pressure : Float32

      def initialize(@id = 0, @x = 0.0, @y = 0.0, @pressure = 1.0)
      end
    end

    enum KeyCode
      Unknown = 0
      Back = 4
      Home = 3
      Menu = 82
      VolumeUp = 24
      VolumeDown = 25
      Enter = 66
      Delete = 67
      Tab = 61
      Space = 62
      Escape = 111
      
      A = 29
      B = 30
      C = 31
      D = 32
      E = 33
      F = 34
      G = 35
      H = 36
      I = 37
      J = 38
      K = 39
      L = 40
      M = 41
      N = 42
      O = 43
      P = 44
      Q = 45
      R = 46
      S = 47
      T = 48
      U = 49
      V = 50
      W = 51
      X = 52
      Y = 53
      Z = 54
      
      Num0 = 7
      Num1 = 8
      Num2 = 9
      Num3 = 10
      Num4 = 11
      Num5 = 12
      Num6 = 13
      Num7 = 14
      Num8 = 15
      Num9 = 16
    end

    struct KeyEvent
      property key_code : KeyCode
      property action : TouchAction
      property text : String

      def initialize(@key_code = KeyCode::Unknown, @action = TouchAction::Began, @text = "")
      end

      def is_pressed? : Bool
        @action == TouchAction::Began
      end

      def is_released? : Bool
        @action == TouchAction::Ended
      end
    end

    struct GestureEvent
      enum GestureType
        Tap
        DoubleTap
        LongPress
        Pan
        Pinch
        Rotate
        Swipe
      end

      property type : GestureType
      property center_x : Float32
      property center_y : Float32
      property scale : Float32
      property rotation : Float32
      property velocity_x : Float32
      property velocity_y : Float32

      def initialize(@type = GestureType::Tap, @center_x = 0.0, @center_y = 0.0, 
                     @scale = 1.0, @rotation = 0.0, @velocity_x = 0.0, @velocity_y = 0.0)
      end
    end

    abstract class EventHandler
      @touch_listeners = [] of TouchListener
      @gesture_listeners = [] of GestureListener
      @key_listeners = [] of KeyListener

      def on_touch(listener : TouchListener) : Nil
        @touch_listeners << listener
      end

      def on_gesture(listener : GestureListener) : Nil
        @gesture_listeners << listener
      end

      def on_key(listener : KeyListener) : Nil
        @key_listeners << listener
      end

      protected def dispatch_touch(touch : Touch, action : TouchAction) : Nil
        @touch_listeners.each do |listener|
          case action
          when TouchAction::Began
            listener.on_touch_began(touch)
          when TouchAction::Moved
            listener.on_touch_moved(touch)
          when TouchAction::Ended
            listener.on_touch_ended(touch)
          when TouchAction::Cancelled
            listener.on_touch_cancelled(touch)
          end
        end
      end

      protected def dispatch_gesture(gesture : GestureEvent) : Nil
        @gesture_listeners.each do |listener|
          case gesture.type
          when GestureEvent::GestureType::Tap
            listener.on_tap(gesture)
          when GestureEvent::GestureType::DoubleTap
            listener.on_double_tap(gesture)
          when GestureEvent::GestureType::LongPress
            listener.on_long_press(gesture)
          when GestureEvent::GestureType::Pan
            listener.on_pan(gesture)
          when GestureEvent::GestureType::Pinch
            listener.on_pinch(gesture)
          when GestureEvent::GestureType::Rotate
            listener.on_rotate(gesture)
          when GestureEvent::GestureType::Swipe
            listener.on_swipe(gesture)
          end
        end
      end

      protected def dispatch_key(event : KeyEvent) : Nil
        @key_listeners.each do |listener|
          if event.is_pressed?
            listener.on_key_down(event)
          else
            listener.on_key_up(event)
          end
        end
      end
    end

    module TouchListener
      def on_touch_began(touch : Touch) : Nil
      end

      def on_touch_moved(touch : Touch) : Nil
      end

      def on_touch_ended(touch : Touch) : Nil
      end

      def on_touch_cancelled(touch : Touch) : Nil
      end
    end

    module GestureListener
      def on_tap(gesture : GestureEvent) : Nil
      end

      def on_double_tap(gesture : GestureEvent) : Nil
      end

      def on_long_press(gesture : GestureEvent) : Nil
      end

      def on_pan(gesture : GestureEvent) : Nil
      end

      def on_pinch(gesture : GestureEvent) : Nil
      end

      def on_rotate(gesture : GestureEvent) : Nil
      end

      def on_swipe(gesture : GestureEvent) : Nil
      end
    end

    module KeyListener
      def on_key_down(event : KeyEvent) : Nil
      end

      def on_key_up(event : KeyEvent) : Nil
      end
    end

    class GestureDetector
      @last_tap_time : Time = Time.utc(2000)
      @tap_count : Int32 = 0
      @touch_start_x : Float32 = 0.0
      @touch_start_y : Float32 = 0.0
      @touch_start_time : Time = Time.utc
      @long_press_triggered : Bool = false
      @last_touch : Touch? = nil

      def initialize(@listener : GestureListener)
      end

      def process_touch(touch : Touch, action : TouchAction) : Nil
        @last_touch = touch

        case action
        when TouchAction::Began
          @touch_start_x = touch.x
          @touch_start_y = touch.y
          @touch_start_time = Time.utc
          @long_press_triggered = false
          start_long_press_timer
          
        when TouchAction::Moved
          check_long_press(touch)
          check_pan(touch)
          
        when TouchAction::Ended
          check_tap(touch)
          check_swipe(touch)
          cancel_long_press
        end
      end

      private def start_long_press_timer : Nil
        spawn do
          sleep 0.5.seconds
          if !@long_press_triggered && @last_touch
            gesture = GestureEvent.new(GestureEvent::GestureType::LongPress)
            gesture.center_x = @touch_start_x
            gesture.center_y = @touch_start_y
            @listener.on_long_press(gesture)
            @long_press_triggered = true
          end
        end
      end

      private def cancel_long_press : Nil
        @long_press_triggered = true
      end

      private def check_long_press(touch : Touch) : Nil
        dx = (touch.x - @touch_start_x).abs
        dy = (touch.y - @touch_start_y).abs
        if dx > 10 || dy > 10
          @long_press_triggered = true
        end
      end

      private def check_pan(touch : Touch) : Nil
        dx = touch.x - @touch_start_x
        dy = touch.y - @touch_start_y
        if dx.abs > 10 || dy.abs > 10
          gesture = GestureEvent.new(GestureEvent::GestureType::Pan)
          gesture.center_x = touch.x
          gesture.center_y = touch.y
          gesture.velocity_x = dx
          gesture.velocity_y = dy
          @listener.on_pan(gesture)
        end
      end

      private def check_tap(touch : Touch) : Nil
        dx = (touch.x - @touch_start_x).abs
        dy = (touch.y - @touch_start_y).abs
        duration = Time.utc - @touch_start_time

        if dx < 20 && dy < 20 && duration < 0.3.seconds
          now = Time.utc
          if (now - @last_tap_time) < 0.3.seconds
            @tap_count += 1
            if @tap_count == 2
              gesture = GestureEvent.new(GestureEvent::GestureType::DoubleTap)
              gesture.center_x = touch.x
              gesture.center_y = touch.y
              @listener.on_double_tap(gesture)
              @tap_count = 0
            end
          else
            @tap_count = 1
            gesture = GestureEvent.new(GestureEvent::GestureType::Tap)
            gesture.center_x = touch.x
            gesture.center_y = touch.y
            @listener.on_tap(gesture)
          end
          @last_tap_time = now
        end
      end

      private def check_swipe(touch : Touch) : Nil
        dx = touch.x - @touch_start_x
        dy = touch.y - @touch_start_y
        duration = Time.utc - @touch_start_time

        if dx.abs > 100 && duration < 0.5.seconds
          gesture = GestureEvent.new(GestureEvent::GestureType::Swipe)
          gesture.center_x = touch.x
          gesture.center_y = touch.y
          gesture.velocity_x = dx / duration.total_seconds
          gesture.velocity_y = dy / duration.total_seconds
          @listener.on_swipe(gesture)
        end
      end
    end
  end
end
