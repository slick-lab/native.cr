# src/native/framework/text.cr

module Native
  module Text
    enum KeyboardType
      Default
      Email
      Number
      Phone
      Decimal
      Url
      Ascii
    end

    enum ReturnKeyType
      Done
      Go
      Search
      Send
      Next
      Continue
      Join
      Route
      EmergencyCall
    end

    enum TextAlignment
      Left
      Center
      Right
    end

    struct TextInputConfig
      property placeholder : String = ""
      property placeholder_color : Styling::Color = Styling::Color.gray(150)
      property max_length : Int32 = 0
      property keyboard_type : KeyboardType = KeyboardType::Default
      property return_key_type : ReturnKeyType = ReturnKeyType::Done
      property secure : Bool = false
      property multiline : Bool = false
      property auto_capitalize : Bool = true
      property auto_correct : Bool = true
      property enabled : Bool = true
      property text_color : Styling::Color = Styling::Color.black
      property background_color : Styling::Color = Styling::Color.white
      property border_color : Styling::Color = Styling::Color.gray(200)
      property border_width : Int32 = 1
      property corner_radius : Int32 = 8
      property padding : Int32 = 12
      property font_size : Int32 = 16

      def initialize
      end
    end

    class TextInput < UI::View
      @config : TextInputConfig
      @text : String = ""
      @is_focused : Bool = false
      @native_input_ptr : Void*? = nil
      @on_change : (String -> Nil)?
      @on_submit : (String -> Nil)?
      @on_focus : ( -> Nil)?
      @on_blur : ( -> Nil)?

      def initialize(config : TextInputConfig = TextInputConfig.new)
        super()
        @config = config
        @width = 200
        @height = 44
        
        create_native_input
      end

      def text : String
        @text
      end

      def text=(value : String)
        @text = value
        update_native_text
      end

      def placeholder : String
        @config.placeholder
      end

      def placeholder=(value : String)
        @config.placeholder = value
        update_native_placeholder
      end

      def focus : Nil
        return unless @config.enabled
        
        {% if flag?(:android) }}
          LibTextInput.android_focus(@native_input_ptr)
        {% elsif flag?(:ios) }}
          LibTextInput.ios_focus(@native_input_ptr)
        {% end }}
      end

      def blur : Nil
        {% if flag?(:android) }}
          LibTextInput.android_blur(@native_input_ptr)
        {% elsif flag?(:ios) }}
          LibTextInput.ios_blur(@native_input_ptr)
        {% end }}
      end

      def clear : Nil
        self.text = ""
      end

      def enabled? : Bool
        @config.enabled
      end

      def enabled=(value : Bool)
        @config.enabled = value
        {% if flag?(:android) }}
          LibTextInput.android_set_enabled(@native_input_ptr, value)
        {% elsif flag?(:ios) }}
          LibTextInput.ios_set_enabled(@native_input_ptr, value)
        {% end }}
      end

      def on_change(&block : String -> Nil) : Nil
        @on_change = block
      end

      def on_submit(&block : String -> Nil) : Nil
        @on_submit = block
      end

      def on_focus(&block : -> Nil) : Nil
        @on_focus = block
      end

      def on_blur(&block : -> Nil) : Nil
        @on_blur = block
      end

      def draw(renderer : Void*) : Nil
        return unless @visible
        
        draw_background(renderer)
        draw_border(renderer)
        
        # Native text input draws itself
        update_native_frame
      end

      private def create_native_input : Nil
        {% if flag?(:android) }}
          @native_input_ptr = LibTextInput.android_create_text_input(
            @x, @y, @width, @height,
            @config.placeholder.to_utf8,
            @config.max_length,
            @config.keyboard_type.to_i32,
            @config.return_key_type.to_i32,
            @config.secure,
            @config.multiline,
            @config.auto_capitalize,
            @config.auto_correct,
            @config.enabled
          )
          
          LibTextInput.android_set_callbacks(
            @native_input_ptr,
            ->(text_ptr : UInt8*) { handle_text_change(text_ptr) },
            ->(text_ptr : UInt8*) { handle_submit(text_ptr) },
            -> { handle_focus },
            -> { handle_blur }
          )
        {% elsif flag?(:ios) }}
          @native_input_ptr = LibTextInput.ios_create_text_input(
            @x, @y, @width, @height,
            @config.placeholder.to_utf8,
            @config.keyboard_type.to_i32,
            @config.return_key_type.to_i32,
            @config.secure,
            @config.multiline
          )
          
          LibTextInput.ios_set_callbacks(
            @native_input_ptr,
            ->(text_ptr : UInt8*) { handle_text_change(text_ptr) },
            ->(text_ptr : UInt8*) { handle_submit(text_ptr) }
          )
        {% end }}
      end

      private def update_native_text : Nil
        return unless @native_input_ptr
        
        {% if flag?(:android) }}
          LibTextInput.android_set_text(@native_input_ptr, @text.to_utf8)
        {% elsif flag?(:ios) }}
          LibTextInput.ios_set_text(@native_input_ptr, @text.to_utf8)
        {% end }}
      end

      private def update_native_placeholder : Nil
        return unless @native_input_ptr
        
        {% if flag?(:android) }}
          LibTextInput.android_set_placeholder(@native_input_ptr, @config.placeholder.to_utf8)
        {% elsif flag?(:ios) }}
          LibTextInput.ios_set_placeholder(@native_input_ptr, @config.placeholder.to_utf8)
        {% end }}
      end

      private def update_native_frame : Nil
        return unless @native_input_ptr
        
        {% if flag?(:android) }}
          LibTextInput.android_set_frame(@native_input_ptr, absolute_x, absolute_y, @width, @height)
        {% elsif flag?(:ios) }}
          LibTextInput.ios_set_frame(@native_input_ptr, absolute_x, absolute_y, @width, @height)
        {% end }}
      end

      private def draw_border(renderer : Void*) : Nil
        if @is_focused
          draw_rect(renderer, absolute_x, absolute_y, @width, @height,
                    @config.border_color.r, @config.border_color.g, @config.border_color.b, 255)
        else
          draw_rect(renderer, absolute_x, absolute_y, @width, @height,
                    @config.border_color.r, @config.border_color.g, @config.border_color.b, 200)
        end
      end

      private def handle_text_change(text_ptr : UInt8*) : Nil
        @text = String.new(text_ptr)
        @on_change.try &.call(@text)
        LibTextInput.free_string(text_ptr)
      end

      private def handle_submit(text_ptr : UInt8*) : Nil
        @text = String.new(text_ptr)
        @on_submit.try &.call(@text)
        LibTextInput.free_string(text_ptr)
      end

      private def handle_focus : Nil
        @is_focused = true
        @on_focus.try &.call
      end

      private def handle_blur : Nil
        @is_focused = false
        @on_blur.try &.call
      end
    end

    class SecureTextInput < TextInput
      def initialize(config : TextInputConfig = TextInputConfig.new)
        config.secure = true
        super(config)
      end
    end

    class MultilineTextInput < TextInput
      def initialize(config : TextInputConfig = TextInputConfig.new)
        config.multiline = true
        config.return_key_type = ReturnKeyType::Default
        super(config)
        @height = 100
      end
    end

    class SearchBar < UI::View
      @text_input : TextInput
      @on_search : (String -> Nil)?
      @on_cancel : ( -> Nil)?

      def initialize(placeholder : String = "Search...")
        super()
        @height = 50
        
        config = TextInputConfig.new
        config.placeholder = placeholder
        config.return_key_type = ReturnKeyType::Search
        
        @text_input = TextInput.new(config)
        @text_input.on_submit do |text|
          @on_search.try &.call(text)
        end
        
        add_child(@text_input)
      end

      def text : String
        @text_input.text
      end

      def text=(value : String)
        @text_input.text = value
      end

      def on_search(&block : String -> Nil) : Nil
        @on_search = block
      end

      def on_cancel(&block : -> Nil) : Nil
        @on_cancel = block
      end

      def clear : Nil
        @text_input.clear
      end

      def layout(x : Int32, y : Int32, width : Int32, height : Int32) : Nil
        super(x, y, width, height)
        @text_input.layout(x, y, width, height)
      end
    end

    class FormField < UI::View
      property label : String
      property text_input : TextInput
      property error_message : String?
      property is_valid : Bool = true

      def initialize(label : String, config : TextInputConfig = TextInputConfig.new)
        super()
        @label = label
        @text_input = TextInput.new(config)
        @error_message = nil
        @height = 80
        
        add_child(@text_input)
      end

      def text : String
        @text_input.text
      end

      def text=(value : String)
        @text_input.text = value
      end

      def show_error(message : String) : Nil
        @error_message = message
        @is_valid = false
        @text_input.config.border_color = Styling::Color.red
      end

      def clear_error : Nil
        @error_message = nil
        @is_valid = true
        @text_input.config.border_color = Styling::Color.gray(200)
      end

      def layout(x : Int32, y : Int32, width : Int32, height : Int32) : Nil
        super(x, y, width, height)
        @text_input.layout(x, y + 30, width, 44)
      end

      def draw(renderer : Void*) : Nil
        draw_text(renderer, @label, absolute_x, absolute_y, 14, 100, 100, 100)
        
        if error_message = @error_message
          draw_text(renderer, error_message, absolute_x, absolute_y + 78, 12, 255, 0, 0)
        end
        
        super(renderer)
      end
    end

    module TextUtils
      def self.validate_email(email : String) : Bool
        regex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/
        email =~ regex ? true : false
      end

      def self.validate_phone(phone : String) : Bool
        digits = phone.gsub(/[^0-9]/, "")
        digits.size >= 10 && digits.size <= 15
      end

      def self.validate_password_strength(password : String) : Int32
        score = 0
        score += 1 if password.size >= 8
        score += 1 if password.matches?(/[a-z]/)
        score += 1 if password.matches?(/[A-Z]/)
        score += 1 if password.matches?(/\d/)
        score += 1 if password.matches?(/[!@#$%^&*(),.?":{}|<>]/)
        score
      end

      def self.truncate(text : String, max_length : Int32) : String
        return text if text.size <= max_length
        text[0...max_length] + "..."
      end

      def self.capitalize_words(text : String) : String
        text.split.map(&.capitalize).join(" ")
      end
    end
  end
end
