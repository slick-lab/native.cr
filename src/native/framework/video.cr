# src/native/framework/video.cr

module Native
  module Video
    enum VideoState
      Idle
      Loading
      Playing
      Paused
      Buffering
      Ended
      Error
    end

    struct VideoConfig
      property auto_play : Bool = false
      property loop : Bool = false
      property muted : Bool = false
      property volume : Float32 = 1.0
      property controls : Bool = true
      property fill_mode : String = "contain"

      def initialize
      end
    end

    class VideoView < UI::View
      @config : VideoConfig
      @video_ptr : Void*? = nil
      @state : VideoState = VideoState::Idle
      @duration : Float64 = 0.0
      @current_time : Float64 = 0.0
      @on_ready : ( -> Nil)?
      @on_complete : ( -> Nil)?
      @on_error : (String -> Nil)?
      @on_time_update : (Float64 -> Nil)?
      @on_state_change : (VideoState -> Nil)?

      def initialize(config : VideoConfig = VideoConfig.new)
        super()
        @config = config
        @width = 320
        @height = 240
      end

      def load(path : String) : Bool
        {% if flag?(:android) %}
          @video_ptr = LibVideo.android_create_video_view(
            absolute_x, absolute_y, @width, @height,
            path.to_utf8,
            @config.auto_play,
            @config.loop,
            @config.muted
          )
        {% elsif flag?(:ios) %}
          @video_ptr = LibVideo.ios_create_video_view(
            absolute_x, absolute_y, @width, @height,
            path.to_utf8,
            @config.auto_play,
            @config.loop
          )
        {% else %}
          return false
        {% end %}

        if @video_ptr
          setup_callbacks
          @state = VideoState::Loading
          @on_state_change.try &.call(@state)
          true
        else
          false
        end
      end

      def load(url : String) : Bool
        load(url)
      end

      def play : Nil
        return unless @video_ptr && @state != VideoState::Playing

        {% if flag?(:android) %}
          LibVideo.android_video_play(@video_ptr)
        {% elsif flag?(:ios) %}
          LibVideo.ios_video_play(@video_ptr)
        {% end %}

        @state = VideoState::Playing
        @on_state_change.try &.call(@state)
      end

      def pause : Nil
        return unless @video_ptr && @state == VideoState::Playing

        {% if flag?(:android) %}
          LibVideo.android_video_pause(@video_ptr)
        {% elsif flag?(:ios) %}
          LibVideo.ios_video_pause(@video_ptr)
        {% end %}

        @state = VideoState::Paused
        @on_state_change.try &.call(@state)
      end

      def stop : Nil
        return unless @video_ptr

        {% if flag?(:android) %}
          LibVideo.android_video_stop(@video_ptr)
        {% elsif flag?(:ios) %}
          LibVideo.ios_video_stop(@video_ptr)
        {% end %}

        @state = VideoState::Idle
        @on_state_change.try &.call(@state)
      end

      def seek(time : Float64) : Nil
        return unless @video_ptr

        {% if flag?(:android) %}
          LibVideo.android_video_seek(@video_ptr, time)
        {% elsif flag?(:ios) %}
          LibVideo.ios_video_seek(@video_ptr, time)
        {% end %}
      end

      def volume=(value : Float32)
        @config.volume = value.clamp(0.0, 1.0)
        return unless @video_ptr

        {% if flag?(:android) %}
          LibVideo.android_video_set_volume(@video_ptr, @config.volume)
        {% elsif flag?(:ios) %}
          LibVideo.ios_video_set_volume(@video_ptr, @config.volume)
        {% end %}
      end

      def volume : Float32
        @config.volume
      end

      def muted=(value : Bool)
        @config.muted = value
        return unless @video_ptr

        {% if flag?(:android) %}
          LibVideo.android_video_set_muted(@video_ptr, value)
        {% end %}
      end

      def muted? : Bool
        @config.muted
      end

      def duration : Float64
        @duration
      end

      def current_time : Float64
        @current_time
      end

      def state : VideoState
        @state
      end

      def playing? : Bool
        @state == VideoState::Playing
      end

      def paused? : Bool
        @state == VideoState::Paused
      end

      def on_ready(&block : -> Nil) : Nil
        @on_ready = block
      end

      def on_complete(&block : -> Nil) : Nil
        @on_complete = block
      end

      def on_error(&block : String -> Nil) : Nil
        @on_error = block
      end

      def on_time_update(&block : Float64 -> Nil) : Nil
        @on_time_update = block
      end

      def on_state_change(&block : VideoState -> Nil) : Nil
        @on_state_change = block
      end

      def layout(x : Int32, y : Int32, width : Int32, height : Int32) : Nil
        super(x, y, width, height)
        update_native_frame
      end

      def draw(renderer : Void*) : Nil
        return unless @visible
        # Video draws itself natively
        update_native_frame
      end

      private def update_native_frame : Nil
        return unless @video_ptr

        {% if flag?(:android) %}
          LibVideo.android_video_set_frame(@video_ptr, absolute_x, absolute_y, @width, @height)
        {% elsif flag?(:ios) %}
          LibVideo.ios_video_set_frame(@video_ptr, absolute_x, absolute_y, @width, @height)
        {% end %}
      end

      private def setup_callbacks : Nil
        {% if flag?(:android) %}
          LibVideo.android_video_set_callbacks(
            @video_ptr,
            -> { handle_ready },
            -> { handle_complete },
            ->(error_ptr : UInt8*) { handle_error(error_ptr) },
            ->(time : Float64) { handle_time_update(time) }
          )
        {% elsif flag?(:ios) %}
          LibVideo.ios_video_set_callbacks(
            @video_ptr,
            -> { handle_ready },
            -> { handle_complete },
            ->(error_ptr : UInt8*) { handle_error(error_ptr) },
            ->(time : Float64) { handle_time_update(time) }
          )
        {% end %}
      end

      private def handle_ready : Nil
        @state = VideoState::Idle
        @duration = {% if flag?(:android) %}
          LibVideo.android_video_get_duration(@video_ptr)
        {% else %}
          0.0
        {% end %}
        @on_ready.try &.call
        @on_state_change.try &.call(@state)

        if @config.auto_play
          play
        end
      end

      private def handle_complete : Nil
        @state = VideoState::Ended
        @on_complete.try &.call
        @on_state_change.try &.call(@state)
      end

      private def handle_error(error_ptr : UInt8*) : Nil
        @state = VideoState::Error
        error_message = String.new(error_ptr)
        @on_error.try &.call(error_message)
        @on_state_change.try &.call(@state)
        LibVideo.free_string(error_ptr)
      end

      private def handle_time_update(time : Float64) : Nil
        @current_time = time
        @on_time_update.try &.call(time)
      end
    end

    class VideoPlayer < VideoView
      @play_button : UI::Button?
      @progress_slider : UI::View?
      @time_label : UI::Text?

      def initialize(config : VideoConfig = VideoConfig.new)
        super(config)
        @config.controls = true
        
        if @config.controls
          setup_controls
        end
      end

      private def setup_controls : Nil
        @play_button = UI::Button.new
        @play_button.not_nil!.text = "▶"
        @play_button.not_nil!.width = 44
        @play_button.not_nil!.height = 44
        @play_button.not_nil!.x = @width // 2 - 22
        @play_button.not_nil!.y = @height // 2 - 22
        @play_button.not_nil!.on_click = ->{ toggle_play_pause }
        add_child(@play_button.not_nil!)
      end

      private def toggle_play_pause : Nil
        if playing?
          pause
          @play_button.try(&.text = "▶")
        else
          play
          @play_button.try(&.text = "⏸")
        end
      end
    end
  end
end
