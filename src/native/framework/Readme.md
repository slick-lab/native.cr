# native.cr/framework

This directory contains the UI and API framework for native.cr apps.

## Files

| File | What It Provides |
|------|------------------|
| `app.cr` | Base App class, @[Preserve] macro, state preservation, fast restart |
| `ui.cr` | View, Text, Button, Column, Row, Container components |
| `styling.cr` | Color, EdgeInsets, CornerRadius, Font, Theme, Style helpers |
| `events.cr` | Touch, KeyEvent, GestureEvent, TouchListener, GestureListener |
| `animation.cr` | Animators, curves, sequences, parallel animations, animation DSL |
| `image.cr` | ImageData, ImageLoader, UIImage component, image utilities |
| `network.cr` | HTTP client, WebSocket, ImageDownloader, Request/Response |
| `storage.cr` | Preferences, FileStorage, SQLite database |
| `audio.cr` | Sound, MusicPlayer, AudioRecorder, AudioMixer |
| `platform.cr` | Device info, battery, sensors, geolocation, haptics, clipboard, brightness |
| `camera.cr` | Camera capture, photo/video, PreviewView, flash, zoom, focus |
| `notifications.cr` | Local/push notifications, scheduling, actions, channels |
| `permissions.cr` | Runtime permission checking and requesting |
| `biometric.cr` | Fingerprint/Face ID authentication |
| `payment.cr` | In-app purchases, products, subscriptions, restore |
| `game_loop.cr` | Game loop with fixed/variable/adaptive timestep |
| `math.cr` | Vector2, Vector3, Rect, Matrix3, Color math utilities |
| `text.cr` | TextInput, SecureTextInput, SearchBar, FormField, keyboard handling |
| `scroll.cr` | ScrollView with scrolling, bounce, deceleration |
| `dialog.cr` | AlertDialog, Toast, LoadingDialog, ActionSheet |
| `navigation.cr` | Navigator, NavigationStack, screen transitions |
| `list.cr` | RecyclerView, ListAdapter, view recycling, infinite scroll |
| `gesture.cr` | Tap, long press, pan, pinch, rotation, swipe recognizers |
| `video.cr` | VideoView, video playback, controls |

