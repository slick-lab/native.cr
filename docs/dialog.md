# Dialogs

Alerts, confirmations, and toast messages.

---

## Toast

Quick message popups:

```crystal
Native::Dialog::Toast.show("Saved!")

Native::Dialog::Toast.show_short("Copied")
Native::Dialog::Toast.show_long("This is a longer message")
```

Custom duration:

```crystal
toast = Native::Dialog::Toast.new("Processing...", Native::Dialog::Toast::Length::Long)
toast.show
```

---

## AlertDialog

Alerts with buttons:

```crystal
dialog = Native::Dialog::AlertDialog.new
dialog.title = "Confirm Delete"
dialog.message = "This action cannot be undone."
dialog.positive_button = "Delete"
dialog.negative_button = "Cancel"

dialog.on_positive { delete_item }
dialog.on_negative { puts "Cancelled" }

dialog.show
```

---

## Button Callbacks

```crystal
dialog.on_positive { confirm_action }
dialog.on_negative { cancel_action }
dialog.on_neutral { secondary_action }
```

---

## Properties

| Property | Type | Description |
|----------|------|-------------|
| `title` | String | Dialog title |
| `message` | String | Body text |
| `positive_button` | String | Right button text |
| `negative_button` | String | Left button text |
| `neutral_button` | String | Middle button text |
| `cancelable` | Bool | Can tap outside to dismiss |

---

## Confirm Dialog

```crystal
def confirm_delete
  dialog = Native::Dialog::AlertDialog.new
  dialog.title = "Delete Item?"
  dialog.message = "This cannot be undone."
  dialog.positive_button = "Delete"
  dialog.negative_button = "Keep"

  dialog.on_positive { perform_delete }
  dialog.show
end
```

---

## Info Dialog

```crystal
def show_info
  dialog = Native::Dialog::AlertDialog.new
  dialog.title = "About"
  dialog.message = "App Version 1.0\nBuilt with native.cr"
  dialog.positive_button = "OK"
  dialog.cancelable = true
  dialog.show
end
```

---

## Dismiss Programmatically

```crystal
dialog.dismiss
```

---

## Example: Form Validation

```crystal
class FormApp < Native::App
  def setup
    submit = Native::UI::Button.new("Submit")
    submit.on_click { validate_and_submit }
    @root = submit
  end

  def validate_and_submit
    if @email.empty?
      show_error("Email is required")
    else
      submit_data
    end
  end

  def show_error(message)
    Native::Dialog::Toast.show(message)
  end

  def show_success
    dialog = Native::Dialog::AlertDialog.new
    dialog.title = "Success"
    dialog.message = "Your data has been saved."
    dialog.positive_button = "Great!"
    dialog.show
  end
end
```
