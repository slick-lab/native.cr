# src/native/framework/gesture.cr

module Native
  module Gesture
    enum GestureState
      Possible
      Began
      Changed
      Ended
      Cancelled
      Failed
    end

    struct Point
      property x : Float64
      property y : Float64

      def initialize(@x = 0.0, @y = 0.0)
      end

      def distance_to(other : Point) : Float64
        dx = @x - other.x
        dy = @y - other.y
        Math.sqrt(dx * dx + dy * dy)
      end
    end

    class TapGestureRecognizer
      @state : GestureState = GestureState::Possible
      @number_of_taps_required : Int32 = 1
      @number_of_touches_required : Int32 = 1
      @start_point : Point = Point.new
      @current_point : Point = Point.new
      @tap_count : Int32 = 0
      @last_tap_time : Float64 = 0.0
      @on_tap : (Point -> Nil)?
      @on_state_change : (GestureState -> Nil)?

      def initialize
      end

      def number_of_taps_required=(value : Int32)
        @number_of_taps_required = value
      end

      def number_of_touches_required=(value : Int32)
        @number_of_touches_required = value
      end

      def on_tap(&block : Point -> Nil) : Nil
        @on_tap = block
      end

      def on_state_change(&block : GestureState -> Nil) : Nil
        @on_state_change = block
      end

      def touches_began(touches : Array(Point)) : Nil
        return if touches.size != @number_of_touches_required

        @start_point = touches.first
        @current_point = touches.first
        @state = GestureState::Began
        @on_state_change.try &.call(@state)
      end

      def touches_moved(touches : Array(Point)) : Nil
        return unless @state == GestureState::Began || @state == GestureState::Changed

        @current_point = touches.first
        distance = @start_point.distance_to(@current_point)

        if distance > 10
          @state = GestureState::Failed
          @on_state_change.try &.call(@state)
        else
          @state = GestureState::Changed
          @on_state_change.try &.call(@state)
        end
      end

      def touches_ended(touches : Array(Point)) : Nil
        return unless @state == GestureState::Began || @state == GestureState::Changed

        now = Time.utc.to_unix_f
        if now - @last_tap_time < 0.3
          @tap_count += 1
        else
          @tap_count = 1
        end
        @last_tap_time = now

        if @tap_count >= @number_of_taps_required
          @state = GestureState::Ended
          @on_tap.try &.call(@current_point)
          @on_state_change.try &.call(@state)
          @tap_count = 0
        end
      end

      def touches_cancelled(touches : Array(Point)) : Nil
        @state = GestureState::Cancelled
        @on_state_change.try &.call(@state)
        @tap_count = 0
      end

      def reset : Nil
        @state = GestureState::Possible
      end
    end

    class LongPressGestureRecognizer
      @state : GestureState = GestureState::Possible
      @minimum_press_duration : Float64 = 0.5
      @allowable_movement : Float64 = 10.0
      @start_point : Point = Point.new
      @current_point : Point = Point.new
      @press_timer : Time? = nil
      @on_long_press : (Point -> Nil)?
      @on_state_change : (GestureState -> Nil)?

      def initialize
      end

      def minimum_press_duration=(value : Float64)
        @minimum_press_duration = value
      end

      def on_long_press(&block : Point -> Nil) : Nil
        @on_long_press = block
      end

      def on_state_change(&block : GestureState -> Nil) : Nil
        @on_state_change = block
      end

      def touches_began(touches : Array(Point)) : Nil
        @start_point = touches.first
        @current_point = touches.first
        @state = GestureState::Began
        @on_state_change.try &.call(@state)

        start_timer
      end

      def touches_moved(touches : Array(Point)) : Nil
        return unless @state == GestureState::Began || @state == GestureState::Changed

        @current_point = touches.first
        distance = @start_point.distance_to(@current_point)

        if distance > @allowable_movement
          cancel_timer
          @state = GestureState::Failed
          @on_state_change.try &.call(@state)
        else
          @state = GestureState::Changed
          @on_state_change.try &.call(@state)
        end
      end

      def touches_ended(touches : Array(Point)) : Nil
        cancel_timer
        @state = GestureState::Ended
        @on_state_change.try &.call(@state)
      end

      def touches_cancelled(touches : Array(Point)) : Nil
        cancel_timer
        @state = GestureState::Cancelled
        @on_state_change.try &.call(@state)
      end

      def reset : Nil
        @state = GestureState::Possible
        cancel_timer
      end

      private def start_timer : Nil
        spawn do
          sleep @minimum_press_duration.seconds
          if @state == GestureState::Began
            @state = GestureState::Ended
            @on_long_press.try &.call(@current_point)
            @on_state_change.try &.call(@state)
          end
        end
      end

      private def cancel_timer : Nil
        # Timer will be cancelled when sleep finishes and state check fails
      end
    end

    class PanGestureRecognizer
      @state : GestureState = GestureState::Possible
      @minimum_touches : Int32 = 1
      @maximum_touches : Int32 = 1
      @start_point : Point = Point.new
      @previous_point : Point = Point.new
      @current_point : Point = Point.new
      @translation : Point = Point.new
      @velocity : Point = Point.new
      @last_time : Float64 = 0.0
      @on_pan : (Point, Point, Point -> Nil)?
      @on_state_change : (GestureState -> Nil)?

      def initialize
      end

      def on_pan(&block : Point, Point, Point -> Nil) : Nil
        @on_pan = block
      end

      def on_state_change(&block : GestureState -> Nil) : Nil
        @on_state_change = block
      end

      def translation : Point
        @translation
      end

      def velocity : Point
        @velocity
      end

      def touches_began(touches : Array(Point)) : Nil
        @start_point = touches.first
        @previous_point = touches.first
        @current_point = touches.first
        @translation = Point.new
        @state = GestureState::Began
        @on_state_change.try &.call(@state)
        @last_time = Time.utc.to_unix_f
      end

      def touches_moved(touches : Array(Point)) : Nil
        @current_point = touches.first
        @translation = Point.new(
          @current_point.x - @start_point.x,
          @current_point.y - @start_point.y
        )

        now = Time.utc.to_unix_f
        delta_time = now - @last_time
        if delta_time > 0
          @velocity = Point.new(
            (@current_point.x - @previous_point.x) / delta_time,
            (@current_point.y - @previous_point.y) / delta_time
          )
        end

        @state = GestureState::Changed
        @on_pan.try &.call(@translation, @velocity, @current_point)
        @on_state_change.try &.call(@state)

        @previous_point = @current_point
        @last_time = now
      end

      def touches_ended(touches : Array(Point)) : Nil
        @state = GestureState::Ended
        @on_pan.try &.call(@translation, @velocity, @current_point)
        @on_state_change.try &.call(@state)
      end

      def touches_cancelled(touches : Array(Point)) : Nil
        @state = GestureState::Cancelled
        @on_state_change.try &.call(@state)
      end

      def reset : Nil
        @state = GestureState::Possible
        @translation = Point.new
        @velocity = Point.new
      end
    end

    class PinchGestureRecognizer
      @state : GestureState = GestureState::Possible
      @start_distance : Float64 = 0.0
      @current_distance : Float64 = 0.0
      @scale : Float64 = 1.0
      @start_scale : Float64 = 1.0
      @on_pinch : (Float64, Point -> Nil)?
      @on_state_change : (GestureState -> Nil)?

      def initialize
      end

      def on_pinch(&block : Float64, Point -> Nil) : Nil
        @on_pinch = block
      end

      def on_state_change(&block : GestureState -> Nil) : Nil
        @on_state_change = block
      end

      def scale : Float64
        @scale
      end

      def touches_began(touches : Array(Point)) : Nil
        return if touches.size < 2

        @start_distance = distance_between(touches[0], touches[1])
        @current_distance = @start_distance
        @start_scale = @scale
        @state = GestureState::Began
        @on_state_change.try &.call(@state)
      end

      def touches_moved(touches : Array(Point)) : Nil
        return if touches.size < 2

        @current_distance = distance_between(touches[0], touches[1])
        @scale = @start_scale * (@current_distance / @start_distance)

        center = Point.new(
          (touches[0].x + touches[1].x) / 2,
          (touches[0].y + touches[1].y) / 2
        )

        @state = GestureState::Changed
        @on_pinch.try &.call(@scale, center)
        @on_state_change.try &.call(@state)
      end

      def touches_ended(touches : Array(Point)) : Nil
        @state = GestureState::Ended
        @on_pinch.try &.call(@scale, Point.new)
        @on_state_change.try &.call(@state)
      end

      def touches_cancelled(touches : Array(Point)) : Nil
        @state = GestureState::Cancelled
        @on_state_change.try &.call(@state)
      end

      def reset : Nil
        @state = GestureState::Possible
        @scale = 1.0
      end

      private def distance_between(p1 : Point, p2 : Point) : Float64
        dx = p1.x - p2.x
        dy = p1.y - p2.y
        Math.sqrt(dx * dx + dy * dy)
      end
    end

    class RotationGestureRecognizer
      @state : GestureState = GestureState::Possible
      @start_angle : Float64 = 0.0
      @current_angle : Float64 = 0.0
      @rotation : Float64 = 0.0
      @start_rotation : Float64 = 0.0
      @on_rotate : (Float64, Point -> Nil)?
      @on_state_change : (GestureState -> Nil)?

      def initialize
      end

      def on_rotate(&block : Float64, Point -> Nil) : Nil
        @on_rotate = block
      end

      def rotation : Float64
        @rotation
      end

      def touches_began(touches : Array(Point)) : Nil
        return if touches.size < 2

        @start_angle = angle_between(touches[0], touches[1])
        @current_angle = @start_angle
        @start_rotation = @rotation
        @state = GestureState::Began
        @on_state_change.try &.call(@state)
      end

      def touches_moved(touches : Array(Point)) : Nil
        return if touches.size < 2

        @current_angle = angle_between(touches[0], touches[1])
        @rotation = @start_rotation + (@current_angle - @start_angle)

        center = Point.new(
          (touches[0].x + touches[1].x) / 2,
          (touches[0].y + touches[1].y) / 2
        )

        @state = GestureState::Changed
        @on_rotate.try &.call(@rotation, center)
        @on_state_change.try &.call(@state)
      end

      def touches_ended(touches : Array(Point)) : Nil
        @state = GestureState::Ended
        @on_rotate.try &.call(@rotation, Point.new)
        @on_state_change.try &.call(@state)
      end

      def reset : Nil
        @state = GestureState::Possible
      end

      private def angle_between(p1 : Point, p2 : Point) : Float64
        Math.atan2(p2.y - p1.y, p2.x - p1.x)
      end
    end

    class SwipeGestureRecognizer
      @state : GestureState = GestureState::Possible
      @direction : Int32 = 0
      @minimum_distance : Float64 = 50.0
      @maximum_duration : Float64 = 0.5
      @start_point : Point = Point.new
      @start_time : Float64 = 0.0
      @on_swipe : (Int32 -> Nil)?
      @on_state_change : (GestureState -> Nil)?

      def initialize
      end

      def on_swipe(&block : Int32 -> Nil) : Nil
        @on_swipe = block
      end

      def touches_began(touches : Array(Point)) : Nil
        @start_point = touches.first
        @start_time = Time.utc.to_unix_f
        @state = GestureState::Began
        @on_state_change.try &.call(@state)
      end

      def touches_ended(touches : Array(Point)) : Nil
        end_point = touches.first
        end_time = Time.utc.to_unix_f

        dx = end_point.x - @start_point.x
        dy = end_point.y - @start_point.y
        distance = Math.sqrt(dx * dx + dy * dy)
        duration = end_time - @start_time

        if distance >= @minimum_distance && duration <= @maximum_duration
          if dx.abs > dy.abs
            @direction = dx > 0 ? 1 : 2
          else
            @direction = dy > 0 ? 3 : 4
          end

          @state = GestureState::Ended
          @on_swipe.try &.call(@direction)
          @on_state_change.try &.call(@state)
        else
          @state = GestureState::Failed
          @on_state_change.try &.call(@state)
        end
      end

      def reset : Nil
        @state = GestureState::Possible
      end
    end

    class GestureView < UI::View
      @tap_recognizer : TapGestureRecognizer?
      @long_press_recognizer : LongPressGestureRecognizer?
      @pan_recognizer : PanGestureRecognizer?
      @pinch_recognizer : PinchGestureRecognizer?
      @rotation_recognizer : RotationGestureRecognizer?
      @swipe_recognizer : SwipeGestureRecognizer?
      @active_touches : Array(Point) = [] of Point

      def initialize
        super
      end

      def add_tap_gesture(taps : Int32 = 1, &block : Point -> Nil) : Nil
        @tap_recognizer = TapGestureRecognizer.new
        @tap_recognizer.not_nil!.number_of_taps_required = taps
        @tap_recognizer.not_nil!.on_tap(&block)
      end

      def add_long_press_gesture(duration : Float64 = 0.5, &block : Point -> Nil) : Nil
        @long_press_recognizer = LongPressGestureRecognizer.new
        @long_press_recognizer.not_nil!.minimum_press_duration = duration
        @long_press_recognizer.not_nil!.on_long_press(&block)
      end

      def add_pan_gesture(&block : Point, Point, Point -> Nil) : Nil
        @pan_recognizer = PanGestureRecognizer.new
        @pan_recognizer.not_nil!.on_pan(&block)
      end

      def add_pinch_gesture(&block : Float64, Point -> Nil) : Nil
        @pinch_recognizer = PinchGestureRecognizer.new
        @pinch_recognizer.not_nil!.on_pinch(&block)
      end

      def add_rotation_gesture(&block : Float64, Point -> Nil) : Nil
        @rotation_recognizer = RotationGestureRecognizer.new
        @rotation_recognizer.not_nil!.on_rotate(&block)
      end

      def add_swipe_gesture(&block : Int32 -> Nil) : Nil
        @swipe_recognizer = SwipeGestureRecognizer.new
        @swipe_recognizer.not_nil!.on_swipe(&block)
      end

      def on_touch_began(x : Int32, y : Int32) : Bool
        point = Point.new(x.to_f64, y.to_f64)
        @active_touches << point

        @tap_recognizer.try(&.touches_began([point]))
        @long_press_recognizer.try(&.touches_began([point]))
        @pan_recognizer.try(&.touches_began([point]))
        @pinch_recognizer.try(&.touches_began(@active_touches))
        @rotation_recognizer.try(&.touches_began(@active_touches))
        @swipe_recognizer.try(&.touches_began([point]))

        true
      end

      def on_touch_moved(x : Int32, y : Int32) : Bool
        point = Point.new(x.to_f64, y.to_f64)

        @tap_recognizer.try(&.touches_moved([point]))
        @long_press_recognizer.try(&.touches_moved([point]))
        @pan_recognizer.try(&.touches_moved([point]))
        @pinch_recognizer.try(&.touches_moved(@active_touches))
        @rotation_recognizer.try(&.touches_moved(@active_touches))

        true
      end

      def on_touch_ended(x : Int32, y : Int32) : Bool
        point = Point.new(x.to_f64, y.to_f64)
        @active_touches.pop

        @tap_recognizer.try(&.touches_ended([point]))
        @long_press_recognizer.try(&.touches_ended([point]))
        @pan_recognizer.try(&.touches_ended([point]))
        @pinch_recognizer.try(&.touches_ended(@active_touches))
        @rotation_recognizer.try(&.touches_ended(@active_touches))
        @swipe_recognizer.try(&.touches_ended([point]))

        true
      end

      def on_touch_cancelled(x : Int32, y : Int32) : Bool
        point = Point.new(x.to_f64, y.to_f64)
        @active_touches.clear

        @tap_recognizer.try(&.touches_cancelled([point]))
        @long_press_recognizer.try(&.touches_cancelled([point]))
        @pan_recognizer.try(&.touches_cancelled([point]))
        @pinch_recognizer.try(&.touches_cancelled(@active_touches))
        @rotation_recognizer.try(&.touches_cancelled(@active_touches))
        @swipe_recognizer.try(&.touches_cancelled([point]))

        true
      end
    end
  end
end
