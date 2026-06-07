---
title: Biometric Authentication
---

# Biometric Authentication

Users want their apps to be secure but convenient. Biometric authentication—fingerprint scanning and face recognition—provides the best of both worlds. Native.cr makes it easy to add fingerprint or face authentication to your app.

## What is Biometric Authentication

Biometric authentication verifies the user's identity using physical characteristics:

- **Fingerprint** - Scans the user's finger
- **Face ID** - Scans the user's face
- **Iris Recognition** - Available on some Android devices

On Android, fingerprint is most common. On iOS, Face ID is standard on newer iPhones. Fallback to fingerprint for older iPhones.

## Checking Biometric Availability

Not all devices have biometric sensors. Check before using biometric features:

```crystal
if Native::Biometric.available?
  # Show biometric login button
else
  # Use password login instead
end
```

You can also check for specific types:

```crystal
if Native::Biometric.has_fingerprint?
  # Use fingerprint
elsif Native::Biometric.has_face_id?
  # Use face ID
end
```

## Requesting Biometric Authentication

Present the biometric prompt to the user. The system handles all UI—you just provide a title and callback:

```crystal
Native::Biometric.authenticate(title: "Unlock Your App") do |success|
  if success
    # Authentication succeeded
    unlock_app
  else
    # Authentication failed
    show_error("Authentication failed. Try again.")
  end
end
```

The user has multiple attempts before the system locks them out temporarily. You don't need to implement retry logic—the system handles it.

## Biometric Configuration

Customize the authentication experience:

```crystal
options = Native::Biometric::Options.new
options.title = "Verify Your Identity"
options.subtitle = "Use your fingerprint to unlock"
options.description = "Touch the sensor to continue"
options.negative_button_text = "Use Passcode"

Native::Biometric.authenticate(options) do |success|
  # Handle result
end
```

## Handling Errors

Biometric authentication can fail for several reasons:

```crystal
Native::Biometric.authenticate do |success, error|
  if success
    proceed
  else
    case error
    when "locked_out"
      show_error("Too many attempts. Try again later.")
    when "not_available"
      show_error("Biometric sensor not available.")
    when "cancelled"
      # User cancelled—no error
    else
      show_error("Authentication failed: #{error}")
    end
  end
end
```

## Common Use Cases

### Login Screen

```crystal
class LoginScreen < Native::App
  def setup
    if Native::Biometric.available?
      button = UI::Button.new
      button.text = "Login with Biometric"
      button.on_click = -> { attempt_biometric_login }
      @root = button
    end
  end

  private def attempt_biometric_login
    Native::Biometric.authenticate(title: "Login") do |success|
      if success
        load_session
        show_main_app
      end
    end
  end
end
```

### Sensitive Operation Confirmation

```crystal
def delete_account
  Native::Biometric.authenticate(title: "Confirm Deletion") do |success|
    if success
      perform_delete
    else
      show_error("Deletion cancelled")
    end
  end
end
```

### Payment Authorization

```crystal
def authorize_payment(amount : Int32)
  Native::Biometric.authenticate(
    title: "Authorize Payment",
    subtitle: "Confirm payment of $#{amount}",
    description: "Use your biometric to authorize"
  ) do |success|
    if success
      process_payment
    else
      show_error("Payment cancelled")
    end
  end
end
```

## Security Considerations

- Biometric sensors are hardware-backed on most devices—highly secure
- The OS never reveals the actual biometric data to apps
- Biometric authentication is tied to the device, not the user's account
- Always use biometric as a convenience, not sole security
- For critical operations (payments, account deletion), consider two-factor authentication
- Store biometric settings securely—never store raw biometric data

## Best Practices

- Check availability before showing biometric UI
- Provide a fallback (password, PIN code) always
- Clearly explain why you're requesting biometric authentication
- Handle errors gracefully—don't crash on authentication failure
- Respect user privacy—never log or transmit biometric data
- Use meaningful titles and descriptions
- Test on multiple devices (behavior differs between Android and iOS)
