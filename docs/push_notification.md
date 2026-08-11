# Push Notifications

native.cr supports both **remote push notifications** (FCM on Android, APNs on iOS) and **local notifications** with scheduling. They share a unified Crystal API.

---

## Local notifications (no server needed)

```crystal
class MyApp < Native::App
  def setup
    # 1. Request permission (required on Android 13+ and all iOS).
    Native::PushNotifications.request_permission do |granted|
      next unless granted

      # 2. Initialize the notification manager with a channel.
      channel = Native::Notifications::NotificationChannel.new("alerts", "Alerts")
      channel.importance = Native::Notifications::NotificationPriority::High
      Native::Notifications::NotificationManager.initialize([channel])

      # 3. Show a notification immediately.
      Native::Notifications::Notifications.send("Hello!", "This is a local notification")

      # 4. Schedule one for later.
      Native::Notifications::Notifications.schedule_reminder(
        "Reminder", "Time to check in!", at: Time.local + 10.minutes
      )
    end

    # 5. Handle taps.
    Native::PushNotifications.on_tap do |payload, id|
      puts "Notification #{id} tapped — payload: #{payload}"
    end
  end
end
```

---

## Remote push notifications (FCM)

### Android setup

**1. Create a Firebase project** at [console.firebase.google.com](https://console.firebase.google.com), register your Android app, and download `google-services.json` into `android/app/`.

**2. Update `android/build.gradle` (project level):**

```groovy
buildscript {
  dependencies {
    classpath 'com.google.gms:google-services:4.4.0'
  }
}
```

**3. Update `android/app/build.gradle`:**

```groovy
apply plugin: 'com.google.gms.google-services'

dependencies {
  implementation 'com.google.firebase:firebase-messaging:23.4.0'
}
```

**4. Register `FcmService` in `AndroidManifest.xml`:**

```xml
<service
    android:name="com.nativecr.FcmService"
    android:exported="false">
  <intent-filter>
    <action android:name="com.google.firebase.MESSAGING_EVENT" />
  </intent-filter>
</service>
```

Also add the permission (needed on Android 13+):

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### Crystal usage

```crystal
class MyApp < Native::App
  def setup
    # 1. Request permission.
    Native::PushNotifications.request_permission do |granted|
      next unless granted

      # 2. Get the device token and send to your server.
      Native::PushNotifications.get_token do |token|
        puts "Register this token with your server: #{token}"
        # → HTTP POST to your backend
      end
    end

    # 3. Handle foreground messages (fires when app is open).
    Native::PushNotifications.on_message do |msg|
      puts "Push received: #{msg.title}"
      puts "Body:    #{msg.body}"
      puts "Payload: #{msg.payload}"  # JSON string from the data map
    end

    # 4. Handle tap on a notification (background or foreground).
    Native::PushNotifications.on_tap do |payload, id|
      parsed = JSON.parse(payload)
      # → navigate to the relevant screen
    end
  end
end

Native::App.registered_subclass = MyApp
```

---

## API reference

### `Native::PushNotifications`

| Method | Description |
|---|---|
| `request_permission { \|granted\| }` | Ask for push notification permission. Fires immediately on Android <13. |
| `get_token { \|token\| }` | Retrieve the FCM/APNs device token. Required to send server push. |
| `on_message { \|msg\| }` | Callback for foreground push messages (`msg.title`, `msg.body`, `msg.payload`). |
| `on_tap { \|payload, id\| }` | Callback when user taps any notification. |

### `Native::Notifications::NotificationManager`

| Method | Description |
|---|---|
| `initialize(channels)` | Set up notification manager and create channels. |
| `show(notification)` | Show a notification immediately. |
| `schedule(notification)` | Show at a future time (uses `notification.schedule_time`). |
| `cancel(id)` | Cancel a notification (and its alarm if scheduled). |
| `cancel_all` | Cancel all pending notifications. |

### `Native::Notifications::Notifications` (convenience)

| Method | Description |
|---|---|
| `send(title, body)` | One-liner: show an immediate notification. |
| `schedule_reminder(title, body, at:)` | One-liner: schedule at a specific `Time`. |
| `daily_reminder(title, body, hour:, minute:)` | Schedule a daily repeating reminder. |

---

## How the tap bridge works

When a user taps a notification, Android fires the `NotificationReceiver` broadcast receiver, which calls `nativeOnNotificationTapped(payload, id)`. This JNI symbol is exported by `push_notifications.cr` and routes to `Native::PushNotifications.on_tap`.

The bridge is safe: if the native library isn't loaded yet (e.g. cold start from a notification tap), the Java side catches `UnsatisfiedLinkError` and logs rather than crashing.

---

## Scheduling (Android)

`scheduleNotification` uses `AlarmManager.setExactAndAllowWhileIdle` on Android 6.0+ for precise delivery even in Doze mode. Repeating reminders use `setRepeating` with a one-day interval.

Note: On Android 12+ (API 31+) your app needs `SCHEDULE_EXACT_ALARM` or `USE_EXACT_ALARM` permission to use exact alarms. Add to `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```
