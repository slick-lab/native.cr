# Notifications

native.cr lets you send local push notifications — alerts that appear in the device's notification tray even when your app is in the background.

> **Note:** These are *local* notifications scheduled by the device. They do not require a server or internet connection. For *push* notifications from a server (APNs, FCM), you would need additional setup not covered here.

---

## Setup

Before sending any notification, call `initialize` once — ideally in your `setup` method:

```crystal
def setup
  Native::Notifications::Notifications.initialize_default
  # ...rest of setup
end
```

`initialize_default` creates a single channel called `"default"` with high priority. That is all you need for most apps.

---

## Sending a simple notification

```crystal
Native::Notifications::Notifications.send(
  title: "Hello!",
  body: "This is a local notification."
)
```

The notification appears immediately in the tray.

---

## Scheduling a notification for later

```crystal
# Send a reminder in 1 hour
remind_at = Time.utc + 1.hour

Native::Notifications::Notifications.schedule_reminder(
  title: "Time to stretch!",
  body: "You've been sitting for an hour.",
  at: remind_at
)
```

---

## Daily repeating reminders

```crystal
# Remind the user every day at 9:00 AM
Native::Notifications::Notifications.daily_reminder(
  title: "Good morning!",
  body: "Start your day with 5 minutes of journaling.",
  hour: 9,
  minute: 0
)
```

---

## Notification with a tap callback

```crystal
Native::Notifications::Notifications.send_simple(
  title: "New message",
  body: "Alice sent you a photo."
) do
  # This block runs when the user taps the notification
  open_messages_screen
end
```

---

## Advanced — building a notification manually

For full control, use `NotificationManager` directly:

```crystal
notif = Native::Notifications::Notification.new
notif.id = 42                    # unique ID (use the same ID to update/cancel)
notif.title = "Download complete"
notif.body = "Your file is ready."
notif.channel_id = "default"
notif.priority = Native::Notifications::NotificationPriority::High
notif.auto_cancel = true         # dismiss when tapped
notif.vibration = true

# Add action buttons
action = Native::Notifications::NotificationAction.new("open", "Open File") do
  open_file
end
notif.actions = [action]

# Attach extra data (available when the user taps)
notif.payload = { "file_id" => "123" }

Native::Notifications::NotificationManager.show(notif)
```

### Notification priorities

| Priority | Effect |
|---|---|
| `Min` | Silent, no heads-up alert |
| `Low` | Quiet, appears in shade only |
| `Default` | Normal |
| `High` | Makes a sound and pops up |
| `Max` | Most prominent |

---

## Cancelling notifications

```crystal
# Cancel a specific notification by ID
Native::Notifications::NotificationManager.cancel(42)

# Cancel all pending notifications
Native::Notifications::NotificationManager.cancel_all
```

---

## Badge numbers (iOS)

Set the number badge on the app icon:

```crystal
Native::Notifications::NotificationManager.set_badge_number(3)
Native::Notifications::NotificationManager.set_badge_number(0)  # clear badge
```

---

## Custom notification channels (Android)

Android requires notifications to belong to a "channel". `initialize_default` creates one for you, but you can create your own:

```crystal
channel = Native::Notifications::NotificationChannel.new("updates", "App Updates")
channel.description = "Updates about your account"
channel.importance = Native::Notifications::NotificationPriority::Default
channel.show_badge = true
channel.vibration = true

Native::Notifications::NotificationManager.initialize([channel])
```

Then use `channel_id: "updates"` when building a notification.

---

## Check if notifications are allowed

```crystal
if Native::Notifications::NotificationManager.get_permission_status
  puts "Notifications are enabled"
else
  # Ask the user
  Native::Notifications::NotificationManager.request_permission
end
```
