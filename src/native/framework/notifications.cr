# src/native/framework/notifications.cr

module Native::Notifications
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
    property importance : NotificationPriority
    property show_badge : Bool
    property sound : String?
    property vibration : Bool
    property light_color : UInt32?

    def initialize(@id : String, @name : String)
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

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        notif_class = env.find_class("com/nativecr/NotificationHelper")
        if notif_class == Pointer(Void).null
          return
        end

        init_method = env.get_static_method_id(notif_class, "init", "(Landroid/app/Activity;)V")
        env.call_static_void_method(notif_class, init_method, activity)

        channels.each do |channel|
          create_channel(channel)
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.notification_init
      {% end %}

      @@initialized = true
    end

    def self.create_channel(channel : NotificationChannel) : Nil
      {% unless flag?(:native_android) %}
        return
      {% end %}

      env = Native::Android::JNI.env
      return unless env

      notif_class = env.find_class("com/nativecr/NotificationHelper")
      if notif_class == Pointer(Void).null
        return
      end

      create_method = env.get_static_method_id(notif_class, "createChannel", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;IZZZLjava/lang/String;)V")
      env.call_static_void_method(notif_class, create_method,
        env.new_string_utf(channel.id),
        env.new_string_utf(channel.name),
        channel.description ? env.new_string_utf(channel.description.not_nil!) : Pointer(Void).null,
        channel.importance.value,
        channel.show_badge,
        channel.vibration,
        channel.sound ? true : false,
        channel.sound ? env.new_string_utf(channel.sound.not_nil!) : Pointer(Void).null
      )
    end

    def self.show(notification : Notification) : Bool
      return false unless @@initialized

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return false unless env

        notif_class = env.find_class("com/nativecr/NotificationHelper")
        if notif_class == Pointer(Void).null
          return false
        end

        show_method = env.get_static_method_id(notif_class, "showNotification", "(ILjava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;IIZLjava/lang/String;ZILjava/lang/String;ZLjava/lang/String;)V")

        env.call_static_void_method(notif_class, show_method,
          notification.id,
          env.new_string_utf(notification.channel_id),
          env.new_string_utf(notification.title),
          env.new_string_utf(notification.body),
          notification.subtitle ? env.new_string_utf(notification.subtitle.not_nil!) : Pointer(Void).null,
          notification.large_icon ? env.new_string_utf(notification.large_icon.not_nil!) : Pointer(Void).null,
          notification.small_icon ? env.new_string_utf(notification.small_icon.not_nil!) : Pointer(Void).null,
          notification.badge_number,
          notification.priority.value,
          notification.auto_cancel,
          notification.sound ? env.new_string_utf(notification.sound.not_nil!) : Pointer(Void).null,
          notification.vibration,
          notification.color || 0,
          notification.payload.to_json,
          notification.actions.any?,
          notification.actions.map(&.id).join(",")
        )
      {% elsif flag?(:native_ios) %}
        LibIOS.show_notification(notification.id, notification.title.to_utf8, notification.body.to_utf8, notification.badge_number, notification.sound.to_utf8, notification.payload.to_json.to_utf8)
      {% else %}
        false
      {% end %}
      true
    end

    def self.schedule(notification : Notification) : Bool
      return false unless notification.schedule_time

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return false unless env

        notif_class = env.find_class("com/nativecr/NotificationHelper")
        if notif_class == Pointer(Void).null
          return false
        end

        schedule_method = env.get_static_method_id(notif_class, "scheduleNotification", "(IJLjava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Z)V")

        timestamp = notification.schedule_time.not_nil!.to_unix * 1000
        env.call_static_void_method(notif_class, schedule_method,
          notification.id,
          timestamp,
          env.new_string_utf(notification.channel_id),
          env.new_string_utf(notification.title),
          env.new_string_utf(notification.body),
          notification.payload.to_json,
          notification.repeat_interval ? true : false
        )
      {% elsif flag?(:native_ios) %}
        trigger_time = notification.schedule_time.not_nil!.to_unix_f
        repeats = notification.repeat_interval ? notification.repeat_interval.not_nil!.to_i == 86400 : false
        LibIOS.schedule_notification(notification.id, notification.title.to_utf8, notification.body.to_utf8, trigger_time, repeats, notification.payload.to_json.to_utf8)
      {% else %}
        false
      {% end %}
      true
    end

    def self.cancel(id : Int32) : Nil
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env

        notif_class = env.find_class("com/nativecr/NotificationHelper")
        return if notif_class == Pointer(Void).null

        cancel_method = env.get_static_method_id(notif_class, "cancelNotification", "(I)V")
        env.call_static_void_method(notif_class, cancel_method, id)
      {% elsif flag?(:native_ios) %}
        LibIOS.cancel_notification(id)
      {% end %}
    end

    def self.cancel_all : Nil
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env

        notif_class = env.find_class("com/nativecr/NotificationHelper")
        return if notif_class == Pointer(Void).null

        cancel_method = env.get_static_method_id(notif_class, "cancelAllNotifications", "()V")
        env.call_static_void_method(notif_class, cancel_method)
      {% elsif flag?(:native_ios) %}
        LibIOS.cancel_all_notifications
      {% end %}
    end

    def self.set_badge_number(count : Int32) : Nil
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env

        notif_class = env.find_class("com/nativecr/NotificationHelper")
        return if notif_class == Pointer(Void).null

        badge_method = env.get_static_method_id(notif_class, "setBadgeNumber", "(I)V")
        env.call_static_void_method(notif_class, badge_method, count)
      {% elsif flag?(:native_ios) %}
        LibIOS.set_badge_number(count)
      {% end %}
    end

    def self.get_permission_status : Bool
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return false unless env && activity

        notif_manager = env.call_object_method(activity, env.get_method_id(env.get_object_class(activity), "getSystemService", "(Ljava/lang/String;)Ljava/lang/Object;"), env.new_string_utf("notification"))
        are_notifs_enabled = env.get_method_id(env.get_object_class(notif_manager), "areNotificationsEnabled", "()Z")
        env.call_boolean_method(notif_manager, are_notifs_enabled)
      {% elsif flag?(:native_ios) %}
        LibIOS.notification_permission_granted
      {% else %}
        false
      {% end %}
    end

    def self.request_permission : Bool
      {% if flag?(:native_android) %}
        true
      {% elsif flag?(:native_ios) %}
        LibIOS.request_notification_permission
      {% else %}
        false
      {% end %}
    end
  end

  module Notifications
    def self.initialize_default
      channel = NotificationChannel.new("default", "Default Notifications")
      channel.importance = NotificationPriority::High
      NotificationManager.initialize([channel])
    end

    def self.send(title : String, body : String, id : Int32 = Random.rand(1..Int32::MAX), channel_id : String = "default") : Bool
      notification = Notification.new
      notification.id = id
      notification.title = title
      notification.body = body
      notification.channel_id = channel_id
      NotificationManager.show(notification)
    end

    def self.send_simple(title : String, body : String, on_tap : -> Nil = nil) : Bool
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

    def self.schedule_reminder(title : String, body : String, at : Time, id : Int32 = Random.rand(1..Int32::MAX)) : Bool
      notification = Notification.new
      notification.id = id
      notification.title = title
      notification.body = body
      notification.schedule_time = at
      NotificationManager.schedule(notification)
    end

    def self.daily_reminder(title : String, body : String, hour : Int32, minute : Int32, id : Int32 = Random.rand(1..Int32::MAX)) : Bool
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

      notification = Notification.new
      notification.id = id
      notification.title = title
      notification.body = body
      notification.schedule_time = schedule_time
      notification.repeat_interval = 1.day
      NotificationManager.schedule(notification)
    end
  end
end
