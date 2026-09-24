# Changelog

All notable changes to native.cr will be documented in this file.

## [0.1.8] - Unreleased

### Added
- **iOS native runtime (Swift)**: full LibIOS implementation in
  `src/native/engine/ios/swift/` — UI (views, widgets, alerts, toasts,
  animators), media (effects/music/recorder/video/camera) and services
  (HTTP/WebSockets, file storage, user defaults, notifications, StoreKit,
  biometrics, location, sensors, image picker) — one `@_cdecl` symbol per
  LibIOS fun, main-thread-safe, retained-pointer handle model
- **iOS CLI pipeline works end to end**: `native create --ios` emits a
  complete Xcode project (pbxproj, Info.plist, bridging header, Swift
  runtime) with no manual steps; `native build ios` fixed (`-Dnative_ios`
  instead of the never-matching `-D ios`, `aarch64-apple-ios` target,
  runtime refreshed per build); `native ipa` gains an unsigned simulator
  Payload fallback without APPLE_TEAM_ID plus Process.run hygiene
- **Push notifications** (`Native::PushNotifications`): FCM on Android, APNs-ready on iOS —
  `request_permission`, `get_token`, `on_token` / `on_token_refresh` / `on_message` / `on_tap`,
  foreground message → local notification bridging, exception-safe callback dispatch
- **iOS binding layer** (`src/native/engine/ios/ios_bindings.cr`): the full `lib LibIOS` C-ABI
  contract — 226 funs covering every framework call site (225 referenced), with documented
  handle/string/memory conventions for the native Swift dylib to implement
- `JNIHelpers.new_object` (constructor one-shot on a stored handle's class) and
  `get_int_field_by_name` (leak-free field reads)
- Push notification spec coverage (desktop dispatch paths)

### Fixed
- Push bridge threads: Java side now posts every native callback to the main thread
  (FCM/GMS executor threads were calling into a thread-bound cached JNIEnv)
- `PushManager.getToken`: removed a dead reflection listener that was built but never
  attached; null tokens no longer cross the JNI boundary
- `platform#share` on iOS now matches the 6-argument share ABI (NULL for absent fields)
- Removed the never-compiled `push_notification.c_r` from the repository root


## [0.1.6] - 2029-06-27

### fixes
- improved xml gradle parser error
- fixed gradle instal error
- changed build cli to link .o(object file) to a static binary 
- improved create cli to match framework api


## [0.1.5] - 2026-06-26

### Fixed 
- `native.c` in android framework 
- `cli/android.cr` renamed correct library name in xml generation that prevented libraries from loading during app launch

### Added

- sign cli 
  added the sign cli to sign apk files using apksigner



## [0.1.0] - 2026-06-02

### Added

#### Core Engine
- Android engine with OpenGL ES 2.0 rendering
- iOS engine with Metal rendering
- NativeActivity support for Android
- Objective-C bridge for iOS
- Fast restart with state preservation
- File watcher for development mode

#### Framework Components
- App base class with @[Preserve] macro for state preservation
- UI components (View, Text, Button, Column, Row, Container, Image)
- Styling system with Color, EdgeInsets, CornerRadius, Font, Theme
- Touch events and gesture handling
- Animation system with curves and sequences
- Image loading from file and network (PNG, JPEG)
- HTTP client and WebSocket support
- Storage (Preferences, FileStorage, SQLite)
- Audio playback (Sound, MusicPlayer, AudioRecorder)
- Platform APIs (Device info, Battery, Sensors, Geolocation, Haptics)
- Camera capture (Photo, Video, Preview)
- Notifications (Local, Push, Scheduling)
- Permission handling
- Biometric authentication (Fingerprint, FaceID)
- In-app purchases
- Game loop (Fixed, Variable, Adaptive)
- Math utilities (Vector2, Vector3, Rect, Matrix3)
- Text input with keyboard handling
- ScrollView and ListView with recycling
- Dialogs (Alert, Confirmation, Toast, Loading, ActionSheet)
- Navigation stack with transitions
- Gesture recognizers (Tap, LongPress, Pan, Pinch, Rotation, Swipe)
- Video playback

#### CLI Tools
- `native.cr create` - Create new project
- `native.cr build` - Build for Android or iOS
- `native.cr reload` - Development mode with hot reload
- `native.cr doctor` - Check toolchain installation

#### Developer Experience
- VS Code configuration
- EditorConfig
- Crystal formatter integration

### Supported Platforms
- Android 7.0+ (API 24) - ARM64 only
- iOS 11+ - ARM64 only

### Requirements
- Crystal 1.20+ with Android ARM64 target support
- Android NDK r25+
- Xcode 14+

## [Unreleased]

### Planned
- WebView component
- Map integration
- QR code scanning
- Particle system
- Shader support
- Charts and graphs
- Push notification service integration
- OTA updates
- Hot reload for mobile devices

### In Progress
- Windows support (backend)
- Linux desktop support
- WebAssembly target
- Documentation site
- Example apps gallery
