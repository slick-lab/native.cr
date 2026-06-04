# src/native/framework/permissions.cr

module Native
  module Permissions
    enum PermissionType
      Camera
      Microphone
      Location
      LocationAlways
      Notifications
      Storage
      StorageRead
      StorageWrite
      Contacts
      Calendar
      CameraRoll
      Bluetooth
      SpeechRecognition
      MotionActivity
      Reminders
      Siri
      MediaLibrary
    end

    enum PermissionStatus
      Granted
      Denied
      Restricted
      NotDetermined
      Limited
    end

    struct PermissionInfo
      property type : PermissionType
      property status : PermissionStatus
      property can_request : Bool
      property is_granted : Bool
      property is_denied : Bool

      def initialize(@type = PermissionType::Camera, @status = PermissionStatus::NotDetermined,
                     @can_request = true, @is_granted = false, @is_denied = false)
      end
    end

    class PermissionManager
      @@callbacks = {} of PermissionType => Array(PermissionStatus -> Nil)

      def self.check(type : PermissionType) : PermissionStatus
        {% if flag?(:android) %}
          result = LibPermissions.android_check_permission(type.to_i32)
        {% elsif flag?(:ios) %}
          result = LibPermissions.ios_check_permission(type.to_i32)
        {% else %}
          result = 0
        {% end %}
        
        PermissionStatus.from_value(result)
      end

      def self.request(type : PermissionType, &callback : PermissionStatus -> Nil) : Nil
        status = check(type)
        
        if status != PermissionStatus::NotDetermined
          callback.call(status)
          return
        end
        
        @@callbacks[type] = [] of PermissionStatus -> Nil unless @@callbacks.has_key?(type)
        @@callbacks[type] << callback
        
        {% if flag?(:android) %}
          LibPermissions.android_request_permission(type.to_i32)
        {% elsif flag?(:ios) %}
          LibPermissions.ios_request_permission(type.to_i32)
        {% end %}
      end

      def self.request_multiple(types : Array(PermissionType), &callback : Hash(PermissionType, PermissionStatus) -> Nil) : Nil
        results = {} of PermissionType => PermissionStatus
        pending = types.size
        mutex = Mutex.new
        
        types.each do |type|
          request(type) do |status|
            mutex.synchronize do
              results[type] = status
              pending -= 1
              
              if pending == 0
                callback.call(results)
              end
            end
          end
        end
      end

      def self.check_info(type : PermissionType) : PermissionInfo
        status = check(type)
        
        info = PermissionInfo.new(
          type: type,
          status: status,
          is_granted: status == PermissionStatus::Granted,
          is_denied: status == PermissionStatus::Denied,
          can_request: status == PermissionStatus::NotDetermined
        )
        
        info
      end

      def self.is_granted?(type : PermissionType) : Bool
        check(type) == PermissionStatus::Granted
      end

      def self.is_denied?(type : PermissionType) : Bool
        status = check(type)
        status == PermissionStatus::Denied || status == PermissionStatus::Restricted
      end

      def self.open_settings : Bool
        {% if flag?(:android) %}
          LibPermissions.android_open_settings
        {% elsif flag?(:ios) %}
          LibPermissions.ios_open_settings
        {% else %}
          false
        {% end %}
      end

      def self.should_show_rationale?(type : PermissionType) : Bool
        {% if flag?(:android) %}
          LibPermissions.android_should_show_rationale(type.to_i32)
        {% else %}
          false
        {% end %}
      end

      private def self.handle_permission_result(type : PermissionType, granted : Bool) : Nil
        status = granted ? PermissionStatus::Granted : PermissionStatus::Denied
        
        if callbacks = @@callbacks[type]?
          callbacks.each { |cb| cb.call(status) }
          @@callbacks.delete(type)
        end
      end
    end

    module Permissions
      def self.check_camera : PermissionStatus
        PermissionManager.check(PermissionType::Camera)
      end

      def self.request_camera(&callback : PermissionStatus -> Nil) : Nil
        PermissionManager.request(PermissionType::Camera, &callback)
      end

      def self.has_camera? : Bool
        PermissionManager.is_granted?(PermissionType::Camera)
      end

      def self.check_microphone : PermissionStatus
        PermissionManager.check(PermissionType::Microphone)
      end

      def self.request_microphone(&callback : PermissionStatus -> Nil) : Nil
        PermissionManager.request(PermissionType::Microphone, &callback)
      end

      def self.has_microphone? : Bool
        PermissionManager.is_granted?(PermissionType::Microphone)
      end

      def self.check_location : PermissionStatus
        PermissionManager.check(PermissionType::Location)
      end

      def self.request_location(&callback : PermissionStatus -> Nil) : Nil
        PermissionManager.request(PermissionType::Location, &callback)
      end

      def self.has_location? : Bool
        PermissionManager.is_granted?(PermissionType::Location)
      end

      def self.check_notifications : PermissionStatus
        PermissionManager.check(PermissionType::Notifications)
      end

      def self.request_notifications(&callback : PermissionStatus -> Nil) : Nil
        PermissionManager.request(PermissionType::Notifications, &callback)
      end

      def self.has_notifications? : Bool
        PermissionManager.is_granted?(PermissionType::Notifications)
      end

      def self.check_storage : PermissionStatus
        PermissionManager.check(PermissionType::Storage)
      end

      def self.request_storage(&callback : PermissionStatus -> Nil) : Nil
        PermissionManager.request(PermissionType::Storage, &callback)
      end

      def self.has_storage? : Bool
        PermissionManager.is_granted?(PermissionType::Storage)
      end

      def self.check_contacts : PermissionStatus
        PermissionManager.check(PermissionType::Contacts)
      end

      def self.request_contacts(&callback : PermissionStatus -> Nil) : Nil
        PermissionManager.request(PermissionType::Contacts, &callback)
      end

      def self.has_contacts? : Bool
        PermissionManager.is_granted?(PermissionType::Contacts)
      end

      def self.request_all_required(&callback : Bool -> Nil) : Nil
        required = [] of PermissionType
        
        if CameraModule.has_permission? == false
          required << PermissionType::Camera
        end
        
        if Audio.has_permission? == false
          required << PermissionType::Microphone
        end
        
        if Notifications::NotificationManager.get_permission_status == false
          required << PermissionType::Notifications
        end
        
        if required.empty?
          callback.call(true)
          return
        end
        
        PermissionManager.request_multiple(required) do |results|
          all_granted = results.all? { |_, status| status == PermissionStatus::Granted }
          callback.call(all_granted)
        end
      end

      def self.show_rationale_dialog(type : PermissionType) : Nil
        return unless PermissionManager.should_show_rationale?(type)
        
        message = case type
                  when PermissionType::Camera
                    "This app needs camera access to take photos and scan documents"
                  when PermissionType::Microphone
                    "This app needs microphone access to record audio"
                  when PermissionType::Location
                    "This app needs location access to show nearby places"
                  when PermissionType::Notifications
                    "This app needs notification access to send you alerts"
                  when PermissionType::Storage
                    "This app needs storage access to save files and photos"
                  when PermissionType::Contacts
                    "This app needs contacts access to find your friends"
                  else
                    "This app needs permission to function properly"
                  end
        
        Dialog.show(
          title: "Permission Required",
          message: message,
          buttons: [
            DialogButton.new("Cancel", DialogAction::Negative) { },
            DialogButton.new("Allow", DialogAction::Positive) {
              PermissionManager.request(type) { |_| }
            }
          ]
        )
      end
    end

    # Platform callbacks for permission results
    {% if flag?(:android) %}
      @[Export("native_cr_permission_result")]
      fun native_cr_permission_result(permission_type : Int32, granted : Bool) : Void
        PermissionManager.handle_permission_result(PermissionType.from_value(permission_type), granted)
      end
    {% elsif flag?(:ios) %}
      # iOS delegates will call back through the bridge
    {% end %}
  end
end
