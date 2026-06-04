# src/native/framework/platform.cr

module Native
  module Platform
    enum DeviceType
      Phone
      Tablet
      TV
      Watch
    end

    enum Orientation
      Portrait
      PortraitUpsideDown
      LandscapeLeft
      LandscapeRight
    end

    struct DeviceInfo
      property model : String
      property manufacturer : String
      property os_version : String
      property app_version : String
      property screen_width : Int32
      property screen_height : Int32
      property screen_dpi : Int32
      property device_type : DeviceType
      property language : String
      property timezone : String

      def initialize
        @model = ""
        @manufacturer = ""
        @os_version = ""
        @app_version = ""
        @screen_width = 0
        @screen_height = 0
        @screen_dpi = 0
        @device_type = DeviceType::Phone
        @language = ""
        @timezone = ""
      end
    end

    struct BatteryInfo
      property level : Int32
      property is_charging : Bool
      property is_full : Bool

      def initialize(@level = 0, @is_charging = false, @is_full = false)
      end
    end

    struct Location
      property latitude : Float64
      property longitude : Float64
      property altitude : Float64
      property accuracy : Float32
      property timestamp : Int64

      def initialize(@latitude = 0.0, @longitude = 0.0, @altitude = 0.0,
                     @accuracy = 0.0, @timestamp = 0_i64)
      end
    end

    module Device
      def self.info : DeviceInfo
        info = DeviceInfo.new
        
        {% if flag?(:android) %}
          info.model = String.new(LibPlatform.android_get_model)
          info.manufacturer = String.new(LibPlatform.android_get_manufacturer)
          info.os_version = String.new(LibPlatform.android_get_os_version)
          info.app_version = String.new(LibPlatform.android_get_app_version)
          info.screen_width = LibPlatform.android_get_screen_width
          info.screen_height = LibPlatform.android_get_screen_height
          info.screen_dpi = LibPlatform.android_get_screen_dpi
          info.device_type = DeviceType.from_value(LibPlatform.android_get_device_type)
          info.language = String.new(LibPlatform.android_get_language)
          info.timezone = String.new(LibPlatform.android_get_timezone)
        {% elsif flag?(:ios) %}
          info.model = String.new(LibPlatform.ios_get_model)
          info.manufacturer = "Apple"
          info.os_version = String.new(LibPlatform.ios_get_os_version)
          info.app_version = String.new(LibPlatform.ios_get_app_version)
          info.screen_width = LibPlatform.ios_get_screen_width
          info.screen_height = LibPlatform.ios_get_screen_height
          info.screen_dpi = LibPlatform.ios_get_screen_dpi
          info.device_type = DeviceType.from_value(LibPlatform.ios_get_device_type)
          info.language = String.new(LibPlatform.ios_get_language)
          info.timezone = String.new(LibPlatform.ios_get_timezone)
          {% end %}
        info
      end

      def self.orientation : Orientation
        {% if flag?(:android) %}
          Orientation.from_value(LibPlatform.android_get_orientation)
        {% elsif flag?(:ios) %}
          Orientation.from_value(LibPlatform.ios_get_orientation)
        {% else %}
          Orientation::Portrait
        {% end %}
      end

      def self.vibrate(duration_ms : Int32) : Nil
        {% if flag?(:android) %}
          LibPlatform.android_vibrate(duration_ms)
        {% elsif flag?(:ios) %}
          LibPlatform.ios_vibrate
        {% end %}
      end

      def self.open_url(url : String) : Bool
        {% if flag?(:android) %}
          LibPlatform.android_open_url(url.to_utf8)
        {% elsif flag?(:ios) %}
          LibPlatform.ios_open_url(url.to_utf8)
        {% else %}
          false
        {% end %}
      end

      def self.share(text : String, title : String = "") : Nil
        {% if flag?(:android) %}
          LibPlatform.android_share(text.to_utf8, title.to_utf8)
        {% elsif flag?(:ios) %}
          LibPlatform.ios_share(text.to_utf8, title.to_utf8)
        {% end %}
      end

      def self.copy_to_clipboard(text : String) : Nil
        {% if flag?(:android) %}
          LibPlatform.android_copy_to_clipboard(text.to_utf8)
        {% elsif flag?(:ios) %}
          LibPlatform.ios_copy_to_clipboard(text.to_utf8)
        {% end %}
      end

      def self.paste_from_clipboard : String
        {% if flag?(:android) %}
          ptr = LibPlatform.android_paste_from_clipboard
        {% elsif flag?(:ios) %}
          ptr = LibPlatform.ios_paste_from_clipboard
        {% else %}
          return ""
        {% end %}
        
        if ptr
          text = String.new(ptr)
          LibPlatform.free_string(ptr)
          text
        else
          ""
        end
      end
    end

    module Battery
      def self.info : BatteryInfo
        info = BatteryInfo.new
        
        {% if flag?(:android) %}
          info.level = LibPlatform.android_get_battery_level
          info.is_charging = LibPlatform.android_is_battery_charging
          info.is_full = LibPlatform.android_is_battery_full
        {% elsif flag?(:ios) %}
          info.level = LibPlatform.ios_get_battery_level
          info.is_charging = LibPlatform.ios_is_battery_charging
          info.is_full = false
        {% end %}
        
        info
      end

      def self.level : Int32
        info.level
      end

      def self.charging? : Bool
        info.is_charging
      end
    end

    module Sensors
      class Accelerometer
        @callback : (Float64, Float64, Float64) -> Nil = ->(x : Float64, y : Float64, z : Float64) {}
        @is_listening = false

        def on_change(&block : Float64, Float64, Float64 -> Nil) : Nil
          @callback = block
        end

        def start : Nil
          return if @is_listening
          
          {% if flag?(:android) %}
            LibPlatform.android_accelerometer_start
          {% elsif flag?(:ios) %}
            LibPlatform.ios_accelerometer_start
          {% end %}
          
          @is_listening = true
          start_listening
        end

        def stop : Nil
          return unless @is_listening
          
          {% if flag?(:android) %}
            LibPlatform.android_accelerometer_stop
          {% elsif flag?(:ios) %}
            LibPlatform.ios_accelerometer_stop
          {% end %}
          
          @is_listening = false
        end

        private def start_listening : Nil
          spawn do
            while @is_listening
              {% if flag?(:android) %}
                x = LibPlatform.android_accelerometer_get_x
                y = LibPlatform.android_accelerometer_get_y
                z = LibPlatform.android_accelerometer_get_z
              {% elsif flag?(:ios) %}
                x = LibPlatform.ios_accelerometer_get_x
                y = LibPlatform.ios_accelerometer_get_y
                z = LibPlatform.ios_accelerometer_get_z
              {% else %}
                x, y, z = 0.0, 0.0, 0.0
              {% end %}
              
              @callback.call(x, y, z)
              sleep 0.016 # ~60 FPS
            end
          end
        end
      end

      class Gyroscope
        @callback : (Float64, Float64, Float64) -> Nil = ->(x : Float64, y : Float64, z : Float64) {}
        @is_listening = false

        def on_change(&block : Float64, Float64, Float64 -> Nil) : Nil
          @callback = block
        end

        def start : Nil
          return if @is_listening
          
          {% if flag?(:android) %}
            LibPlatform.android_gyroscope_start
          {% elsif flag?(:ios) %}
            LibPlatform.ios_gyroscope_start
          {% end %}
          
          @is_listening = true
          start_listening
        end

        def stop : Nil
          return unless @is_listening
          
          {% if flag?(:android) %}
            LibPlatform.android_gyroscope_stop
          {% elsif flag?(:ios) %}
            LibPlatform.ios_gyroscope_stop
          {% end %}
          
          @is_listening = false
        end

        private def start_listening : Nil
          spawn do
            while @is_listening
              {% if flag?(:android) %}
                x = LibPlatform.android_gyroscope_get_x
                y = LibPlatform.android_gyroscope_get_y
                z = LibPlatform.android_gyroscope_get_z
              {% elsif flag?(:ios) %}
                x = LibPlatform.ios_gyroscope_get_x
                y = LibPlatform.ios_gyroscope_get_y
                z = LibPlatform.ios_gyroscope_get_z
              {% else %}
                x, y, z = 0.0, 0.0, 0.0
              {% end %}
              
              @callback.call(x, y, z)
              sleep 0.016
            end
          end
        end
      end
    end

    module Geolocation
      @@on_location : Location -> Nil = ->(loc : Location) {}
      @@on_error : String -> Nil = ->(err : String) {}
      @@is_listening = false

      def self.get_current_location : Location?
        {% if flag?(:android) %}
          lat = LibPlatform.android_get_last_latitude
          lon = LibPlatform.android_get_last_longitude
        {% elsif flag?(:ios) %}
          lat = LibPlatform.ios_get_last_latitude
          lon = LibPlatform.ios_get_last_longitude
        {% else %}
          return nil
        {% end %}
        
        if lat != 0.0 || lon != 0.0
          Location.new(latitude: lat, longitude: lon)
        else
          nil
        end
      end

      def self.start_listening(accuracy : Float32 = 10.0) : Nil
        return if @@is_listening
        
        {% if flag?(:android) %}
          LibPlatform.android_geolocation_start(accuracy)
        {% elsif flag?(:ios) %}
          LibPlatform.ios_geolocation_start(accuracy)
        {% end %}
        
        @@is_listening = true
        start_polling
      end

      def self.stop_listening : Nil
        return unless @@is_listening
        
        {% if flag?(:android) %}
          LibPlatform.android_geolocation_stop
        {% elsif flag?(:ios) %}
          LibPlatform.ios_geolocation_stop
        {% end %}
        
        @@is_listening = false
      end

      def self.on_location(&block : Location -> Nil) : Nil
        @@on_location = block
      end

      def self.on_error(&block : String -> Nil) : Nil
        @@on_error = block
      end

      private def self.start_polling : Nil
        spawn do
          while @@is_listening
            if loc = get_current_location
              @@on_location.call(loc)
            end
            sleep 1.0
          end
        end
      end
    end

    module HapticFeedback
      enum HapticType
        Light
        Medium
        Heavy
        Success
        Warning
        Error
        Selection
      end

      def self.generate(type : HapticType) : Nil
        {% if flag?(:android) %}
          LibPlatform.android_haptic_feedback(type.to_i32)
        {% elsif flag?(:ios) %}
          LibPlatform.ios_haptic_feedback(type.to_i32)
        {% end %}
      end

      def self.light : Nil
        generate(HapticType::Light)
      end

      def self.medium : Nil
        generate(HapticType::Medium)
      end

      def self.heavy : Nil
        generate(HapticType::Heavy)
      end

      def self.selection : Nil
        generate(HapticType::Selection)
      end

      def self.success : Nil
        generate(HapticType::Success)
      end

      def self.warning : Nil
        generate(HapticType::Warning)
      end
    end

    module Brightness
      def self.get : Float32
        {% if flag?(:android) %}
          LibPlatform.android_get_brightness
        {% elsif flag?(:ios) %}
          LibPlatform.ios_get_brightness
        {% else %}
          0.5
        {% end %}
      end

      def self.set(value : Float32) : Nil
        val = value.clamp(0.0, 1.0)
        
        {% if flag?(:android) %}
          LibPlatform.android_set_brightness(val)
        {% elsif flag?(:ios) %}
          LibPlatform.ios_set_brightness(val)
        {% end %}
      end
    end

    module StatusBar
      def self.hide : Nil
        {% if flag?(:android) %}
          LibPlatform.android_hide_status_bar
        {% elsif flag?(:ios) %}
          LibPlatform.ios_hide_status_bar
        {% end %}
      end

      def self.show : Nil
        {% if flag?(:android) %}
          LibPlatform.android_show_status_bar
        {% elsif flag?(:ios) %}
          LibPlatform.ios_show_status_bar
        {% end %}
      end

      def self.set_color(r : UInt8, g : UInt8, b : UInt8) : Nil
        {% if flag?(:android) %}
          LibPlatform.android_set_status_bar_color(r, g, b)
        {% elsif flag?(:ios) %}
          LibPlatform.ios_set_status_bar_color(r, g, b)
        {% end %}
      end
    end

    module Screen
      def self.keep_on(keep : Bool) : Nil
        {% if flag?(:android) %}
          if keep
            LibPlatform.android_keep_screen_on
          else
            LibPlatform.android_allow_screen_sleep
          end
        {% elsif flag?(:ios) %}
          UIApplication.shared.isIdleTimerDisabled = keep
        {% end %}
      end
    end
  end
end
