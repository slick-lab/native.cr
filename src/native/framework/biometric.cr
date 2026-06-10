# src/native/framework/biometric.cr

module Native::Biometric
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
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return false unless env

        keyguard_class = env.FindClass("android/app/KeyguardManager")
        keyguard = env.CallObjectMethod(Native::Android::JNI.activity, env.GetMethodID(env.GetObjectClass(Native::Android::JNI.activity), "getSystemService", "(Ljava/lang/String;)Ljava/lang/Object;"), env.NewStringUTF("keyguard"))
        is_keyguard = env.GetMethodID(env.GetObjectClass(keyguard), "isKeyguardSecure", "()Z")
        env.CallBooleanMethod(keyguard, is_keyguard)
      elsif Native::Platform.ios?
        LibIOS.is_biometric_enrolled
      else
        false
      end
    end

    def self.authenticate(config : BiometricConfig = BiometricConfig.new) : BiometricResult
      return BiometricResult.new(success: false, error: BiometricError::NotAvailable) unless is_available?

      if Native::Platform.android?
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return BiometricResult.new(success: false, error: BiometricError::NotAvailable) unless env && activity

        biometric_class = env.FindClass("androidx/biometric/BiometricPrompt")
        if biometric_class == Pointer(Void).null
          return BiometricResult.new(success: false, error: BiometricError::NotAvailable)
        end

        executor_class = env.FindClass("android/os/Handler")
        executor = env.CallStaticObjectMethod(executor_class, env.GetStaticMethodID(executor_class, "getMain", "()Landroid/os/Handler;"))

        callback_class = env.FindClass("com/nativecr/BiometricCallback")
        callback_obj = env.NewObject(callback_class, env.GetMethodID(callback_class, "<init>", "(J)V"), Pointer(Void).address.to_i64)

        prompt_info_class = env.FindClass("androidx/biometric/BiometricPrompt$PromptInfo")
        builder_class = env.FindClass("androidx/biometric/BiometricPrompt$PromptInfo$Builder")
        builder = env.NewObject(builder_class, env.GetMethodID(builder_class, "<init>", "()V"))

        set_title = env.GetMethodID(builder_class, "setTitle", "(Ljava/lang/CharSequence;)Landroidx/biometric/BiometricPrompt$PromptInfo$Builder;")
        env.CallObjectMethod(builder, set_title, env.NewStringUTF(config.title))

        set_subtitle = env.GetMethodID(builder_class, "setSubtitle", "(Ljava/lang/CharSequence;)Landroidx/biometric/BiometricPrompt$PromptInfo$Builder;")
        env.CallObjectMethod(builder, set_subtitle, env.NewStringUTF(config.subtitle))

        set_desc = env.GetMethodID(builder_class, "setDescription", "(Ljava/lang/CharSequence;)Landroidx/biometric/BiometricPrompt$PromptInfo$Builder;")
        env.CallObjectMethod(builder, set_desc, env.NewStringUTF(config.description))

        set_negative = env.GetMethodID(builder_class, "setNegativeButtonText", "(Ljava/lang/CharSequence;)Landroidx/biometric/BiometricPrompt$PromptInfo$Builder;")
        env.CallObjectMethod(builder, set_negative, env.NewStringUTF(config.cancel_title))

        build = env.GetMethodID(builder_class, "build", "()Landroidx/biometric/BiometricPrompt$PromptInfo;")
        prompt_info = env.CallObjectMethod(builder, build)

        biometric_prompt = env.NewObject(biometric_class, env.GetMethodID(biometric_class, "<init>", "(Landroidx/core/content/ContextCompat;Ljava/util/concurrent/Executor;Landroidx/biometric/BiometricPrompt$AuthenticationCallback;)V"), activity, executor, callback_obj)

        authenticate = env.GetMethodID(biometric_class, "authenticate", "(Landroidx/biometric/BiometricPrompt$PromptInfo;)V")
        env.CallVoidMethod(biometric_prompt, authenticate, prompt_info)

        wait_result
      elsif Native::Platform.ios?
        result_code = LibIOS.authenticate_biometric(
          config.title.to_utf8,
          config.subtitle.to_utf8,
          config.description.to_utf8,
          config.cancel_title.to_utf8,
          config.fallback_title.to_utf8,
          config.allow_fallback
        )
        parse_result(result_code)
      else
        BiometricResult.new(success: false, error: BiometricError::NotAvailable)
      end
    end

    def self.authenticate_async(config : BiometricConfig = BiometricConfig.new, &callback : BiometricResult -> Nil) : Nil
      spawn do
        result = authenticate(config)
        callback.call(result)
      end
    end

    private def self.check_availability : Nil
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env

        biometric_class = env.FindClass("androidx/biometric/BiometricManager")
        if biometric_class == Pointer(Void).null
          @@is_available = false
          return
        end

        from = env.GetStaticMethodID(biometric_class, "from", "(Landroid/content/Context;)Landroidx/biometric/BiometricManager;")
        manager = env.CallStaticObjectMethod(biometric_class, from, Native::Android::JNI.activity)

        can_auth = env.GetMethodID(biometric_class, "canAuthenticate", "(I)I")
        result = env.CallIntMethod(manager, can_auth, 0)

        @@is_available = result == 0
        @@available_type = BiometricType::Fingerprint if @@is_available
      elsif Native::Platform.ios?
        result = LibIOS.get_biometric_type
        @@is_available = result != 0
        @@available_type = case result
                           when 1 then BiometricType::Fingerprint
                           when 2 then BiometricType::FaceID
                           else        BiometricType::None
                           end
      else
        @@is_available = false
        @@available_type = BiometricType::None
      end
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
      else
        result.success = false
        result.error = BiometricError::NotAvailable
        result.error_message = "Unknown error"
      end

      result.type_used = available_type
      result
    end

    private def self.wait_result : BiometricResult
      result = BiometricResult.new
      result.success = true
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

    def self.authenticate(title : String = "Authenticate", &callback : BiometricResult -> Nil) : Nil
      config = BiometricConfig.new
      config.title = title
      BiometricManager.authenticate_async(config, &callback)
    end

    def self.authenticate_and_save(key : String, value : String, title : String = "Save with Biometric") : Bool
      result = BiometricManager.authenticate(BiometricConfig.new(title: title))

      if result.authenticated?
        Native::Storage::Preferences.new.set(key, value)
        true
      else
        false
      end
    end

    def self.authenticate_and_load(key : String, title : String = "Access with Biometric") : String?
      result = BiometricManager.authenticate(BiometricConfig.new(title: title))

      if result.authenticated?
        Native::Storage::Preferences.new.get_string(key)
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
