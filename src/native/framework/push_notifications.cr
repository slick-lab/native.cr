# src/native/framework/push_notifications.cr
#
# Push notification support for native.cr.
#
# Covers two distinct channels:
#   1. Remote push (FCM on Android, APNs on iOS) — server-sent messages.
#   2. Local notification tap callbacks — user taps a displayed notification.
#
# ── Quick start ───────────────────────────────────────────────────────────────
#
#   class MyApp < Native::App
#     def setup
#       # Request permission (required on Android 13+ and all iOS versions).
#       Native::PushNotifications.request_permission do |granted|
#         if granted
#           # Get the device token to send to your server.
#           Native::PushNotifications.get_token do |token|
#             puts "FCM token: #{token}"
#             # → POST to your backend: register(device_id: token)
#           end
#         end
#       end
#
#       # React to incoming push messages (foreground only).
#       Native::PushNotifications.on_message do |msg|
#         puts "Push: #{msg.title} — #{msg.body}"
#         puts "Data: #{msg.payload}"
#       end
#
#       # React when the user taps a notification.
#       Native::PushNotifications.on_tap do |payload, id|
#         puts "Notification #{id} tapped, payload: #{payload}"
#       end
#     end
#   end
#
# ── Threading contract ────────────────────────────────────────────────────────
#
# The Java bridge (PushManager / FcmService / NotificationReceiver) posts every
# native callback to the Android main thread before it reaches the `fun`s
# below. That keeps the JNI environment handle valid (it is only usable on the
# thread that obtained it) and matches the threading model of every other
# framework callback. User callbacks therefore also fire on the main thread.

module Native
  module PushNotifications
    # Received push message.
    struct Message
      getter title   : String
      getter body    : String
      getter payload : String  # JSON string from the data map

      def initialize(@title, @body, @payload)
      end
    end

    # ── Internal callback storage ─────────────────────────────────────────
    @@on_message_cb    : (Message -> Nil)?         = nil
    @@on_tap_cb        : (String, Int32 -> Nil)?   = nil
    @@on_token_cb      : (String -> Nil)?          = nil
    @@on_token_refresh_cb : (String -> Nil)?       = nil
    @@on_permission_cb : (Bool -> Nil)?            = nil

    # ── Public API ─────────────────────────────────────────────────────────

    # Request push notification permission from the user.
    # On Android <13 this always yields `true` immediately.
    # On Android 13+ it shows the system permission dialog.
    # On iOS it shows the native permission prompt.
    def self.request_permission(&callback : Bool -> Nil)
      @@on_permission_cb = callback

      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          activity = Native::Android::JNI.activity
          if activity.null?
            @@on_permission_cb.try &.call(false)
            next
          end

          # Android 13+ (API 33): POST_NOTIFICATIONS is a runtime permission.
          sdk_int = JNIHelpers.with_class(env, "android/os/Build$VERSION") do |build_class|
            next -1 if build_class.null?
            sdk_field = env.get_static_field_id(build_class, "SDK_INT", "I")
            next -1 if sdk_field.null?
            env.get_static_int_field(build_class, sdk_field)
          end

          if sdk_int == -1
            # Build.VERSION lookup failed — assume the manifest asked for
            # POST_NOTIFICATIONS and let the OS decide.
            @@on_permission_cb.try &.call(true)
          elsif sdk_int >= 33
            Native::Permissions::PermissionManager.request(
              Native::Permissions::PermissionType::Notifications
            ) do |status|
              granted = status == Native::Permissions::PermissionStatus::Granted
              @@on_permission_cb.try &.call(granted)
            end
          else
            # Pre-13: permission is granted at install time.
            @@on_permission_cb.try &.call(true)
          end
        end
      {% elsif flag?(:native_ios) %}
        granted = LibIOS.request_notification_permission
        @@on_permission_cb.try &.call(granted)
      {% else %}
        @@on_permission_cb.try &.call(true)
      {% end %}
    end

    # Retrieve the FCM (Android) or APNs (iOS) device token asynchronously.
    # The token is needed to send push notifications from your server.
    # Yields "" when Firebase is unavailable or the bridge is missing.
    def self.get_token(&callback : String -> Nil)
      @@on_token_cb = callback

      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          activity = Native::Android::JNI.activity
          if activity.null?
            @@on_token_cb.try &.call("")
            next
          end

          JNIHelpers.with_class(env, "com/nativecr/PushManager") do |push_class|
            if push_class.null?
              @@on_token_cb.try &.call("")
              next
            end

            get_token_method = env.get_static_method_id(
              push_class, "getToken", "(Landroid/app/Activity;)V")
            if get_token_method.null?
              @@on_token_cb.try &.call("")
              next
            end

            env.call_static_void_method(push_class, get_token_method, activity)
            # Result fires via nativeOnTokenReady JNI callback → handle_token_ready
          end
        end
      {% elsif flag?(:native_ios) %}
        # iOS token arrives via AppDelegate callback — bridge not shown here.
        @@on_token_cb.try &.call("")
      {% else %}
        @@on_token_cb.try &.call("desktop-no-token")
      {% end %}
    end

    # Register a callback for messages received while the app is in the
    # foreground. Does NOT fire for background/quit-state messages (those
    # arrive via `on_tap` when the user taps the notification).
    def self.on_message(&callback : Message -> Nil)
      @@on_message_cb = callback
    end

    # Register a callback for when the user taps a notification.
    # `payload` is a JSON string; `id` is the notification id.
    def self.on_tap(&callback : String, Int32 -> Nil)
      @@on_tap_cb = callback
    end

    # Register a callback for FCM token rotation (onNewToken). A rotated
    # token must be re-registered with your backend.
    def self.on_token_refresh(&callback : String -> Nil)
      @@on_token_refresh_cb = callback
    end

    # ── JNI entry points (called from the Java bridge, main thread) ───────
    # User callbacks are wrapped in rescue so an exception in app code can
    # never unwind through the JNI boundary and kill the VM.

    # :nodoc:
    def self.handle_token_ready(token : String) : Nil
      @@on_token_cb.try do |cb|
        begin
          cb.call(token)
        rescue e
          Log.warn { "push on_token callback raised: #{e.message}" }
        end
      end
    end

    # :nodoc:
    def self.handle_token_refresh(token : String) : Nil
      @@on_token_refresh_cb.try do |cb|
        begin
          cb.call(token)
        rescue e
          Log.warn { "push on_token_refresh callback raised: #{e.message}" }
        end
      end
    end

    # :nodoc:
    def self.handle_message_received(title : String, body : String, payload : String) : Nil
      msg = Message.new(title, body, payload)
      @@on_message_cb.try do |cb|
        begin
          cb.call(msg)
        rescue e
          Log.warn { "push on_message callback raised: #{e.message}" }
        end
      end
    end

    # :nodoc:
    def self.handle_notification_tapped(payload : String, id : Int32) : Nil
      @@on_tap_cb.try do |cb|
        begin
          cb.call(payload, id)
        rescue e
          Log.warn { "push on_tap callback raised: #{e.message}" }
        end
      end
    end
  end
