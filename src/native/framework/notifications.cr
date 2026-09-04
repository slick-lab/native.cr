# src/native/framework/notifications.cr
# Refactored to use JNIHelpers for automatic local reference cleanup.
# Also fixed: delete_local_ref statements that had been inserted in the
# middle of argument lists (parse errors), and raw Crystal strings
# (payload.to_json, joined action ids) passed where the JNI signature
# wants jstrings — jvalues would have silently passed NULL.

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
        JNIHelpers.with_env do |env|
          activity = Native::Android::JNI.activity
          next unless activity

          JNIHelpers.call_static_void(env, "com/nativecr/NotificationHelper", "init", "(Landroid/app/Activity;)V", activity)

          channels.each do |channel|
            create_channel(channel)
          end
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

      JNIHelpers.with_env do |env|
        JNIHelpers.with_class(env, "com/nativecr/NotificationHelper") do |notif_class|
          next if notif_class.null?
          create_method = env.get_static_method_id(notif_class, "createChannel", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;IZZZLjava/lang/String;)V")
          next if create_method.null?

          JNIHelpers.with_jstring(env, channel.id) do |jid|
            JNIHelpers.with_jstring(env, channel.name) do |jname|
              jdesc = channel.description ? env.new_string_utf(channel.description.not_nil!) : Pointer(Void).null
              jsound = channel.sound ? env.new_string_utf(channel.sound.not_nil!) : Pointer(Void).null
              begin
                env.call_static_void_method(notif_class, create_method,
                  jid, jname, jdesc, channel.importance.value,
                  channel.show_badge, channel.vibration,
                  channel.sound ? true : false, jsound)
              ensure
                env.delete_local_ref(jsound) unless jsound.null?
                env.delete_local_ref(jdesc) unless jdesc.null?
              end
            end
          end
        end
      end
    end

    def self.show(notification : Notification) : Bool
      return false unless @@initialized

      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          JNIHelpers.with_class(env, "com/nativecr/NotificationHelper") do |notif_class|
            next false if notif_class.null?
            show_method = env.get_static_method_id(notif_class, "showNotification", "(ILjava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;IIZLjava/lang/String;ZILjava/lang/String;ZLjava/lang/String;)V")
            next false if show_method.null?

            args = JNIHelpers.with_jstring(env, notification.channel_id) do |jchannel|
              JNIHelpers.with_jstring(env, notification.title) do |jtitle|
                JNIHelpers.with_jstring(env, notification.body) do |jbody|
                  jsubtitle = notification.subtitle ? env.new_string_utf(notification.subtitle.not_nil!) : Pointer(Void).null
                  jlarge = notification.large_icon ? env.new_string_utf(notification.large_icon.not_nil!) : Pointer(Void).null
                  jsmall = notification.small_icon ? env.new_string_utf(notification.small_icon.not_nil!) : Pointer(Void).null
                  jsound = notification.sound ? env.new_string_utf(notification.sound.not_nil!) : Pointer(Void).null
                  jpayload = env.new_string_utf(notification.payload.to_json)
                  jactions = env.new_string_utf(notification.actions.map(&.id).join(","))
                  begin
                    env.call_static_void_method(notif_class, show_method,
                      notification.id, jchannel, jtitle, jbody,
                      jsubtitle, jlarge, jsmall,
                      notification.badge_number,
                      notification.priority.value,
                      notification.auto_cancel,
                      jsound, notification.vibration,
                      notification.color || 0,
                      jpayload, notification.actions.any?, jactions
                    )
                  ensure
                    env.delete_local_ref(jpayload) unless jpayload.null?
                    env.delete_local_ref(jactions) unless jactions.null?
                    env.delete_local_ref(jsound) unless jsound.null?
                    env.delete_local_ref(jsmall) unless jsmall.null?
                    env.delete_local_ref(jlarge) unless jlarge.null?
                    env.delete_local_ref(jsubtitle) unless jsubtitle.null?
                  end
                  true
                end
              end
            end
            !!args
          end
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.show_notification(notification.id, notification.title.to_utf8, notification.body.to_utf8, notification.badge_number, notification.sound.to_utf8, notification.payload.to_json.to_utf8)
      {% else %}
        false
      {% end %}
    end

    def self.schedule(notification : Notification) : Bool
      return false unless notification.schedule_time

      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          JNIHelpers.with_class(env, "com/nativecr/NotificationHelper") do |notif_class|
            next false if notif_class.null?
            schedule_method = env.get_static_method_id(notif_class, "scheduleNotification", "(IJLjava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Z)V")
            next false if schedule_method.null?

            timestamp = notification.schedule_time.not_nil!.to_unix * 1000
            JNIHelpers.with_jstring(env, notification.channel_id) do |jchannel|
              JNIHelpers.with_jstring(env, notification.title) do |jtitle|
                JNIHelpers.with_jstring(env, notification.body) do |jbody|
                  jpayload = env.new_string_utf(notification.payload.to_json)
                  begin
                    env.call_static_void_method(notif_class, schedule_method,
                      notification.id, timestamp, jchannel, jtitle, jbody, jpayload,
                      notification.repeat_interval ? true : false
                    )
                  ensure
                    env.delete_local_ref(jpayload) unless jpayload.null?
                  end
                end
              end
            end
            true
          end
        end
      {% elsif flag?(:native_ios) %}
        trigger_time = notification.schedule_time.not_nil!.to_unix_f
        repeats = notification.repeat_interval ? notification.repeat_interval.not_nil!.to_i == 86400 : false
        LibIOS.schedule_notification(notification.id, notification.title.to_utf8, notification.body.to_utf8, trigger_time, repeats, notification.payload.to_json.to_utf8)
      {% else %}
        false
      {% end %}
    end

    def self.cancel(id : Int32) : Nil
      {% if flag?(:native_android) %}
        JNIHelpers.call_static_void(env, "com/nativecr/NotificationHelper", "cancelNotification", "(I)V", id)
      {% elsif flag?(:native_ios) %}
        LibIOS.cancel_notification(id)
      {% end %}
    end

    def self.cancel_all : Nil
      {% if flag?(:native_android) %}
        JNIHelpers.call_static_void(env, "com/nativecr/NotificationHelper", "cancelAllNotifications", "()V")
      {% elsif flag?(:native_ios) %}
        LibIOS.cancel_all_notifications
      {% end %}
    end

    def self.set_badge_number(count : Int32) : Nil
      {% if flag?(:native_android) %}
        JNIHelpers.call_static_void(env, "com/nativecr/NotificationHelper", "setBadgeNumber", "(I)V", count)
      {% elsif flag?(:native_ios) %}
        LibIOS.set_badge_number(count)
      {% end %}
    end

    def self.get_permission_status : Bool
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          activity = Native::Android::JNI.activity
          next false if activity.null?

          notif_manager = JNIHelpers.with_jstring(env, "notification") do |jname|
            JNIHelpers.call_object(env, activity.to_i64, "getSystemService", "(Ljava/lang/String;)Ljava/lang/Object;", jname)
          end
          next false if notif_manager.null?
          begin
            JNIHelpers.call_boolean(env, notif_manager.to_i64, "areNotificationsEnabled", "()Z")
          ensure
            env.delete_local_ref(notif_manager)
          end
        end
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
