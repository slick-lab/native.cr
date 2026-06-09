# src/native/framework/game_loop.cr

module Native::GameLoop
  enum LoopMode
    Fixed
    Variable
    Adaptive
  end

  struct LoopConfig
    property mode : LoopMode = LoopMode::Adaptive
    property target_fps : Int32 = 60
    property fixed_update_rate : Float64 = 1.0 / 60.0
    property max_frame_time : Float64 = 0.25

    def initialize
    end
  end

  class GameLoop
    @is_running : Bool = false
    @is_paused : Bool = false
    @config : LoopConfig
    @last_time : Float64 = 0.0
    @accumulator : Float64 = 0.0
    @frame_count : Int64 = 0
    @fps : Float64 = 0.0
    @delta_time : Float64 = 0.0
    @frame_times : Array(Float64) = [] of Float64
    @on_update : (Float64 -> Nil)?
    @on_fixed_update : (Float64 -> Nil)?
    @on_render : (Float64 -> Nil)?
    @on_start : ( -> Nil)?
    @on_pause : ( -> Nil)?
    @on_resume : ( -> Nil)?
    @on_stop : ( -> Nil)?

    def initialize(@config : LoopConfig = LoopConfig.new)
    end

    def start : Nil
      return if @is_running

      @is_running = true
      @is_paused = false
      @last_time = now
      @accumulator = 0.0
      @frame_count = 0
      @frame_times.clear

      @on_start.try &.call

      spawn do
        while @is_running
          update_loop
          sleep(0.001)
        end
      end
    end

    def stop : Nil
      @is_running = false
      @on_stop.try &.call
    end

    def pause : Nil
      return if @is_paused
      @is_paused = true
      @on_pause.try &.call
    end

    def resume : Nil
      return unless @is_paused
      @is_paused = false
      @last_time = now
      @on_resume.try &.call
    end

    def on_start(&block : -> Nil) : Nil
      @on_start = block
    end

    def on_update(&block : Float64 -> Nil) : Nil
      @on_update = block
    end

    def on_fixed_update(&block : Float64 -> Nil) : Nil
      @on_fixed_update = block
    end

    def on_render(&block : Float64 -> Nil) : Nil
      @on_render = block
    end

    def on_pause(&block : -> Nil) : Nil
      @on_pause = block
    end

    def on_resume(&block : -> Nil) : Nil
      @on_resume = block
    end

    def on_stop(&block : -> Nil) : Nil
      @on_stop = block
    end

    def is_running? : Bool
      @is_running
    end

    def is_paused? : Bool
      @is_paused
    end

    def fps : Float64
      @fps
    end

    def delta_time : Float64
      @delta_time
    end

    def frame_count : Int64
      @frame_count
    end

    def target_fps=(value : Int32)
      @config.target_fps = value
    end

    def target_fps : Int32
      @config.target_fps
    end

    private def update_loop : Nil
      return if @is_paused

      current_time = now
      frame_time = current_time - @last_time
      @last_time = current_time

      if frame_time > @config.max_frame_time
        frame_time = @config.max_frame_time
      end

      @delta_time = frame_time

      case @config.mode
      when LoopMode::Fixed
        fixed_update_loop(frame_time)
      when LoopMode::Variable
        variable_update_loop(frame_time)
      when LoopMode::Adaptive
        adaptive_update_loop(frame_time)
      end

      calculate_fps(frame_time)
      @frame_count += 1
    end

    private def fixed_update_loop(frame_time : Float64) : Nil
      @accumulator += frame_time
      fixed_delta = @config.fixed_update_rate

      while @accumulator >= fixed_delta
        @on_fixed_update.try &.call(fixed_delta)
        @accumulator -= fixed_delta
      end

      alpha = @accumulator / fixed_delta
      @on_update.try &.call(@delta_time) if @on_update
      @on_render.try &.call(alpha) if @on_render
    end

    private def variable_update_loop(frame_time : Float64) : Nil
      @on_update.try &.call(frame_time)
      @on_fixed_update.try &.call(frame_time)
      @on_render.try &.call(frame_time)
    end

    private def adaptive_update_loop(frame_time : Float64) : Nil
      target_frame_time = 1.0 / @config.target_fps

      @on_update.try &.call(frame_time)
      @on_fixed_update.try &.call(frame_time)

      if frame_time <= target_frame_time
        sleep(target_frame_time - frame_time)
      end

      @on_render.try &.call(frame_time)
    end

    private def calculate_fps(frame_time : Float64) : Nil
      @frame_times << frame_time
      if @frame_times.size > 60
        @frame_times.shift
        avg = @frame_times.sum / @frame_times.size
        @fps = 1.0 / avg
      end
    end

    private def now : Float64
      Time.utc.to_unix_f
    end
  end

  class FixedGameLoop < GameLoop
    def initialize(target_fps : Int32 = 60)
      config = LoopConfig.new
      config.mode = LoopMode::Fixed
      config.target_fps = target_fps
      config.fixed_update_rate = 1.0 / target_fps
      super(config)
    end
  end

  class VariableGameLoop < GameLoop
    def initialize(target_fps : Int32 = 60)
      config = LoopConfig.new
      config.mode = LoopMode::Variable
      config.target_fps = target_fps
      super(config)
    end
  end

  module GameLoopDSL
    def game_loop(target_fps : Int32 = 60, mode : LoopMode = LoopMode::Adaptive)
      @__game_loop = GameLoop.new(LoopConfig.new(mode: mode, target_fps: target_fps))

      @__game_loop.on_start do
        game_start if responds_to?(:game_start)
      end

      @__game_loop.on_update do |delta|
        game_update(delta) if responds_to?(:game_update)
      end

      @__game_loop.on_fixed_update do |delta|
        game_fixed_update(delta) if responds_to?(:game_fixed_update)
      end

      @__game_loop.on_render do |alpha|
        game_render(alpha) if responds_to?(:game_render)
      end

      @__game_loop.on_pause do
        game_pause if responds_to?(:game_pause)
      end

      @__game_loop.on_resume do
        game_resume if responds_to?(:game_resume)
      end

      @__game_loop.on_stop do
        game_stop if responds_to?(:game_stop)
      end

      @__game_loop.start
    end

    def pause_game : Nil
      @__game_loop.try(&.pause)
    end

    def resume_game : Nil
      @__game_loop.try(&.resume)
    end

    def stop_game : Nil
      @__game_loop.try(&.stop)
    end

    def game_fps : Float64
      @__game_loop.try(&.fps) || 0.0
    end

    def game_delta : Float64
      @__game_loop.try(&.delta_time) || 0.0
    end
  end
end
