# Notifications

Local push notifications scheduled from your app.

---

## Setup

```crystal
Native::Notifications::Notifications.initialize_default
```

Call once in `setup`.

---

## Send Notification

```crystal
Native::Notifications::Notifications.send(
  title: "Hello!",
  body: "This is a notification"
)
```

With ID for later cancellation:

```crystal
Native::Notifications::Notifications.send(
  title: "Message",
  body: "New message",
  id: 42
)
```

---

## Tap Action

```crystal
Native::Notifications::Notifications.send_simple(
  title: "Download complete",
  body: "Your file is ready",
  on_tap: -> { open_file }
)
```

---

## Scheduled Notification

```crystal
Native::Notifications::Notifications.schedule_reminder(
  title: "Reminder",
  body: "Meeting in 10 minutes",
  at: Time.utc + 10.minutes
)
```

---

## Daily Reminder

```crystal
Native::Notifications::Notifications.daily_reminder(
  title: "Good morning!",
  body: "Start your day right",
  hour: 8,
  minute: 30
)
```

---

## Cancel

```crystal
Native::Notifications::NotificationManager.cancel(42)
Native::Notifications::NotificationManager.cancel_all
```

---

## Custom Notification

```crystal
notif = Native::Notifications::Notification.new
notif.title = "Order shipped"
notif.body = "Your order is on the way"
notif.priority = Native::Notifications::NotificationPriority::High
notif.vibration = true

Native::Notifications::NotificationManager.show(notif)
```

---

## Example: Reminder App

```crystal
def setup
  Native::Notifications::Notifications.initialize_default

  @input = Native::UI::EditText.new
  @input.hint = "Task"

  btn = Native::UI::Button.new("Remind me")
  btn.on_click do
    Native::Notifications::Notifications.schedule_reminder(
      title: "Reminder",
      body: @input.text,
      at: Time.utc + 5.minutes
    )
  end
end
```
