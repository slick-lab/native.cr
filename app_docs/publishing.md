# Publishing

Prepare and publish your app to the Google Play Store and Apple App Store.

---

## Before Publishing

### Release Checklist

- [ ] App has a unique package name/bundle ID
- [ ] All features tested on real devices
- [ ] Performance is acceptable
- [ ] No debug code or test data
- [ ] Icons and launch screens ready
- [ ] Privacy policy if collecting data
- [ ] App signing configured

---

## App Signing

### Android Signing

Generate a signing key:

```bash
keytool -genkeypair -v \
  -keystore release.keystore \
  -alias myapp \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

Configure in `android/gradle.properties`:

```properties
MYAPP_RELEASE_STORE_FILE=release.keystore
MYAPP_RELEASE_KEY_ALIAS=myapp
MYAPP_RELEASE_STORE_PASSWORD=********
MYAPP_RELEASE_KEY_PASSWORD=********
```

Or use native.cr CLI:

```bash
crystal main.cr sign android --keystore release.keystore --alias myapp
```

### iOS Signing

1. Open Xcode → Preferences → Accounts
2. Add your Apple ID
3. Select your team
4. Xcode manages signing automatically

For manual signing:

1. Create certificates in Apple Developer Portal
2. Create provisioning profiles
3. Configure in Xcode project settings

---

## Build Release

### Android Release Build

```bash
crystal main.cr build android --release
```

Or with signing:

```bash
crystal main.cr build android --release --sign
```

Output: `build/android/app-release.apk`

For Google Play, build an AAB:

```bash
crystal main.cr build android --release --bundle
```

Output: `build/android/app-release.aab`

### iOS Release Build

```bash
crystal main.cr build ios --release
```

Or archive in Xcode:

1. Open `ios/MyApp.xcworkspace`
2. Select a real device as target
3. Product → Archive
4. Distribute via Organizer

---

## App Icons

### Android Icons

Provide icons for each density:

```
android/app/src/main/res/
├── mipmap-mdpi/ic_launcher.png    # 48x48
├── mipmap-hdpi/ic_launcher.png    # 72x72
├── mipmap-xhdpi/ic_launcher.png   # 96x96
├── mipmap-xxhdpi/ic_launcher.png  # 144x144
└── mipmap-xxxhdpi/ic_launcher.png # 192x192
```

Or use adaptive icons (Android 8+):

```
mipmap-anydpi-v26/
├── ic_launcher.xml   # Foreground/background layers
└── ic_launcher_round.xml
```

### iOS Icons

Provide all required sizes in `Assets.xcassets`:

| Size | Device | Usage |
|------|--------|-------|
| 180x180 | iPhone | @3x |
| 120x120 | iPhone | @2x |
| 167x167 | iPad Pro | @2x |
| 152x152 | iPad | @2x |
| 1024x1024 | App Store | Marketing |

---

## Launch Screens

### Android Launch Screen

In `res/drawable/launch_screen.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
  <item android:drawable="@color/background" />
  <item>
    <bitmap
      android:gravity="center"
      android:src="@drawable/logo" />
  </item>
</layer-list>
```

Create a theme in `res/values/styles.xml`:

```xml
<style name="LaunchTheme" parent="Theme.AppCompat.NoActionBar">
  <item name="android:windowBackground">@drawable/launch_screen</item>
</style>
```

Apply in `AndroidManifest.xml`:

```xml
<activity
  android:name=".MainActivity"
  android:theme="@style/LaunchTheme">
```

### iOS Launch Screen

Use a storyboard in `LaunchScreen.storyboard`:

1. Open in Xcode
2. Add image view with logo
3. Set constraints to center
4. Configure background color

---

## Privacy and Permissions

### Privacy Policy

Required if your app:

- Collects personal data
- Uses location
- Uses camera or microphone
- Shares data with third parties

Host a privacy policy page and link to it in:

- Android: App content page in Play Console
- iOS: App Store Connect app information

### Data Disclosure

For iOS, disclose data usage in App Store Connect:

- Contact Info: Email, Name
- Location: Precise/Coarse
- Photos & Videos
- Browsing History
- etc.

---

## Store Listings

### Google Play Store

1. Create developer account ($25 one-time fee)
2. Create app in Play Console
3. Fill in store listing:
   - App name (30 chars)
   - Short description (80 chars)
   - Full description (4000 chars)
   - Screenshots (phone, tablet)
   - Feature graphic (1024x500)
   - App icon
4. Content rating questionnaire
5. Target audience selection
6. Privacy policy URL

### Apple App Store

1. Create Apple Developer account ($99/year)
2. Create app in App Store Connect
3. Fill in app information:
   - App name (30 chars)
   - Subtitle (30 chars)
   - Description (4000 chars)
   - Keywords (100 chars)
   - Support URL
   - Privacy policy URL
4. Screenshots for all supported devices
5. App preview videos (optional)
6. Age rating questionnaire

---

## Submitting

### Google Play

1. Upload AAB to Play Console
2. Choose release track:
   - Internal testing (fastest)
   - Closed testing (selected testers)
   - Open testing (public testing)
   - Production (public release)
3. Complete pre-launch report review
4. Roll out to percentage or 100%

### App Store

1. Upload build with Xcode or Transporter
2. Wait for processing
3. Select build in App Store Connect
4. Submit for review (1-3 days typical)
5. Address any issues from review
6. Release automatically on approval or schedule

---

## Version Updates

### Version Numbers

**Android:** `versionCode` (integer) and `versionName` (string)

In `build.gradle`:
```groovy
versionCode 2
versionName "1.1.0"
```

**iOS:** `CFBundleShortVersionString` and `CFBundleVersion`

In `Info.plist`:
```xml
<key>CFBundleShortVersionString</key>
<string>1.1</string>
<key>CFBundleVersion</key>
<string>2</string>
```

### Release Notes

Prepare release notes for updates:

- What's new
- Bug fixes
- New features

Keep it user-friendly and concise.

---

## Analytics and Crash Reporting

### Firebase (Recommended)

1. Create Firebase project
2. Add Android and iOS apps
3. Download config files:
   - Android: `google-services.json`
   - iOS: `GoogleService-Info.plist`
4. Add to project
5. Analytics and Crashlytics work automatically

### Custom Analytics

Track events:

```crystal
def track_event(name : String, params : Hash? = nil)
  # Send to your analytics backend
  Native::Network::HTTPClient.post("https://analytics.example.com/events", body: {
    event: name,
    params: params,
    timestamp: Time.utc.to_iso8601
  }.to_json)
end

# Usage
track_event("button_click", { "button_id" => "submit" })
track_event("screen_view", { "screen" => "settings" })
```

---

## Post-Launch

### Monitor

- Crash rates
- User reviews
- Performance metrics
- Feature usage

### Respond

- Fix critical issues quickly
- Address user feedback
- Plan feature updates

---

## Resources

- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Android App Bundles](https://developer.android.com/guide/app-bundle)
- [iOS App Distribution](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases)

---

## Next Steps

- [Testing Strategies](testing-strategies.md) — Ensure quality before release
- [Platform-Specifics](platform-specifics.md) — Handle platform differences
