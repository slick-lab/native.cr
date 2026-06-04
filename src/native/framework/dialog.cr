# src/native/framework/dialog.cr

module Native
  module Dialog
    enum DialogAction
      Positive
      Negative
      Neutral
      Destructive
    end

    struct DialogButton
      property title : String
      property action : DialogAction
      property callback : -> Nil
      property is_default : Bool
      property is_cancel : Bool

      def initialize(@title = "", @action = DialogAction::Neutral, 
                     @callback = ->{}, @is_default = false, @is_cancel = false)
      end
    end

    struct AlertConfig
      property title : String = ""
      property message : String = ""
      property cancelable : Bool = true
      property buttons : Array(DialogButton) = [] of DialogButton

      def initialize
      end
    end

    class AlertDialog
      @config : AlertConfig
      @dialog_ptr : Void*? = nil
      @is_showing : Bool = false

      def initialize(config : AlertConfig = AlertConfig.new)
        @config = config
      end

      def title=(value : String)
        @config.title = value
        update_native_title if @is_showing
      end

      def message=(value : String)
        @config.message = value
        update_native_message if @is_showing
      end

      def add_button(title : String, action : DialogAction = DialogAction::Neutral, &callback : -> Nil) : Nil
        @config.buttons << DialogButton.new(title, action, callback)
      end

      def show : Nil
        return if @is_showing
        
        {% if flag?(:android) %}
          @dialog_ptr = LibDialog.android_show_alert(
            @config.title.to_utf8,
            @config.message.to_utf8,
            @config.cancelable
          )
          
          setup_button_callbacks
        {% elsif flag?(:ios) %}
          @dialog_ptr = LibDialog.ios_show_alert(
            @config.title.to_utf8,
            @config.message.to_utf8,
            @config.cancelable
          )
          
          setup_button_callbacks
        {% end %}
        
        @is_showing = true
      end

      def dismiss : Nil
        return unless @is_showing && @dialog_ptr
        
        {% if flag?(:android) %}
          LibDialog.android_dismiss_dialog(@dialog_ptr)
        {% elsif flag?(:ios) %}
          LibDialog.ios_dismiss_alert(@dialog_ptr)
        {% end %}
        
        @is_showing = false
        @dialog_ptr = nil
      end

      private def update_native_title : Nil
        return unless @dialog_ptr
        
        {% if flag?(:android) %}
          LibDialog.android_set_dialog_title(@dialog_ptr, @config.title.to_utf8)
        {% end %}
      end

      private def update_native_message : Nil
        return unless @dialog_ptr
        
        {% if flag?(:android) %}
          LibDialog.android_set_dialog_message(@dialog_ptr, @config.message.to_utf8)
        {% end %}
      end

      private def setup_button_callbacks : Nil
        @config.buttons.each_with_index do |button, index|
          {% if flag?(:android) %}
            LibDialog.android_add_dialog_button(
              @dialog_ptr,
              button.title.to_utf8,
              button.action.to_i32,
              index,
              button.is_default,
              button.is_cancel
            )
          {% elsif flag?(:ios) %}
            LibDialog.ios_add_alert_button(
              @dialog_ptr,
              button.title.to_utf8,
              button.action.to_i32,
              index
            )
          {% end %}
        end
        
        set_global_callback
      end

      private def set_global_callback : Nil
        {% if flag?(:android) %}
          LibDialog.android_set_dialog_callback(
            @dialog_ptr,
            ->(index : Int32) {
              handle_button_click(index)
            },
            -> {
              handle_dismiss
            }
          )
        {% elsif flag?(:ios) %}
          LibDialog.ios_set_alert_callback(
            @dialog_ptr,
            ->(index : Int32) {
              handle_button_click(index)
            }
          )
        {% end %}
      end

      private def handle_button_click(index : Int32) : Nil
        if index >= 0 && index < @config.buttons.size
          @config.buttons[index].callback.call
        end
        @is_showing = false
        @dialog_ptr = nil
      end

      private def handle_dismiss : Nil
        @is_showing = false
        @dialog_ptr = nil
      end
    end

    class ConfirmationDialog < AlertDialog
      def initialize(title : String, message : String, 
                     on_confirm : -> Nil, on_cancel : -> Nil = ->{})
        super(AlertConfig.new(title: title, message: message))
        add_button("Confirm", DialogAction::Positive, &on_confirm)
        add_button("Cancel", DialogAction::Negative, &on_cancel)
      end
    end

    class DestructiveConfirmationDialog < AlertDialog
      def initialize(title : String, message : String,
                     on_confirm : -> Nil, on_cancel : -> Nil = ->{})
        super(AlertConfig.new(title: title, message: message))
        add_button("Delete", DialogAction::Destructive, &on_confirm)
        add_button("Cancel", DialogAction::Negative, &on_cancel)
      end
    end

    class Toast
      enum Duration
        Short
        Long
      end

      def self.show(message : String, duration : Duration = Duration::Short) : Nil
        {% if flag?(:android) %}
          LibDialog.android_show_toast(message.to_utf8, duration == Duration::Short ? 0 : 1)
        {% elsif flag?(:ios) %}
          LibDialog.ios_show_toast(message.to_utf8, duration == Duration::Short ? 2.0 : 3.5)
        {% end %}
      end
    end

    class LoadingDialog
      @dialog_ptr : Void*? = nil
      @is_showing : Bool = false

      def initialize(@message : String = "Loading...")
      end

      def show : Nil
        return if @is_showing
        
        {% if flag?(:android) %}
          @dialog_ptr = LibDialog.android_show_loading(@message.to_utf8)
        {% elsif flag?(:ios) %}
          @dialog_ptr = LibDialog.ios_show_loading(@message.to_utf8)
        {% end %}
        
        @is_showing = true
      end

      def dismiss : Nil
        return unless @is_showing && @dialog_ptr
        
        {% if flag?(:android) %}
          LibDialog.android_dismiss_loading(@dialog_ptr)
        {% elsif flag?(:ios) %}
          LibDialog.ios_dismiss_loading(@dialog_ptr)
        {% end %}
        
        @is_showing = false
        @dialog_ptr = nil
      end

      def set_message(message : String) : Nil
        @message = message
        return unless @is_showing && @dialog_ptr
        
        {% if flag?(:android) %}
          LibDialog.android_set_loading_message(@dialog_ptr, message.to_utf8)
        {% end %}
      end

      def showing? : Bool
        @is_showing
      end
    end

    class ActionSheet
      @config : AlertConfig
      @sheet_ptr : Void*? = nil

      def initialize(title : String = "", message : String = "")
        @config = AlertConfig.new(title: title, message: message)
      end

      def add_action(title : String, style : DialogAction = DialogAction::Neutral, &callback : -> Nil) : Nil
        @config.buttons << DialogButton.new(title, style, callback)
      end

      def show : Nil
        {% if flag?(:ios) %}
          @sheet_ptr = LibDialog.ios_show_action_sheet(
            @config.title.to_utf8,
            @config.message.to_utf8
          )
          
          @config.buttons.each_with_index do |button, index|
            LibDialog.ios_add_action_sheet_button(
              @sheet_ptr,
              button.title.to_utf8,
              button.action.to_i32,
              index,
              button.action == DialogAction::Destructive
            )
          end
          
          LibDialog.ios_set_action_sheet_callback(
            @sheet_ptr,
            ->(index : Int32) {
              if index >= 0 && index < @config.buttons.size
                @config.buttons[index].callback.call
              end
              @sheet_ptr = nil
            }
          )
        {% else %}
          alert = AlertDialog.new(@config)
          @config.buttons.each { |b| alert.add_button(b.title, b.action, &b.callback) }
          alert.show
        {% end %}
      end
    end

    module Dialog
      def self.alert(title : String, message : String, &callback : -> Nil) : Nil
        dialog = AlertDialog.new(AlertConfig.new(title: title, message: message))
        dialog.add_button("OK", DialogAction::Positive, &callback)
        dialog.show
      end

      def self.confirm(title : String, message : String, on_confirm : -> Nil, on_cancel : -> Nil = ->{})
        ConfirmationDialog.new(title, message, on_confirm, on_cancel).show
      end

      def self.confirm_destructive(title : String, message : String, on_confirm : -> Nil, on_cancel : -> Nil = ->{})
        DestructiveConfirmationDialog.new(title, message, on_confirm, on_cancel).show
      end

      def self.prompt(title : String, message : String, on_result : String -> Nil, placeholder : String = "", on_cancel : -> Nil = ->{})
        {% if flag?(:android) %}
          LibDialog.android_show_prompt_dialog(
            title.to_utf8,
            message.to_utf8,
            placeholder.to_utf8,
            ->(text_ptr : UInt8*) {
              on_result.call(String.new(text_ptr))
              LibDialog.free_string(text_ptr)
            },
            -> {
              on_cancel.call
            }
          )
        {% elsif flag?(:ios) %}
          LibDialog.ios_show_prompt_alert(
            title.to_utf8,
            message.to_utf8,
            placeholder.to_utf8,
            ->(text_ptr : UInt8*) {
              on_result.call(String.new(text_ptr))
              LibDialog.free_string(text_ptr)
            },
            -> {
              on_cancel.call
            }
          )
        {% end %}
      end

      def self.toast(message : String, long : Bool = false)
        Toast.show(message, long ? Toast::Duration::Long : Toast::Duration::Short)
      end

      def self.loading(message : String = "Loading...", &block : -> T) : T forall T
        loader = LoadingDialog.new(message)
        loader.show
        
        result = block.call
        
        loader.dismiss
        result
      end

      def self.loading_async(message : String = "Loading...", &block : -> T) : Promise(T)
        loader = LoadingDialog.new(message)
        loader.show
        
        promise = Promise(T).new
        spawn do
          begin
            result = block.call
            promise.complete(result)
          rescue ex
            promise.reject(ex)
          ensure
            loader.dismiss
          end
        end
        
        promise
      end
    end
  end
end
