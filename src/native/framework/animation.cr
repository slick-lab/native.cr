# src/native/framework/animation.cr

module Native
  module Animation
    enum Curve
      Linear
      EaseIn
      EaseOut
      EaseInOut
      Bounce
      Elastic
    end

    struct AnimationConfig
      property duration : Float64 = 0.3
      property delay : Float64 = 0.0
      property curve : Curve = Curve::EaseInOut
      property repeat_count : Int32 = 0
      property auto_reverse : Bool = false

      def initialize(@duration = 0.3, @delay = 0.0, @curve = Curve::EaseInOut,
                     @repeat_count = 0, @auto_reverse = false)
      end
    end

    abstract class Animator
      @start_time : Float64 = 0.0
      @is_running : Bool = false
      @is_paused : Bool = false
      @elapsed : Float64 = 0.0
      @repeat_count : Int32 = 0
      @current_repeat : Int32 = 0
      @direction : Int32 = 1

      def initialize(@config : AnimationConfig = AnimationConfig.new)
        @repeat_count = @config.repeat_count
      end

      def start : Nil
        @start_time = now
        @is_running = true
        @is_paused = false
        @elapsed = 0.0
        @current_repeat = 0
        @direction = 1
        on_start
      end

      def stop : Nil
        @is_running = false
        on_complete
      end

      def pause : Nil
        return unless @is_running
        @is_paused = true
      end

      def resume : Nil
        return unless @is_running && @is_paused
        @is_paused = false
        @start_time = now - @elapsed
      end

      def update(current_time : Float64) : Nil
        return unless @is_running && !@is_paused

        @elapsed = current_time - @start_time - @config.delay

        if @elapsed < 0
          return
        end

        duration = @config.duration
        t = (@elapsed / duration).clamp(0.0, 1.0)
        t = apply_curve(t)

        if @direction == 1
          apply(t)
        else
          apply(1.0 - t)
        end

        if @elapsed >= duration
          if @auto_reverse && @direction == 1
            @direction = -1
            @start_time = current_time
            @elapsed = 0.0
          elsif @auto_reverse && @direction == -1
            @direction = 1
            @current_repeat += 1
            @start_time = current_time
            @elapsed = 0.0
          else
            @current_repeat += 1
            @start_time = current_time
            @elapsed = 0.0
          end

          if @repeat_count > 0 && @current_repeat >= @repeat_count
            stop
          end
        end
      end

      private def apply_curve(t : Float64) : Float64
        case @config.curve
        when Curve::Linear
          t
        when Curve::EaseIn
          t * t
        when Curve::EaseOut
          t * (2.0 - t)
        when Curve::EaseInOut
          if t < 0.5
            2.0 * t * t
          else
            -1.0 + (4.0 - 2.0 * t) * t
          end
        when Curve::Bounce
          if t < (1.0 / 2.75)
            7.5625 * t * t
          elsif t < (2.0 / 2.75)
            t -= 1.5 / 2.75
            7.5625 * t * t + 0.75
          elsif t < (2.5 / 2.75)
            t -= 2.25 / 2.75
            7.5625 * t * t + 0.9375
          else
            t -= 2.625 / 2.75
            7.5625 * t * t + 0.984375
          end
        when Curve::Elastic
          if t == 0.0 || t == 1.0
            t
          else
            p = 0.3
            s = p / 4.0
            t - 1.0
            (2.0 ** (-10.0 * t)) * Math.sin((t - s) * (2.0 * Math::PI) / p) + 1.0
          end
        else
          t
        end
      end

      def is_running? : Bool
        @is_running && !@is_paused
      end

      protected abstract def apply(t : Float64) : Nil

      protected def on_start : Nil; end

      protected def on_complete : Nil; end

      private def now : Float64
        Time.utc.to_unix_f
      end
    end

    class ValueAnimator < Animator
      @start_value : Float64 = 0.0
      @end_value : Float64 = 1.0
      @current_value : Float64 = 0.0
      @on_update : (Float64 -> Nil)?

      def initialize(start_value : Float64 = 0.0, end_value : Float64 = 1.0,
                     config : AnimationConfig = AnimationConfig.new)
        super(config)
        @start_value = start_value
        @end_value = end_value
      end

      def on_update(&block : Float64 -> Nil) : Nil
        @on_update = block
      end

      protected def apply(t : Float64) : Nil
        @current_value = @start_value + (@end_value - @start_value) * t
        @on_update.try &.call(@current_value)
      end

      def current_value : Float64
        @current_value
      end
    end

    class ColorAnimator < Animator
      @start_r : UInt8
      @start_g : UInt8
      @start_b : UInt8
      @end_r : UInt8
      @end_g : UInt8
      @end_b : UInt8
      @on_update : (UInt8, UInt8, UInt8 -> Nil)?

      def initialize(start_color : Styling::Color, end_color : Styling::Color,
                     config : AnimationConfig = AnimationConfig.new)
        super(config)
        @start_r = start_color.r
        @start_g = start_color.g
        @start_b = start_color.b
        @end_r = end_color.r
        @end_g = end_color.g
        @end_b = end_color.b
      end

      def on_update(&block : UInt8, UInt8, UInt8 -> Nil) : Nil
        @on_update = block
      end

      protected def apply(t : Float64) : Nil
        r = (@start_r + (@end_r - @start_r) * t).to_u8
        g = (@start_g + (@end_g - @start_g) * t).to_u8
        b = (@start_b + (@end_b - @start_b) * t).to_u8
        @on_update.try &.call(r, g, b)
      end
    end

    class TransformAnimator < Animator
      @start_x : Int32
      @start_y : Int32
      @end_x : Int32
      @end_y : Int32
      @view : UI::View?
      @on_update : (Int32, Int32 -> Nil)?

      def initialize(view : UI::View, end_x : Int32, end_y : Int32,
                     config : AnimationConfig = AnimationConfig.new)
        super(config)
        @view = view
        @start_x = view.x
        @start_y = view.y
        @end_x = end_x
        @end_y = end_y
      end

      def on_update(&block : Int32, Int32 -> Nil) : Nil
        @on_update = block
      end

      protected def apply(t : Float64) : Nil
        x = (@start_x + (@end_x - @start_x) * t).to_i
        y = (@start_y + (@end_y - @start_y) * t).to_i

        if @view
          @view.not_nil!.x = x
          @view.not_nil!.y = y
        end

        @on_update.try &.call(x, y)
      end
    end

    class SequenceAnimator < Animator
      @animators : Array(Animator) = [] of Animator
      @current_index : Int32 = 0

      def add(animator : Animator) : Nil
        @animators << animator
      end

      def start : Nil
        @current_index = 0
        start_current
      end

      private def start_current : Nil
        return if @current_index >= @animators.size
        @animators[@current_index].on_complete do
          @current_index += 1
          start_current
        end
        @animators[@current_index].start
      end

      protected def apply(t : Float64) : Nil
        # Sequence uses individual animators
      end
    end

    class ParallelAnimator < Animator
      @animators : Array(Animator) = [] of Animator

      def add(animator : Animator) : Nil
        @animators << animator
      end

      def start : Nil
        @animators.each(&.start)
      end

      protected def apply(t : Float64) : Nil
        # Parallel uses individual animators
      end
    end

    module AnimationDSL
      def animate(duration : Float64 = 0.3, curve : Curve = Curve::EaseInOut, &)
        config = AnimationConfig.new(duration: duration, curve: curve)
        yield AnimationBuilder.new(config)
      end

      class AnimationBuilder
        def initialize(@config : AnimationConfig)
          @animations = [] of Animator
        end

        def move(view : UI::View, x : Int32, y : Int32) : Nil
          anim = TransformAnimator.new(view, x, y, @config)
          @animations << anim
        end

        def fade(view : UI::View, alpha : Float32) : Nil
          anim = ValueAnimator.new(view.alpha.to_f64, alpha.to_f64, @config)
          anim.on_update { |v| view.alpha = v.to_f32 }
          @animations << anim
        end

        def color(view : UI::View, color : Styling::Color) : Nil
          anim = ColorAnimator.new(
            Styling::Color.new(view.background_r, view.background_g, view.background_b),
            color,
            @config
          )
          anim.on_update { |r, g, b| view.background_color = Styling::Color.new(r, g, b) }
          @animations << anim
        end

        def scale(view : UI::View, scale_x : Float64, scale_y : Float64) : Nil
          anim = ValueAnimator.new(1.0, scale_x, @config)
          anim.on_update { |v| view.scale = v.to_f32 }
          @animations << anim
        end

        def then
          seq = SequenceAnimator.new(@config)
          @animations.each { |a| seq.add(a) }
          seq.start
        end

        def all
          parallel = ParallelAnimator.new(@config)
          @animations.each { |a| parallel.add(a) }
          parallel.start
        end
      end
    end

    class AnimationManager
      @animators : Array(Animator) = [] of Animator
      @previous_time : Float64 = 0.0

      def initialize
        @previous_time = now
      end

      def add(animator : Animator) : Nil
        @animators << animator
        animator.start
      end

      def remove(animator : Animator) : Nil
        @animators.delete(animator)
      end

      def update : Nil
        current_time = now
        delta = current_time - @previous_time
        @previous_time = current_time

        @animators.each do |animator|
          animator.update(current_time)
        end

        @animators.reject! { |a| !a.is_running? }
      end

      def clear : Nil
        @animators.clear
      end

      private def now : Float64
        Time.utc.to_unix_f
      end
    end
  end
end