end

# ── JNI export functions ────────────────────────────────────────────────────
# These Crystal `fun` declarations are the symbols that Java calls via JNI.
# The names follow the JNI convention: Java_<pkg>_<ClassName>_<methodName>.
#
# The Java bridge posts all of these onto the Android main thread before
# invoking them, so the cached JNI environment is always valid here.

{% if flag?(:native_android) %}
  fun native_on_token_ready =
    "Java_com_nativecr_PushManager_nativeOnTokenReady"(
      env : Void*, cls : Void*, token_j : Void*
    ) : Void
    token_s = Native::Android::JNI.get_string_utf_chars(token_j)
    Native::PushNotifications.handle_token_ready(token_s)
  end

  fun native_on_token_refresh =
    "Java_com_nativecr_FcmService_nativeOnTokenRefresh"(
      env : Void*, cls : Void*, token_j : Void*
    ) : Void
    token_s = Native::Android::JNI.get_string_utf_chars(token_j)
    Native::PushNotifications.handle_token_refresh(token_s)
  end

  fun native_on_message_received =
    "Java_com_nativecr_FcmService_nativeOnMessageReceived"(
      env : Void*, cls : Void*, title_j : Void*, body_j : Void*, payload_j : Void*
    ) : Void
    title   = Native::Android::JNI.get_string_utf_chars(title_j)
    body    = Native::Android::JNI.get_string_utf_chars(body_j)
    payload = Native::Android::JNI.get_string_utf_chars(payload_j)
    Native::PushNotifications.handle_message_received(title, body, payload)
  end

  fun native_on_notification_tapped =
    "Java_com_nativecr_NotificationReceiver_nativeOnNotificationTapped"(
      env : Void*, cls : Void*, payload_j : Void*, id : Int32
    ) : Void
    payload = Native::Android::JNI.get_string_utf_chars(payload_j)
    Native::PushNotifications.handle_notification_tapped(payload, id)
  end
{% end %}
