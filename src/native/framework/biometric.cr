# src/native/framework/biometric.cr

module Native
  module Biometric
    enum BiometricType
      Fingerprint
      FaceID
      Iris
      None
    end

    enum BiometricError
      Success
      NotAvailable
      NotEnrolled
      NotAuthenticated
      Lockout
      LockoutPermanent
      UserCancel
      UserFallback
      SystemCancel
      PasscodeNotSet
      InvalidContext
      NotInteractive
    end

    struct BiometricConfig
      property title : String = "Biometric Authentication"
      property subtitle : String = ""
      property description : String = "Verify your identity to continue"
      property cancel_title : String = "Cancel"
      property fallback_title : String = "Use Passcode"
      property allow_device_credential : Bool = true
      property allow_fallback : Bool = true

      def initialize
      end
    end

    struct BiometricResult
      property success : Bool
      property error : BiometricError
      property error_message : String?
      property type_used : BiometricType

      def initialize(@success = false, @error = BiometricError::Success,
                     @error_message = nil, @type_used = BiometricType::None)
      end

      def authenticated? : Bool
        @success
      end
    end

    class BiometricManager
      @@is_available : Bool? = nil
      @@available_type : BiometricType = BiometricType::None

      def self.is_available? : Bool
        if @@is_available.nil?
          check_availability
        end
        @@is_available || false
      end

      def self.available_type : BiometricType
        if @@is_available.nil?
          check_availability
        end
        @@available_type
      end

      def self.is_enrolled? : Bool
        {% if flag?(:android) %}
          LibBiometric.android_is_biometric_enrolled
        {% elsif flag?(:ios) %}
          LibBiometric.ios_is_biometric_enrolled
        {% else %}
          false
        {% end %}
      end

      def self.authenticate(config : BiometricConfig = BiometricConfig.new) : BiometricResult
        return BiometricResult.new(success: false, error: BiometricError::NotAvailable) unless is_available?
        
        {% if flag?(:android) %}
          result_code = LibBiometric.android_authenticate(
            config.title.to_utf8,
            config.subtitle.to_utf8,
            config.description.to_utf8,
            config.cancel_title.to_utf8,
            config.fallback_title.to_utf8,
            config.allow_device_credential,
            config.allow_fallback
          )
        {% elsif flag?(:ios) %}
          result_code = LibBiometric.ios_authenticate(
            config.title.to_utf8,
            config.subtitle.to_utf8,
            config.description.to_utf8,
            config.cancel_title.to_utf8,
            config.fallback_title.to_utf8,
            config.allow_fallback
          )
        {% else %}
          return BiometricResult.new(success: false, error: BiometricError::NotAvailable)
        {% end %}
        
        parse_result(result_code)
      end

      def self.authenticate_async(config : BiometricConfig = BiometricConfig.new, &callback : BiometricResult -> Nil) : Nil
        spawn do
          result = authenticate(config)
          callback.call(result)
        end
      end

      private def self.check_availability : Nil
        {% if flag?(:android) %}
          result = LibBiometric.android_is_biometric_available
          @@is_available = result >= 0
          @@available_type = case result
                             when 1 then BiometricType::Fingerprint
                             when 2 then BiometricType::FaceID
                             when 3 then BiometricType::Iris
                             else BiometricType::None
                             end
        {% elsif flag?(:ios) %}
          result = LibBiometric.ios_get_biometric_type
          @@is_available = result != 0
          @@available_type = case result
                             when 1 then BiometricType::Fingerprint
                             when 2 then BiometricType::FaceID
                             else BiometricType::None
                             end
        {% else %}
          @@is_available = false
          @@available_type = BiometricType::None
        {% end %}
      end

      private def self.parse_result(result_code : Int32) : BiometricResult
        result = BiometricResult.new
        
        case result_code
        when 0
          result.success = true
          result.error = BiometricError::Success
        when 1
          result.success = false
          result.error = BiometricError::NotAvailable
          result.error_message = "Biometric authentication is not available"
        when 2
          result.success = false
          result.error = BiometricError::NotEnrolled
          result.error_message = "No biometric data is enrolled"
        when 3
          result.success = false
          result.error = BiometricError::NotAuthenticated
          result.error_message = "Authentication failed"
        when 4
          result.success = false
          result.error = BiometricError::Lockout
          result.error_message = "Too many failed attempts. Try again later"
        when 5
          result.success = false
          result.error = BiometricError::LockoutPermanent
          result.error_message = "Too many failed attempts. Use your passcode"
        when 6
          result.success = false
          result.error = BiometricError::UserCancel
          result.error_message = "User cancelled"
        when 7
          result.success = false
          result.error = BiometricError::UserFallback
          result.error_message = "User chose fallback"
        when 8
          result.success = false
          result.error = BiometricError::SystemCancel
          result.error_message = "System cancelled"
        when 9
          result.success = false
          result.error = BiometricError::PasscodeNotSet
          result.error_message = "Device passcode is not set"
        else
          result.success = false
          result.error = BiometricError::NotAvailable
          result.error_message = "Unknown error"
        end
        
        result.type_used = available_type
        result
      end
    end

    module Biometric
      def self.available? : Bool
        BiometricManager.is_available?
      end

      def self.type : BiometricType
        BiometricManager.available_type
      end

      def self.type_name : String
        case type
        when BiometricType::Fingerprint
          "Fingerprint"
        when BiometricType::FaceID
          "Face ID"
        when BiometricType::Iris
          "Iris Scan"
        else
          "None"
        end
      end

      def self.enrolled? : Bool
        BiometricManager.is_enrolled?
      end

      def self.authenticate(callback : BiometricResult -> Nil, title : String = "Authenticate") : Nil
        config = BiometricConfig.new
        config.title = title
        BiometricManager.authenticate_async(config, &callback)
      end

      def self.authenticate_and_save(key : String, value : String, title : String = "Save with Biometric") : Bool
        result = BiometricManager.authenticate(BiometricConfig.new(title: title))
        
        if result.authenticated?
          Storage::Preferences.new.set(key, value)
          true
        else
          false
        end
      end

      def self.authenticate_and_load(key : String, title : String = "Access with Biometric") : String?
        result = BiometricManager.authenticate(BiometricConfig.new(title: title))
        
        if result.authenticated?
          Storage::Preferences.new.get_string(key)
        else
          nil
        end
      end

      def self.protected_action(title : String = "Verify Identity", &block : -> T) : T? forall T
        result = BiometricManager.authenticate(BiometricConfig.new(title: title))
        
        if result.authenticated?
          block.call
        else
          nil
        end
      end
    end
  end
end
