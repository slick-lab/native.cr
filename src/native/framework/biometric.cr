# src/native/framework/biometric.cr
# Refactored to use JNIHelpers for automatic local reference cleanup.

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
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          activity = Native::Android::JNI.activity
          next false if activity.null?

          keyguard = JNIHelpers.with_jstring(env, "keyguard") do |jname|
            JNIHelpers.call_object(env, activity.to_i64, "getSystemService", "(Ljava/lang/String;)Ljava/lang/Object;", jname)
          end
          next false if keyguard.null?
          begin
            JNIHelpers.call_boolean(env, keyguard.to_i64, "isKeyguardSecure", "()Z")
          ensure
            env.delete_local_ref(keyguard)
          end
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.is_biometric_enrolled
      {% else %}
        false
      {% end %}
    end

    def self.authenticate(config : BiometricConfig = BiometricConfig.new) : BiometricResult
      return BiometricResult.new(success: false, error: BiometricError::NotAvailable) unless is_available?

      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          activity = Native::Android::JNI.activity
          next BiometricResult.new(success: false, error: BiometricError::NotAvailable) if activity.null?

          executor = JNIHelpers.call_static_object(env, "android/os/Handler", "getMain", "()Landroid/os/Handler;")
          next BiometricResult.new(success: false, error: BiometricError::NotAvailable) if executor.null?
          begin
            callback_obj = JNIHelpers.new_callback(env, "com/nativecr/BiometricCallback", 0i64)
            next BiometricResult.new(success: false, error: BiometricError::NotAvailable) if callback_obj.null?
            begin
              prompt_info = JNIHelpers.with_class(env, "androidx/biometric/BiometricPrompt$PromptInfo$Builder") do |builder_class|
                next Pointer(Void).null if builder_class.null?
                ctor = env.get_method_id(builder_class, "<init>", "()V")
                next Pointer(Void).null if ctor.null?
                builder = env.new_object(builder_class, ctor)
                next Pointer(Void).null if builder.null?
                begin
                  JNIHelpers.with_jstring(env, config.title) do |jt|
                    JNIHelpers.call_object(env, builder.to_i64, "setTitle", "(Ljava/lang/CharSequence;)Landroidx/biometric/BiometricPrompt$PromptInfo$Builder;", jt)
                  end
                  JNIHelpers.with_jstring(env, config.subtitle) do |jt|
                    JNIHelpers.call_object(env, builder.to_i64, "setSubtitle", "(Ljava/lang/CharSequence;)Landroidx/biometric/BiometricPrompt$PromptInfo$Builder;", jt)
                  end
                  JNIHelpers.with_jstring(env, config.description) do |jt|
                    JNIHelpers.call_object(env, builder.to_i64, "setDescription", "(Ljava/lang/CharSequence;)Landroidx/biometric/BiometricPrompt$PromptInfo$Builder;", jt)
                  end
                  JNIHelpers.with_jstring(env, config.cancel_title) do |jt|
                    JNIHelpers.call_object(env, builder.to_i64, "setNegativeButtonText", "(Ljava/lang/CharSequence;)Landroidx/biometric/BiometricPrompt$PromptInfo$Builder;", jt)
                  end
                  JNIHelpers.call_object(env, builder.to_i64, "build", "()Landroidx/biometric/BiometricPrompt$PromptInfo;")
                ensure
                  env.delete_local_ref(builder)
                end
              end
              next BiometricResult.new(success: false, error: BiometricError::NotAvailable) if prompt_info.null?

              JNIHelpers.with_class(env, "androidx/biometric/BiometricPrompt") do |prompt_class|
                next if prompt_class.null?
                # The real BiometricPrompt constructor takes a
                # FragmentActivity — the old code looked up a
                # ContextCompat signature (null method id → JNI abort).
                ctor = env.get_method_id(prompt_class, "<init>", "(Landroidx/fragment/app/FragmentActivity;Ljava/util/concurrent/Executor;Landroidx/biometric/BiometricPrompt$AuthenticationCallback;)V")
                next if ctor.null?
                biometric_prompt = env.new_object(prompt_class, ctor, activity, executor, callback_obj)
                next if biometric_prompt.null?
                begin
                  JNIHelpers.call_void(env, biometric_prompt.to_i64, "authenticate", "(Landroidx/biometric/BiometricPrompt$PromptInfo;)V", prompt_info)
                ensure
                  env.delete_local_ref(biometric_prompt)
                end
              end
            ensure
              env.delete_local_ref(callback_obj)
            end
          ensure
            env.delete_local_ref(executor)
          end
        end
        wait_result
      {% elsif flag?(:native_ios) %}
        result_code = LibIOS.authenticate_biometric(
          config.title.to_utf8,
          config.subtitle.to_utf8,
          config.description.to_utf8,
          config.cancel_title.to_utf8,
          config.fallback_title.to_utf8,
          config.allow_fallback
        )
        parse_result(result_code)
      {% else %}
        BiometricResult.new(success: false, error: BiometricError::NotAvailable)
      {% end %}
    end

    def self.authenticate_async(config : BiometricConfig = BiometricConfig.new, &callback : BiometricResult -> Nil) : Nil
      spawn do
        result = authenticate(config)
        callback.call(result)
      end
    end

    private def self.check_availability : Nil
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          activity = Native::Android::JNI.activity
          next if activity.null?

          manager = JNIHelpers.call_static_object(env, "androidx/biometric/BiometricManager", "from", "(Landroid/content/Context;)Landroidx/biometric/BiometricManager;", activity)
          next if manager.null?
          begin
            result = JNIHelpers.call_int(env, manager.to_i64, "canAuthenticate", "(I)I", 0)
            @@is_available = result == 0
            @@available_type = BiometricType::Fingerprint if @@is_available
          ensure
            env.delete_local_ref(manager)
          end
        end
      {% elsif flag?(:native_ios) %}
        result = LibIOS.get_biometric_type
        @@is_available = result != 0
        @@available_type = case result
                           when 1 then BiometricType::Fingerprint
                           when 2 then BiometricType::FaceID
                           else        BiometricType::None
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
