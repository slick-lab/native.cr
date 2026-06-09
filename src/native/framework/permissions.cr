# src/native/framework/permissions.cr

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
      if Native::Platform.android?
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return PermissionStatus::Denied unless env && activity

        perm_name = permission_string(type)
        check_permission = env.GetMethodID(env.GetObjectClass(activity), "checkSelfPermission", "(Ljava/lang/String;)I")
        result = env.CallIntMethod(activity, check_permission, env.NewStringUTF(perm_name))

        case result
        when 0 then PermissionStatus::Granted
        when -1 then PermissionStatus::Denied
        else PermissionStatus::NotDetermined
        end
      elsif Native::Platform.ios?
        status = LibIOS.check_permission(type.value)
        PermissionStatus.from_value(status)
      else
        PermissionStatus::NotDetermined
      end
    end

    def self.request(type : PermissionType, &callback : PermissionStatus -> Nil)
      status = check(type)

      if status != PermissionStatus::NotDetermined
        callback.call(status)
        return
      end

      @@callbacks[type] = [] of PermissionStatus -> Nil unless @@callbacks.has_key?(type)
      @@callbacks[type] << callback

      if Native::Platform.android?
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        perm_name = permission_string(type)
        request_perms = env.GetMethodID(env.GetObjectClass(activity), "requestPermissions", "([Ljava/lang/String;I)V")
        perm_array = env.NewObjectArray(1, env.FindClass("java/lang/String"), nil)
        env.SetObjectArrayElement(perm_array, 0, env.NewStringUTF(perm_name))
        env.CallVoidMethod(activity, request_perms, perm_array, type.value)
      elsif Native::Platform.ios?
        LibIOS.request_permission(type.value)
      end
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
      if Native::Platform.android?
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        intent_class = env.FindClass("android/content/Intent")
        settings_action = env.GetStaticFieldID(intent_class, "ACTION_APPLICATION_DETAILS_SETTINGS", "Ljava/lang/String;")
        action = env.GetStaticObjectField(intent_class, settings_action)

        uri_class = env.FindClass("android/net/Uri")
        parse_method = env.GetStaticMethodID(uri_class, "parse", "(Ljava/lang/String;)Landroid/net/Uri;")
        package_name = env.CallObjectMethod(activity, env.GetMethodID(env.GetObjectClass(activity), "getPackageName", "()Ljava/lang/String;"))
        uri = env.CallStaticObjectMethod(uri_class, parse_method, env.NewStringUTF("package:"), package_name)

        intent = env.NewObject(intent_class, env.GetMethodID(intent_class, "<init>", "(Ljava/lang/String;Landroid/net/Uri;)V"), action, uri)
        start_activity = env.GetMethodID(env.GetObjectClass(activity), "startActivity", "(Landroid/content/Intent;)V")
        env.CallVoidMethod(activity, start_activity, intent)
      elsif Native::Platform.ios?
        LibIOS.open_settings
      end
    end

    private def self.permission_string(type : PermissionType) : String
      case type
      when PermissionType::Camera then "android.permission.CAMERA"
      when PermissionType::Microphone then "android.permission.RECORD_AUDIO"
      when PermissionType::Location, PermissionType::LocationFine then "android.permission.ACCESS_FINE_LOCATION"
      when PermissionType::LocationCoarse then "android.permission.ACCESS_COARSE_LOCATION"
      when PermissionType::Storage then "android.permission.READ_EXTERNAL_STORAGE"
      when PermissionType::StorageRead then "android.permission.READ_EXTERNAL_STORAGE"
      when PermissionType::StorageWrite then "android.permission.WRITE_EXTERNAL_STORAGE"
      when PermissionType::Contacts then "android.permission.READ_CONTACTS"
      when PermissionType::Calendar then "android.permission.READ_CALENDAR"
      when PermissionType::Bluetooth then "android.permission.BLUETOOTH"
      else ""
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
