# Changelog

All notable changes to native.cr will be documented in this file.

## [0.1.6] - 2029-06-27

### fixes
- improved xml gradle parser error
- fixed gradle instal error


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
