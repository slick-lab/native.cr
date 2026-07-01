# Biometric

Fingerprint and Face ID authentication.

---

## Check Availability

```crystal
if Native::Biometric.available?
  puts "Biometric: #{Native::Biometric.type_name}"
end

Native::Biometric.type      # => Fingerprint, FaceID, Iris, None
Native::Biometric.enrolled? # => Is biometric set up?
```

---

## BiometricType

| Type | Description |
|------|-------------|
| Fingerprint | Touch ID / Fingerprint sensor |
| FaceID | Face ID (iOS) or Face Unlock (Android) |
| Iris | Iris scanner |
| None | Not available |

---

## Authenticate

Simple usage:

```crystal
Native::Biometric.authenticate("Unlock App") { |result|
  if result.authenticated?
    unlock_app
  else
    show_error(result.error_message)
  end
}
```

---

## BiometricConfig

Customize the prompt:

```crystal
config = Native::Biometric::BiometricConfig.new
config.title = "Verify Identity"
config.subtitle = "Use biometric to continue"
config.description = "Your data is protected"
config.cancel_title = "Cancel"
config.fallback_title = "Use Passcode"
config.allow_device_credential = true
config.allow_fallback = true

Native::Biometric::BiometricManager.authenticate(config)
```

---

## BiometricResult

| Field | Type | Description |
|-------|------|-------------|
| `success` | Bool | Authentication succeeded |
| `error` | BiometricError | Error code |
| `error_message` | String? | Human-readable error |
| `type_used` | BiometricType | Which biometric was used |

```crystal
result.authenticated?  # => true if success
```

---

## BiometricError

| Error | Description |
|-------|-------------|
| Success | Authenticated successfully |
| NotAvailable | No biometric hardware |
| NotEnrolled | No biometric registered |
| NotAuthenticated | Auth failed |
| Lockout | Too many failures, try later |
| LockoutPermanent | Must use passcode |
| UserCancel | User tapped cancel |
| UserFallback | User chose passcode |
| SystemCancel | System interrupted |
| PasscodeNotSet | No passcode configured |

---

## Protected Actions

Wrap sensitive operations:

```crystal
Native::Biometric.protected_action("Access Wallet") {
  show_wallet
}
```

---

## Secure Storage

Store and retrieve data with biometric protection:

```crystal
# Save with biometric
Native::Biometric.authenticate_and_save("secret_key", "api_key_123", "Save API Key")

# Load with biometric
value = Native::Biometric.authenticate_and_load("secret_key", "Access API Key")
```

---

## Example: Login Screen

```crystal
class LoginApp < Native::App
  def setup
    if Native::Biometric.available? && Native::Biometric.enrolled?
      show_biometric_login
    else
      show_password_login
    end
  end

  def show_biometric_login
    btn = Native::UI::Button.new("Login with #{Native::Biometric.type_name}")
    btn.on_click { authenticate }
    @root = btn
  end

  def authenticate
    Native::Biometric.authenticate("Login to App") { |result|
      if result.authenticated?
        proceed_to_app
      else
        show_error(result.error_message || "Authentication failed")
      end
    }
  end

  def proceed_to_app
    @status.text = "Welcome!"
  end
end
```

---

## Example: Protected Data Access

```crystal
class SecureApp < Native::App
  def setup
    btn = Native::UI::Button.new("View Secrets")
    btn.on_click { view_secrets }
    @root = btn
  end

  def view_secrets
    Native::Biometric.protected_action("Unlock Secrets") {
      display_secrets
    }
  end

  def display_secrets
    @label.text = "The secret is: 42"
  end
end
```

---

## Platform Notes

**Android:** Uses AndroidX Biometric library. Requires `USE_BIOMETRIC` permission.

**iOS:** Uses LocalAuthentication framework. Face ID requires `NSFaceIDUsageDescription` in Info.plist.
