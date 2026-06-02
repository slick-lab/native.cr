# src/native/framework/notifications.cr

module Native
  module Notifications
    enum NotificationPriority
      Min
      Low
      Default
      High
      Max
    end

    enum NotificationVisibility
      Public
      Private
      Secret
    end

    struct NotificationAction
      property id : String
      property title : String
      property icon : String?
      property callback : -> Nil

      def initialize(@id : String, @title : String, @icon : String? = nil, &block : -> Nil)
        @callback = block
      end
    end

    struct NotificationChannel
      property id : String
      property name : String
      property description : String?
      property priority : NotificationPriority
      property importance : NotificationPriority
      property show_badge : Bool
      property sound : String?
      property vibration : Bool
      property light_color : UInt32?

      def initialize(@id : String, @name : String)
        @priority = NotificationPriority::Default
        @importance = NotificationPriority::Default
        @show_badge = true
        @vibration = true
      end
    end

    struct Notification
      property id : Int32 = 0
      property channel_id : String = "default"
      property title : String = ""
      property body : String = ""
      property subtitle : String? = nil
      property large_icon : String? = nil
      property small_icon : String? = nil
      property badge_number : Int32 = 0
      property priority : NotificationPriority = NotificationPriority::Default
      property visibility : NotificationVisibility = NotificationVisibility::Public
      property auto_cancel : Bool = true
      property sound : String? = nil
      property vibration : Bool = true
      property color : UInt32? = nil
      property actions : Array(NotificationAction) = [] of NotificationAction
      property payload : Hash(String, String) = {} of String => String
      property schedule_time : Time? = nil
      property repeat_interval : Time::Span? = nil

      def initialize
      end
    end

    class NotificationManager
      @@initialized : Bool = false

      def self.initialize(channels : Array(NotificationChannel) = [] of NotificationChannel) : Nil
        return if @@initialized
        
        {{ if flag?(:android) }}
          channels.each do |channel|
            LibNotifications.android_create_channel(
              channel.id.to_utf8,
              channel.name.to_utf8,
              channel.description.to_utf8?,
              channel.importance.to_i32,
              channel.show_badge,
              channel.sound.to_utf8?,
              channel.vibration,
              channel.light_color || 0
            )
          end
        {{ elsif flag?(:ios) }}
          LibNotifications.ios_request_permission
          setup_delegate
        {{ end }}
        
        @@initialized = true
      end

      def self.show(notification : Notification) : Bool
        return false unless @@initialized
        
        {{ if flag?(:android) }}
          action_titles = notification.actions.map(&.title.to_utf8)
          action_ids = notification.actions.map(&.id.to_utf8)
          
          LibNotifications.android_show_notification(
            notification.id,
            notification.channel_id.to_utf8,
            notification.title.to_utf8,
            notification.body.to_utf8,
            notification.subtitle.to_utf8?,
            notification.large_icon.to_utf8?,
            notification.small_icon.to_utf8?,
            notification.badge_number,
            notification.priority.to_i32,
            notification.visibility.to_i32,
            notification.auto_cancel,
            notification.sound.to_utf8?,
            notification.vibration,
            notification.color || 0,
            action_titles,
            action_ids,
            notification.actions.size,
            notification.payload.to_json.to_utf8
          )
        {{ elsif flag?(:ios) }}
          LibNotifications.ios_show_notification(
            notification.id,
            notification.title.to_utf8,
            notification.body.to_utf8,
            notification.badge_number,
            notification.sound.to_utf8?,
            notification.payload.to_json.to_utf8
          )
        {{ else }}
          return false
        {{ end }}
        
        true
      end

      def self.schedule(notification : Notification) : Bool
        return false unless notification.schedule_time
        
        {{ if flag?(:android) }}
          timestamp = notification.schedule_time.not_nil!.to_unix * 1000
          
          LibNotifications.android_schedule_notification(
            notification.id,
            timestamp,
            notification.repeat_interval.try(&.to_i),
            notification.channel_id.to_utf8,
            notification.title.to_utf8,
            notification.body.to_utf8,
            notification.payload.to_json.to_utf8
          )
        {{ elsif flag?(:ios) }}
          trigger = LibNotifications.ios_create_time_trigger(
            notification.schedule_time.not_nil!.to_unix_f,
            notification.repeat_interval.try(&.to_i) == 86400
          )
          
          LibNotifications.ios_schedule_notification(
            notification.id,
            notification.title.to_utf8,
            notification.body.to_utf8,
            trigger,
            notification.payload.to_json.to_utf8
          )
        {{ else }}
          return false
        {{ end }}
        
        true
      end

      def self.cancel(id : Int32) : Nil
        {{ if flag?(:android) }}
          LibNotifications.android_cancel_notification(id)
        {{ elsif flag?(:ios) }}
          LibNotifications.ios_cancel_notification(id)
        {{ end }}
      end

      def self.cancel_all : Nil
        {{ if flag?(:android) }}
          LibNotifications.android_cancel_all_notifications
        {{ elsif flag?(:ios) }}
          LibNotifications.ios_cancel_all_notifications
        {{ end }}
      end

      def self.set_badge_number(count : Int32) : Nil
        {{ if flag?(:android) }}
          LibNotifications.android_set_badge_number(count)
        {{ elsif flag?(:ios) }}
          LibNotifications.ios_set_badge_number(count)
        {{ end }}
      end

      def self.clear_badge : Nil
        set_badge_number(0)
      end

      def self.get_permission_status : Bool
        {{ if flag?(:android) }}
          LibNotifications.android_has_permission
        {{ elsif flag?(:ios) }}
          LibNotifications.ios_has_permission
        {{ else }}
          false
        {{ end }}
      end

      def self.request_permission : Bool
        {{ if flag?(:android) }}
          LibNotifications.android_request_permission
        {{ elsif flag?(:ios) }}
          LibNotifications.ios_request_permission
        {{ else }}
          false
        {{ end }}
      end

      @on_notification_callbacks = [] of (Notification -> Nil)
      @on_action_callbacks = [] of (String, Notification -> Nil)

      def self.on_notification(&block : Notification -> Nil) : Nil
        @on_notification_callbacks << block
        setup_delegate
      end

      def self.on_action(&block : String, Notification -> Nil) : Nil
        @on_action_callbacks << block
        setup_delegate
      end

      private def self.setup_delegate : Nil
        return if @delegate_setup
        
        {{ if flag?(:android) }}
          LibNotifications.android_set_notification_delegate(
            ->(action_id_ptr : UInt8*, payload_json_ptr : UInt8*) {
              handle_notification_action(action_id_ptr, payload_json_ptr)
            },
            ->(payload_json_ptr : UInt8*) {
              handle_notification_received(payload_json_ptr)
            }
          )
        {{ elsif flag?(:ios) }}
          LibNotifications.ios_set_notification_delegate(
            ->(action_id_ptr : UInt8*, payload_json_ptr : UInt8*) {
              handle_notification_action(action_id_ptr, payload_json_ptr)
            },
            ->(payload_json_ptr : UInt8*) {
              handle_notification_received(payload_json_ptr)
            }
          )
        {{ end }}
        
        @delegate_setup = true
      end

      private def self.handle_notification_action(action_id_ptr : UInt8*, payload_json_ptr : UInt8*) : Nil
        action_id = String.new(action_id_ptr)
        payload_json = String.new(payload_json_ptr)
        
        notification = Notification.new
        begin
          data = JSON.parse(payload_json)
          if data.as_h?
            notification.payload = data.as_h.transform_values(&.to_s)
          end
        rescue
        end
        
        @on_action_callbacks.each { |cb| cb.call(action_id, notification) }
        
        LibNotifications.free_string(action_id_ptr)
        LibNotifications.free_string(payload_json_ptr)
      end

      private def self.handle_notification_received(payload_json_ptr : UInt8*) : Nil
        payload_json = String.new(payload_json_ptr)
        
        notification = Notification.new
        begin
          data = JSON.parse(payload_json)
          if data.as_h?
            notification.payload = data.as_h.transform_values(&.to_s)
          end
        rescue
        end
        
        @on_notification_callbacks.each { |cb| cb.call(notification) }
        
        LibNotifications.free_string(payload_json_ptr)
      end

      @@delegate_setup = false
    end

    module Notifications
      def self.initialize_with_defaults : Nil
        channel = NotificationChannel.new("default", "Default Notifications")
        channel.priority = NotificationPriority::High
        channel.importance = NotificationPriority::High
        
        NotificationManager.initialize([channel])
      end

      def self.send(
        title : String,
        body : String,
        id : Int32 = Random.rand(1..Int32::MAX),
        channel_id : String = "default"
      ) : Bool
        notification = Notification.new
        notification.id = id
        notification.title = title
        notification.body = body
        notification.channel_id = channel_id
        
        NotificationManager.show(notification)
      end

      def self.send_simple(
        title : String,
        body : String,
        on_tap : -> Nil = nil
      ) : Bool
        id = Random.rand(1..Int32::MAX)
        
        if on_tap
          action = NotificationAction.new("tap", "Open") do
            on_tap.call
          end
          
          notification = Notification.new
          notification.id = id
          notification.title = title
          notification.body = body
          notification.actions = [action]
          NotificationManager.show(notification)
        else
          send(title, body, id)
        end
      end

      def self.schedule_reminder(
        title : String,
        body : String,
        at : Time,
        id : Int32 = Random.rand(1..Int32::MAX)
      ) : Bool
        notification = Notification.new
        notification.id = id
        notification.title = title
        notification.body = body
        notification.schedule_time = at
        
        NotificationManager.schedule(notification)
      end

      def self.schedule_repeating(
        title : String,
        body : String,
        interval : Time::Span,
        start_at : Time? = nil,
        id : Int32 = Random.rand(1..Int32::MAX)
      ) : Bool
        notification = Notification.new
        notification.id = id
        notification.title = title
        notification.body = body
        notification.schedule_time = start_at || Time.utc + 1.second
        notification.repeat_interval = interval
        
        NotificationManager.schedule(notification)
      end

      def self.daily_reminder(
        title : String,
        body : String,
        hour : Int32,
        minute : Int32,
        id : Int32 = Random.rand(1..Int32::MAX)
      ) : Bool
        now = Time.local
        schedule_time = Time.local(
          year: now.year,
          month: now.month,
          day: now.day,
          hour: hour,
          minute: minute,
          second: 0
        )
        
        if schedule_time <= now
          schedule_time = schedule_time + 1.day
        end
        
        schedule_repeating(title, body, 1.day, schedule_time, id)
      end
    end
  end
end
