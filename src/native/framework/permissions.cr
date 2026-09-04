# src/native/framework/permissions.cr
# Refactored to use JNIHelpers for automatic local reference cleanup.

module Native::Permissions
  enum PermissionType
    Camera
    Microphone
    Location
    LocationFine
    LocationCoarse
    Notifications
    Storage
    StorageRead
    StorageWrite
    Contacts
    Calendar
    CameraRoll
    Bluetooth
    Speech
    Motion
  end

  enum PermissionStatus
    Granted
    Denied
    Restricted
    NotDetermined
    Limited
  end

  class PermissionManager
    @@callbacks = {} of PermissionType => Array(PermissionStatus -> Nil)

    def self.check(type : PermissionType) : PermissionStatus
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          activity = Native::Android::JNI.activity
          return PermissionStatus::Denied if activity.null?

          result = JNIHelpers.with_jstring(env, permission_string(type)) do |jperm|
            JNIHelpers.call_int(env, activity.to_i64, "checkSelfPermission", "(Ljava/lang/String;)I", jperm)
          end

          case result
          when 0 then PermissionStatus::Granted
          when -1 then PermissionStatus::Denied
          else PermissionStatus::NotDetermined
          end
        end
      {% elsif flag?(:native_ios) %}
        status = LibIOS.check_permission(type.value)
        PermissionStatus.from_value(status)
      {% else %}
        PermissionStatus::NotDetermined
      {% end %}
    end

    def self.request(type : PermissionType, &callback : PermissionStatus -> Nil)
      status = check(type)

      if status != PermissionStatus::NotDetermined
        callback.call(status)
        return
      end

      @@callbacks[type] = [] of Proc(PermissionStatus, Nil) unless @@callbacks.has_key?(type)
      @@callbacks[type] << callback

      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          activity = Native::Android::JNI.activity
          return unless activity

          JNIHelpers.with_class(env, "java/lang/String") do |string_class|
            next if string_class.null?
            perm_array = env.new_object_array(1, string_class)
            next if perm_array.null?
            begin
              JNIHelpers.with_jstring(env, permission_string(type)) do |jperm|
                env.set_object_array_element(perm_array, 0, jperm)
              end
              JNIHelpers.call_void(env, activity.to_i64, "requestPermissions", "([Ljava/lang/String;I)V", perm_array, type.value)
            ensure
              env.delete_local_ref(perm_array)
            end
          end
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.request_permission(type.value)
      {% end %}
    end

    def self.request_multiple(types : Array(PermissionType), &callback : Hash(PermissionType, PermissionStatus) -> Nil)
      results = {} of PermissionType => PermissionStatus
      pending = types.size
      mutex = Mutex.new

      types.each do |type|
        request(type) do |status|
          mutex.synchronize do
            results[type] = status
            pending -= 1
            callback.call(results) if pending == 0
          end
        end
      end
    end

    def self.is_granted?(type : PermissionType) : Bool
      check(type) == PermissionStatus::Granted
    end

    def self.is_denied?(type : PermissionType) : Bool
      status = check(type)
      status == PermissionStatus::Denied || status == PermissionStatus::Restricted
    end

    def self.open_settings
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          activity = Native::Android::JNI.activity
          return unless activity

          JNIHelpers.with_class(env, "android/content/Intent") do |intent_class|
            next if intent_class.null?
            settings_fid = env.get_static_field_id(intent_class, "ACTION_APPLICATION_DETAILS_SETTINGS", "Ljava/lang/String;")
            next if settings_fid.null?
            action = env.get_static_object_field(intent_class, settings_fid)

            package_name = JNIHelpers.call_object(env, activity.to_i64, "getPackageName", "()Ljava/lang/String;")
            next if package_name.null?
            begin
              uri = JNIHelpers.with_jstring(env, "package:") do |jprefix|
                JNIHelpers.call_object(env, jprefix.to_i64, "concat", "(Ljava/lang/String;)Ljava/lang/String;", package_name)
              end
              next if uri.null?
              begin
                uri_obj = JNIHelpers.call_static_object(env, "android/net/Uri", "parse", "(Ljava/lang/String;)Landroid/net/Uri;", uri)
                next if uri_obj.null?
                begin
                  ctor = env.get_method_id(intent_class, "<init>", "(Ljava/lang/String;Landroid/net/Uri;)V")
                  next if ctor.null?
                  intent = env.new_object(intent_class, ctor, action, uri_obj)
                  next if intent.null?
                  begin
                    JNIHelpers.call_void(env, activity.to_i64, "startActivity", "(Landroid/content/Intent;)V", intent)
                  ensure
                    env.delete_local_ref(intent)
                  end
                ensure
                  env.delete_local_ref(uri_obj)
                end
              ensure
                env.delete_local_ref(uri)
              end
            ensure
              env.delete_local_ref(package_name)
            end
          end
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.open_settings
      {% end %}
    end

    private def self.permission_string(type : PermissionType) : String
      case type
      when PermissionType::Camera                                 then "android.permission.CAMERA"
      when PermissionType::Microphone                             then "android.permission.RECORD_AUDIO"
      when PermissionType::Location, PermissionType::LocationFine then "android.permission.ACCESS_FINE_LOCATION"
      when PermissionType::LocationCoarse                         then "android.permission.ACCESS_COARSE_LOCATION"
      when PermissionType::Storage                                then "android.permission.READ_EXTERNAL_STORAGE"
      when PermissionType::StorageRead                            then "android.permission.READ_EXTERNAL_STORAGE"
      when PermissionType::StorageWrite                           then "android.permission.WRITE_EXTERNAL_STORAGE"
      when PermissionType::Contacts                               then "android.permission.READ_CONTACTS"
      when PermissionType::Calendar                               then "android.permission.READ_CALENDAR"
      when PermissionType::Bluetooth                              then "android.permission.BLUETOOTH"
        # Android 13+ (API 33) requires POST_NOTIFICATIONS as a runtime permission.
      when PermissionType::Notifications then "android.permission.POST_NOTIFICATIONS"
      else                                    ""
      end
    end

    def self.handlePermissionResult(type : PermissionType, granted : Bool)
      status = granted ? PermissionStatus::Granted : PermissionStatus::Denied

      if callbacks = @@callbacks[type]?
        callbacks.each { |cb| cb.call(status) }
        @@callbacks.delete(type)
      end
    end
  end

  module Permissions
    def self.camera(&callback : PermissionStatus -> Nil)
      PermissionManager.request(PermissionType::Camera, &callback)
    end

    def self.camera_granted? : Bool
      PermissionManager.is_granted?(PermissionType::Camera)
    end

    def self.microphone(&callback : PermissionStatus -> Nil)
      PermissionManager.request(PermissionType::Microphone, &callback)
    end

    def self.microphone_granted? : Bool
      PermissionManager.is_granted?(PermissionType::Microphone)
    end

    def self.location(&callback : PermissionStatus -> Nil)
      PermissionManager.request(PermissionType::Location, &callback)
    end

    def self.location_granted? : Bool
      PermissionManager.is_granted?(PermissionType::Location)
    end

    def self.notifications(&callback : PermissionStatus -> Nil)
      PermissionManager.request(PermissionType::Notifications, &callback)
    end

    def self.notifications_granted? : Bool
      PermissionManager.is_granted?(PermissionType::Notifications)
    end

    def self.storage(&callback : PermissionStatus -> Nil)
      PermissionManager.request(PermissionType::Storage, &callback)
    end

    def self.storage_granted? : Bool
      PermissionManager.is_granted?(PermissionType::Storage)
    end
  end
end
