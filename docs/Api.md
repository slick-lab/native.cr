# native.cr API Reference

**Version:** 0.1.6

A Crystal framework for building native Android and iOS apps using the Android/iOS platform APIs directly via JNI and native bridges.

---

## Table of Contents

- [Top-Level: `Native`](#top-level-native)
- [`Native::App`](#nativeapp)
- [`Native::Platform`](#nativeplatform)
- [`Native::Math`](#nativemath)
- [`Native::Storage`](#nativestorage)
- [`Native::Network`](#nativenetwork)
- [`Native::Connectivity`](#nativeconnectivity)
- [`Native::Location`](#nativelocation)
- [`Native::Sensors`](#nativesensors)
- [`Native::Notifications`](#nativenotifications)
- [`Native::Permissions`](#nativepermissions)
- [`Native::Clipboard`](#nativeclipboard)
- [`Native::Share`](#nativeshare)
- [`Native::Biometric`](#nativebiometric)
- [`Native::ImagePicker`](#nativeimagepicker)
- [`Native::Payment`](#nativepayment)
- [`Native::GameLoop`](#nativegameloop)
- [`Native::Animation`](#nativeanimation)
- [`Native::Dialog`](#nativedialog)
- [`Native::Audio` / `Native::Media`](#nativeaudio--nativemedia)
- [`Native::UI`](#nativeui)
- [`Native::Navigation`](#nativenavigation)
- [`Native::Core`](#nativecore)
- [CLI Commands](#cli-commands)

---

## Top-Level `Native`

Entry point module. Dispatches CLI subcommands.

```crystal
Native::VERSION # => "0.1.6"
Native.run      # parses ARGV and dispatches to a CLI command
```

**CLI subcommands** (invoked via the `native.cr` binary):
- `native.cr create <name>` — scaffold a new project
- `native.cr build` — build the project for the current platform
- `native.cr reload <file>` — start development with fast reload
- `native.cr doctor` — check toolchain installation
- `native.cr sign` — sign builds
- `native.cr --version` — print version

---

## `Native::App`

Abstract base class for all apps. Subclass it and implement `setup`.

```crystal
class MyApp < Native::App
  def setup : Nil
    # build your UI here
  end
end
Native::App.registered_subclass = MyApp
```

### Class methods
| Method | Description |
|---|---|
| `App.start(app_class : App.class)` | Instantiate, load saved state, run setup, then run loop |
| `App.start_registered : Nil` | Start the registered subclass (used by the Android bridge) |
| `App.current : App` | The currently running app instance |
| `App.current=(app : App)` | Set the current app |
| `App.registered_subclass : App.class` | The subclass registered for Android builds |
| `App.registered_subclass=(klass : App.class)` | Register your app subclass |

### Instance methods
| Method | Description |
|---|---|
| `setup : Nil` | **Abstract** — implement to build your UI |
| `run : Nil` | Default run loop (sleeps 16ms per tick) |
| `load_saved_state` | Restores state from `NATIVE_CR_STATE_FILE` env var |
| `state_to_json : String` | Override to serialize state (default `"{}"`) |
| `state_from_json(json : String) : Nil` | Override to deserialize state |
| `renderer : Void*` / `renderer=` | Renderer pointer property |

### Optional lifecycle / input callbacks (override in subclass)
| Method | Description |
|---|---|
| `on_touch_began(x : Float32, y : Float32)` | Touch started |
| `on_touch_moved(x : Float32, y : Float32)` | Touch moved |
| `on_touch_ended(x : Float32, y : Float32)` | Touch ended |
| `on_key_pressed(key : Int32)` | Key pressed |
| `on_key_released(key : Int32)` | Key released |
| `on_pause` | App paused |
| `on_resume` | App resumed |
| `on_destroy` | App destroyed |

---

## `Native::Platform`

Device and OS information, plus system actions.

| Method | Returns | Description |
|---|---|---|
| `Platform.android?` | `Bool` | Running on Android |
| `Platform.ios?` | `Bool` | Running on iOS |
| `Platform.desktop?` | `Bool` | Running on desktop |
| `Platform.is_mobile?` | `Bool` | Android or iOS |
| `Platform.os_name` | `String` | `"Android"`, `"iOS"`, or `"Desktop"` |
| `Platform.device_model` | `String` | Device model string |
| `Platform.os_version` | `String` | OS version string |
| `Platform.screen_width` | `Int32` | Screen width in pixels |
| `Platform.screen_height` | `Int32` | Screen height in pixels |
| `Platform.screen_density` | `Float32` | Screen density (dpi / 160) |
| `Platform.vibrate(duration_ms : Int32)` | `Nil` | Vibrate the device |
| `Platform.open_url(url : String)` | `Bool` | Open a URL in the system app |
| `Platform.share(text : String, title : String = "")` | `Nil` | Share text via system sheet |
| `Platform.copy_to_clipboard(text : String)` | `Nil` | Copy text to clipboard |
| `Platform.paste_from_clipboard` | `String` | Paste text from clipboard |
| `Platform.battery_level` | `Int32` | Battery level (0–100) |
| `Platform.is_charging?` | `Bool` | Device is charging |

---

## `Native::Math`

Math constants, helpers, and value types.

### Constants
`PI`, `TAU`, `HALF_PI`, `DEG_TO_RAD`, `RAD_TO_DEG`

### Module methods
| Method | Returns | Description |
|---|---|---|
| `Math.clamp(value, min, max)` | `T` | Clamp value to range |
| `Math.lerp(a, b, t : Float64)` | `Float64` | Linear interpolation |
| `Math.map(value, from_min, from_max, to_min, to_max)` | `Float64` | Re-map a value from one range to another |
| `Math.random(min : Float64 = 0.0, max : Float64 = 1.0)` | `Float64` | Random float in range |
| `Math.random_int(min : Int32, max : Int32)` | `Int32` | Random int in range (inclusive) |
| `Math.deg_to_rad(degrees : Float64)` | `Float64` | Degrees to radians |
| `Math.rad_to_deg(radians : Float64)` | `Float64` | Radians to degrees |

### `Vector2`
A 2D vector with `x : Float64`, `y : Float64`.

| Method / Member | Description |
|---|---|
| `.zero`, `.one`, `.up`, `.down`, `.left`, `.right` | Preset vectors |
| `+`, `-` (vector) | Add/subtract vectors |
| `*`, `/` (scalar `Float64` or `Int32`) | Scale vector |
| `-` (unary) | Negate |
| `magnitude` / `magnitude_squared` | Length |
| `normalize` / `normalized` | Unit vector |
| `dot(other)`, `cross(other)` | Dot / cross product |
| `distance_to(other)`, `distance_squared_to(other)` | Distance |
| `angle_to(other)` / `angle` | Angle in radians |
| `rotate(radians)` | Rotated copy |
| `lerp(to, t)` | Interpolate |
| `clamp(min, max)` | Clamp components |
| `==(other)`, `to_s`, `to_tuple` | Equality / string / tuple |

### `Vector3`
A 3D vector with `x`, `y`, `z : Float64`.

| Method / Member | Description |
|---|---|
| `.zero`, `.one` | Preset vectors |
| `+`, `-` (vector) | Add/subtract |
| `*`, `/` (scalar `Float64`) | Scale |
| `magnitude` / `magnitude_squared` | Length |
| `normalize` | Unit vector |
| `dot(other)` | Dot product |
| `cross(other)` | Cross product (returns `Vector3`) |
| `==(other)`, `to_s` | Equality / string |

### `Rect`
A rectangle with `x`, `y`, `width`, `height : Float64`.

| Method | Description |
|---|---|
| `left`, `right`, `top`, `bottom` | Edges |
| `center_x`, `center_y`, `center` | Center (`center` returns `Vector2`) |
| `contains_point(point : Vector2)` | Point is inside |
| `intersects(other : Rect)` | Rectangles overlap |
| `intersection(other : Rect) : Rect?` | Overlapping region |
| `expand(amount : Float64)` / `shrink(amount)` | Grow / shrink |

### `Matrix3`
A 3×3 matrix (row-major `Array(Float64)` of 9 elements).

| Method | Description |
|---|---|
| `.identity` | Identity matrix |
| `.translation(x, y)` | Translation matrix |
| `.scaling(x, y)` | Scale matrix |
| `.rotation(angle)` | Rotation matrix |
| `*(other : Matrix3)` | Matrix multiplication |
| `transform(point : Vector2) : Vector2` | Transform a point |

### `Color`
An RGBA color with `r`, `g`, `b`, `a : Float64` (0.0–1.0).

| Method | Description |
|---|---|
| `.from_rgba(r, g, b, a : Int32 = 255)` | From 0–255 components |
| `.from_hex(hex : UInt32)` | From ARGB hex |
| `.white`, `.black`, `.red`, `.green`, `.blue` | Presets |
| `.gray(level : UInt8)` / `.grey(level)` | Grayscale |
| `.transparent` | Fully transparent |
| `lerp(to : Color, t : Float64)` | Interpolate colors |
| `with_alpha(alpha : Float64)` | New color with alpha |
| `lighten(amount : Float64)` / `darken(amount)` | Brighten / darken |
| `to_rgba` | `{Int32, Int32, Int32, Int32}` |
| `to_hex` | `UInt32` (ARGB) |

---

## `Native::Storage`

### `Preferences`
Key-value storage backed by Android `SharedPreferences` or iOS `NSUserDefaults`.

```crystal
prefs = Native::Storage::Preferences.new("my_prefs")
```

| Method | Description |
|---|---|
| `set(key : String, value : String/Int32/Int64/Float32/Float64/Bool)` | Store a value |
| `get_string(key, default : String = "")` | Read string |
| `get_int(key, default : Int32 = 0)` | Read int |
| `get_int64(key, default : Int64 = 0)` | Read int64 |
| `get_float(key, default : Float32 = 0.0)` | Read float |
| `get_double(key, default : Float64 = 0.0)` | Read double |
| `get_bool(key, default : Bool = false)` | Read bool |
| `contains?(key : String)` | Key exists |
| `delete(key : String)` | Remove key |
| `clear` | Remove all keys |
| `all_keys : Array(String)` | All keys |

### `FileStorage`
File-backed storage. Construct with a `StorageType` enum: `Documents`, `Cache`, `Temporary`.

```crystal
fs = Native::Storage::FileStorage.new(Native::Storage::FileStorage::StorageType::Documents)
```

| Method | Description |
|---|---|
| `write(filename : String, data : Bytes) : Bool` | Write bytes |
| `write_text(filename : String, content : String) : Bool` | Write text |
| `read(filename : String) : Bytes?` | Read bytes |
| `read_text(filename : String) : String?` | Read text |
| `exists?(filename : String) : Bool` | File exists |
| `delete(filename : String) : Bool` | Delete file |
| `list(directory : String = "") : Array(String)` | List files |

---

## `Native::Network`

### Enums
- `Method`: `GET`, `POST`, `PUT`, `DELETE`, `PATCH`, `HEAD`

### `Request`
| Method / Property | Description |
|---|---|
| `method : Method` | HTTP method (default `GET`) |
| `url : String` | Request URL |
| `headers : Hash(String, String)` | Headers |
| `body : String` | Request body |
| `timeout : Float64` | Timeout in seconds (default 30) |
| `stream : Bool` | Enable streaming |
| `chunk_handler : (Bytes -> Nil)?` | Stream chunk callback |
| `add_header(key, value)` | Add a header |
| `json=(data : String)` | Set JSON body + `Content-Type` |
| `form=(params : Hash(String, String))` | Set form-encoded body |
| `on_chunk(&block : Bytes -> Nil)` | Enable streaming with handler |

### `Response`
| Method / Property | Description |
|---|---|
| `status_code : Int32` | HTTP status |
| `headers : Hash(String, String)` | Response headers |
| `body : String` | Response body |
| `success : Bool` | Request succeeded |
| `error : String?` | Error message |
| `ok?` | Status 200–299 |
| `client_error?` | Status 400–499 |
| `server_error?` | Status 500–599 |
| `json` | Parsed JSON body (if success) |

### `HTTPClient`
```crystal
client = Native::Network::HTTPClient.new("https://api.example.com")
```

| Method | Returns | Description |
|---|---|---|
| `initialize(base_url : String = "")` | | Create client |
| `get(path, headers = nil, &block : Bytes -> Nil)` | `Response` | Streaming GET |
| `post(path, body = "", headers = nil)` | `Response` | POST |
| `put(path, body = "", headers = nil)` | `Response` | PUT |
| `delete(path, headers = nil)` | `Response` | DELETE |
| `request(request : Request)` | `Response` | Custom request |

### `HTTP` (convenience module)
| Method | Description |
|---|---|
| `HTTP.get(url : String) : Response` | Simple GET |
| `HTTP.get(url : String, &block : Bytes -> Nil) : Response` | Streaming GET |
| `HTTP.post(url : String, body : String = "") : Response` | Simple POST |
| `HTTP.put(url : String, body : String = "") : Response` | Simple PUT |
| `HTTP.delete(url : String) : Response` | Simple DELETE |

### `WebSocket`
```crystal
ws = Native::Network::WebSocket.new("wss://example.com/socket")
```

| Method | Description |
|---|---|
| `on_open(&block : -> Nil)` | Connection opened |
| `on_message(&block : String -> Nil)` | Text message received |
| `on_chunk(&block : Bytes -> Nil)` | Binary chunk received |
| `on_error(&block : String -> Nil)` | Error |
| `on_close(&block : Int32, String -> Nil)` | Connection closed (code, reason) |
| `connect : Nil` | Open connection |
| `send(text : String) : Nil` | Send text |
| `send_binary(data : Bytes) : Nil` | Send binary |
| `close : Nil` | Close connection |

---

## `Native::Connectivity`

### Enums
- `NetworkType`: `None`, `WiFi`, `Cellular`, `Ethernet`, `Bluetooth`, `VPN`, `Unknown`

### `NetworkInfo`
| Property | Type |
|---|---|
| `type` | `NetworkType` |
| `is_connected` | `Bool` |
| `is_metered` | `Bool` |
| `is_roaming` | `Bool` |
| `ssid` | `String` |
| `ip_address` | `String` |
| `signal_strength` | `Int32` |
| `is_wifi?` / `is_cellular?` | `Bool` |

### `Connectivity` (convenience module)
| Method | Description |
|---|---|
| `Connectivity.get_network_info : NetworkInfo` | Current network info |
| `Connectivity.is_connected? : Bool` | Network connected |
| `Connectivity.is_wifi? : Bool` | On Wi-Fi |
| `Connectivity.is_cellular? : Bool` | On cellular |
| `Connectivity.start_monitoring(&callback : NetworkInfo -> Nil)` | Listen for changes |
| `Connectivity.stop_monitoring` | Stop listening |
| `Connectivity.on_network_change(&callback : NetworkInfo -> Nil)` | Register a change listener |

### `ConnectivityManager`
Same operations available via `ConnectivityManager.instance`. Methods: `get_network_info`, `is_connected?`, `is_wifi?`, `is_cellular?`, `start_monitoring`, `stop_monitoring`, `on_network_change`.

---

## `Native::Location`

### Enums
- `LocationAccuracy`: `High`, `Balanced`, `Low`, `Passive`

### `Location` struct
| Property | Type |
|---|---|
| `latitude` / `longitude` / `altitude` | `Float64` |
| `accuracy` / `bearing` / `speed` | `Float32` |
| `timestamp` | `Int64` |
| `provider` | `String` |
| `distance_to(other : Location) : Float64` | Haversine distance in meters |

### `Locations` (convenience module)
| Method | Description |
|---|---|
| `Locations.start_updates(accuracy = Balanced, min_distance = 0.0f32, min_time = 0, &callback : Location -> Nil)` | Begin updates |
| `Locations.stop_updates` | Stop updates |
| `Locations.get_last_location : Location?` | Last known location |
| `Locations.is_listening? : Bool` | Currently listening |
| `Locations.on_error(&block : String -> Nil)` | Error callback |
| `Locations.distance_between(lat1, lon1, lat2, lon2) : Float64` | Distance in meters |

### `LocationManager`
Same operations via `LocationManager.instance`. Methods: `start_updates`, `stop_updates`, `get_last_location`, `is_listening?`, `on_location`, `on_error`.

---

## `Native::Sensors`

### Enums
- `SensorType`: `Accelerometer`, `Gyroscope`, `Magnetometer`, `Light`, `Proximity`, `Pressure`, `Temperature`, `Humidity`

### `SensorData` struct
| Property / Method | Description |
|---|---|
| `type : SensorType` | Sensor type |
| `timestamp : Int64` | Timestamp |
| `values : Array(Float64)` | Raw values |
| `accuracy : Int32` | Accuracy |
| `x`, `y`, `z` | First three values as `Float64` |

### `Sensor` (convenience module)
Each starts listening and takes a `delay_us : Int32` (microseconds between samples, default 200000) and a `&callback : SensorData -> Nil`.

| Method |
|---|
| `Sensor.accelerometer(delay_us = 200000, &callback)` |
| `Sensor.gyroscope(delay_us = 200000, &callback)` |
| `Sensor.magnetometer(delay_us = 200000, &callback)` |
| `Sensor.light(delay_us = 20000, &callback)` |
| `Sensor.proximity(delay_us = 200000, &callback)` |
| `Sensor.pressure(delay_us = 200000, &callback)` |
| `Sensor.temperature(delay_us = 200000, &callback)` |
| `Sensor.humidity(delay_us = 200000, &callback)` |

### `SensorManager`
Via `SensorManager.instance`. Methods: `sensor_available?(type)`, `start_listening(type, &callback)`, `stop_listening(type)`, `stop_all`.

---

## `Native::Notifications`

### Enums
- `NotificationPriority`: `Min`, `Low`, `Default`, `High`, `Max`
- `NotificationVisibility`: `Public`, `Private`, `Secret`

### `NotificationAction` struct
`id : String`, `title : String`, `icon : String?`, `callback : -> Nil`

### `NotificationChannel` struct
`id`, `name`, `description : String?`, `importance : NotificationPriority`, `show_badge : Bool`, `sound : String?`, `vibration : Bool`, `light_color : UInt32?`

### `Notification` struct
| Property | Type / Default |
|---|---|
| `id` | `Int32` (0) |
| `channel_id` | `String` ("default") |
| `title` / `body` | `String` |
| `subtitle` | `String?` |
| `large_icon` / `small_icon` | `String?` |
| `badge_number` | `Int32` |
| `priority` | `NotificationPriority` |
| `visibility` | `NotificationVisibility` |
| `auto_cancel` | `Bool` (true) |
| `sound` | `String?` |
| `vibration` | `Bool` (true) |
| `color` | `UInt32?` |
| `actions` | `Array(NotificationAction)` |
| `payload` | `Hash(String, String)` |
| `schedule_time` | `Time?` |
| `repeat_interval` | `Time::Span?` |

### `NotificationManager`
| Method | Returns | Description |
|---|---|---|
| `initialize(channels = []) : Nil` | | Initialize with channels |
| `create_channel(channel : NotificationChannel)` | `Nil` | Create a channel |
| `show(notification : Notification)` | `Bool` | Show immediately |
| `schedule(notification : Notification)` | `Bool` | Schedule for later |
| `cancel(id : Int32)` | `Nil` | Cancel one |
| `cancel_all` | `Nil` | Cancel all |
| `set_badge_number(count : Int32)` | `Nil` | App badge |
| `get_permission_status` | `Bool` | Permission granted? |
| `request_permission` | `Bool` | Request permission |

### `Notifications` (convenience module)
| Method | Description |
|---|---|
| `Notifications.initialize_default` | Initialize with a default high-priority channel |
| `Notifications.send(title, body, id = random, channel_id = "default") : Bool` | Send a notification |
| `Notifications.send_simple(title, body, on_tap = nil) : Bool` | Send with optional tap handler |
| `Notifications.schedule_reminder(title, body, at : Time, id = random) : Bool` | Schedule a one-time reminder |
| `Notifications.daily_reminder(title, body, hour, minute, id = random) : Bool` | Schedule a daily repeating reminder |

---

## `Native::Permissions`

### Enums
- `PermissionType`: `Camera`, `Microphone`, `Location`, `LocationFine`, `LocationCoarse`, `Notifications`, `Storage`, `StorageRead`, `StorageWrite`, `Contacts`, `Calendar`, `CameraRoll`, `Bluetooth`, `Speech`, `Motion`
- `PermissionStatus`: `Granted`, `Denied`, `Restricted`, `NotDetermined`, `Limited`

### `PermissionManager`
| Method | Description |
|---|---|
| `check(type : PermissionType) : PermissionStatus` | Current status |
| `request(type, &callback : PermissionStatus -> Nil)` | Request a permission |
| `request_multiple(types : Array(PermissionType), &callback : Hash(PermissionType, PermissionStatus) -> Nil)` | Request several |
| `is_granted?(type) : Bool` | Granted? |
| `is_denied?(type) : Bool` | Denied or restricted? |
| `open_settings` | Open system app settings |

### `Permissions` (convenience module)
| Method | Description |
|---|---|
| `Permissions.camera(&callback)` / `Permissions.camera_granted?` | Camera |
| `Permissions.microphone(&callback)` / `Permissions.microphone_granted?` | Microphone |
| `Permissions.location(&callback)` / `Permissions.location_granted?` | Location |
| `Permissions.notifications(&callback)` / `Permissions.notifications_granted?` | Notifications |
| `Permissions.storage(&callback)` / `Permissions.storage_granted?` | Storage |

---

## `Native::Clipboard`

### `Clipboard` (convenience module)
| Method | Description |
|---|---|
| `Clipboard.copy(text : String) : Bool` | Copy to clipboard |
| `Clipboard.paste : String?` | Get clipboard text |
| `Clipboard.has_text? : Bool` | Clipboard has text |
| `Clipboard.clear : Bool` | Clear clipboard |

### `ClipboardManager`
Via `ClipboardManager.instance`. Methods: `set_text(text) : Bool`, `get_text : String?`, `has_text? : Bool`, `clear : Bool`.

---

## `Native::Share`

### `ShareOptions` struct
`title`, `text`, `url`, `image_path`, `image_data`, `mime_type : String` (default `"text/plain"`), `has_content? : Bool`

### `ShareSheet`
| Method | Description |
|---|---|
| `initialize(options : ShareOptions = ShareOptions.new)` | Create sheet |
| `options : ShareOptions` | Get/set options |
| `on_complete : (Bool -> Nil)?` | Completion callback |
| `show(&block : Bool -> Nil)` | Present the share sheet |

### `Share` (convenience module)
| Method | Description |
|---|---|
| `Share.share_text(text, title = "share", &block : Bool -> Nil)` | Share text |
| `Share.share_url(url, title = "share", &block)` | Share a URL |
| `Share.share_image(image_path, title = "share", &block)` | Share an image file |
| `Share.share_text_and_url(text, url, title = "share", &block)` | Share text + URL |
| `Share.share(options : ShareOptions, &block)` | Share custom options |

---

## `Native::Biometric`

### Enums
- `BiometricType`: `Fingerprint`, `FaceID`, `Iris`, `None`
- `BiometricError`: `Success`, `NotAvailable`, `NotEnrolled`, `NotAuthenticated`, `Lockout`, `LockoutPermanent`, `UserCancel`, `UserFallback`, `SystemCancel`, `PasscodeNotSet`, `InvalidContext`, `NotInteractive`

### `BiometricConfig` struct
`title`, `subtitle`, `description`, `cancel_title`, `fallback_title : String`, `allow_device_credential`, `allow_fallback : Bool`

### `BiometricResult` struct
`success : Bool`, `error : BiometricError`, `error_message : String?`, `type_used : BiometricType`, `authenticated? : Bool`

### `Biometric` (convenience module)
| Method | Description |
|---|---|
| `Biometric.available? : Bool` | Biometrics available |
| `Biometric.type : BiometricType` | Available type |
| `Biometric.type_name : String` | Human-readable type name |
| `Biometric.enrolled? : Bool` | Biometrics enrolled |
| `Biometric.authenticate(title = "Authenticate", &callback : BiometricResult -> Nil)` | Authenticate asynchronously |
| `Biometric.authenticate_and_save(key, value, title = "Save with Biometric") : Bool` | Auth then save to Preferences |
| `Biometric.authenticate_and_load(key, title = "Access with Biometric") : String?` | Auth then load from Preferences |
| `Biometric.protected_action(title = "Verify Identity", &block)` | Auth then run a block (returns `T?`) |

### `BiometricManager`
Class methods: `is_available?`, `available_type`, `is_enrolled?`, `authenticate(config = BiometricConfig.new) : BiometricResult`, `authenticate_async(config, &callback)`.

---

## `Native::ImagePicker`

### Enums
- `ImageSource`: `Camera`, `Gallery`, `Both`
- `ImageQuality`: `Low (0)`, `Medium (1)`, `High (2)`, `Original (3)`

### `ImagePickerResult` struct
`success : Bool`, `path : String?`, `data : Bytes?`, `width`, `height : Int32`, `mime_type : String`, `error_message : String?`, `has_image? : Bool`

### `ImagePicker` class
| Method | Description |
|---|---|
| `ImagePicker.pick(source = Gallery, quality = High, max_width = 0, max_height = 0, &callback : ImagePickerResult -> Nil)` | Pick an image |
| `ImagePicker.take_photo(quality = High, max_width = 0, max_height = 0, &callback)` | Take a photo |
| `ImagePicker.pick_multiple(max_count = 10, &callback : Array(ImagePickerResult) -> Nil)` | Pick multiple (stub) |

### `ImagePickerAPI` (convenience module)
| Method | Description |
|---|---|
| `ImagePickerAPI.pick_image(source = Gallery, quality = High, &callback)` | Pick image |
| `ImagePickerAPI.take_photo(quality = High, &callback)` | Take photo |
| `ImagePickerAPI.pick_and_resize(source = Gallery, max_width = 1024, max_height = 1024, &callback)` | Pick and resize |

---

## `Native::Payment`

### Enums
- `ProductType`: `Consumable`, `NonConsumable`, `Subscription`
- `SubscriptionPeriod`: `Weekly`, `Monthly`, `Quarterly`, `Yearly`

### `Product` struct
`id`, `title`, `description`, `price : String`, `price_amount : Float64`, `currency`, `currency_symbol : String`, `type : ProductType`, `subscription_period : SubscriptionPeriod?`, `formatted_price : String`, `price_for_display : String`

### `PurchaseResult` struct
`success : Bool`, `product_id`, `transaction_id`, `receipt_data : String`, `error_message : String?`, `purchase_date : Int64`, `expiration_date : Int64?`, `verified? : Bool`, `is_subscription? : Bool`, `is_active? : Bool`

### `RestoreResult` struct
`success : Bool`, `restored_count : Int32`, `product_ids : Array(String)`, `error_message : String?`

### `Payment` (convenience module)
| Method | Description |
|---|---|
| `Payment.initialize(merchant_id = "") : Bool` | Initialize billing |
| `Payment.products(product_ids : Array(String)) : Array(Product)` | Fetch product details |
| `Payment.purchase(product_id, &callback : PurchaseResult -> Nil) : Bool` | Start a purchase |
| `Payment.restore(&callback : RestoreResult -> Nil) : Bool` | Restore purchases |
| `Payment.is_purchased?(product_id) : Bool` | Product purchased |
| `Payment.is_subscription_active?(product_id) : Bool` | Subscription active |
| `Payment.coins_pack(id, title, coin_amount, price) : Product` | Build a consumable product |
| `Payment.subscription(id, title, period, price) : Product` | Build a subscription product |

### `PaymentManager`
Class methods: `initialize(merchant_id = "")`, `fetch_products(product_ids)`, `purchase(product_id, &callback)`, `restore_purchases(&callback)`, `is_purchased?(product_id)`, `is_subscription_active?(product_id)`.

---

## `Native::GameLoop`

### Enums
- `LoopMode`: `Fixed`, `Variable`, `Adaptive`

### `LoopConfig` struct
`mode : LoopMode (Adaptive)`, `target_fps : Int32 (60)`, `fixed_update_rate : Float64 (1/60)`, `max_frame_time : Float64 (0.25)`

### `GameLoop` class
| Method | Description |
|---|---|
| `initialize(config : LoopConfig = LoopConfig.new)` | Create loop |
| `start : Nil` | Start the loop |
| `stop : Nil` | Stop the loop |
| `pause : Nil` / `resume : Nil` | Pause / resume |
| `on_start(&block : -> Nil)` | Loop started |
| `on_update(&block : Float64 -> Nil)` | Per-frame update (delta time) |
| `on_fixed_update(&block : Float64 -> Nil)` | Fixed timestep update |
| `on_render(&block : Float64 -> Nil)` | Render (alpha or frame time) |
| `on_pause(&block : -> Nil)` / `on_resume(&block : -> Nil)` / `on_stop(&block : -> Nil)` | Lifecycle |
| `is_running? : Bool` / `is_paused? : Bool` | State |
| `fps : Float64` / `delta_time : Float64` / `frame_count : Int64` | Stats |
| `target_fps=` / `target_fps` | Target FPS |

### `FixedGameLoop` and `VariableGameLoop`
Subclasses with preset modes. `FixedGameLoop.new(target_fps = 60)`, `VariableGameLoop.new(target_fps = 60)`.

### `GameLoopDSL`
Include in your `App` subclass to get game-loop callbacks. Call `game_loop(target_fps = 60, mode = Adaptive)` to start.

| DSL method | Description |
|---|---|
| `game_start`, `game_update(delta)`, `game_fixed_update(delta)`, `game_render(alpha)` | Override in your app |
| `game_pause`, `game_resume`, `game_stop` | Override in your app |
| `pause_game` / `resume_game` / `stop_game` | Control the loop |
| `game_fps : Float64` / `game_delta : Float64` | Current stats |

---

## `Native::Animation`

### `Interpolator` enum
`Linear`, `Accelerate`, `Decelerate`, `AccelerateDecelerate`, `Bounce`, `Overshoot`, `Anticipate`, `AnticipateOvershoot`

### `ValueAnimator`
```crystal
anim = Native::Animation::ValueAnimator.new(0.0, 1.0)
```
| Method | Description |
|---|---|
| `initialize(start_value = 0.0, end_value = 1.0)` | Create animator |
| `duration=` / `duration : Int32` | Duration in ms |
| `interpolator=` / `interpolator : Interpolator` | Easing |
| `repeat_count=` / `repeat_count : Int32` | Repeat count |
| `repeat_mode=` / `repeat_mode : Int32` | Repeat mode |
| `start` / `cancel` / `end` | Control animation |
| `is_running? : Bool` | Running? |
| `on_update(&block : Float64 -> Nil)` | Value update callback |
| `on_start(&block : -> Nil)` | Started callback |
| `on_end(&block : -> Nil)` | Ended callback |
| `on_repeat(&block : -> Nil)` | Repeated callback |

### `ObjectAnimator < ValueAnimator`
Animates a property on a `UI::View`.
```crystal
Native::Animation::ObjectAnimator.new(view, "translationX", 0.0, 100.0)
```

### `AnimatorSet`
| Method | Description |
|---|---|
| `play_together(animator : ValueAnimator)` | Play together |
| `play_sequentially(animators : Array(ValueAnimator))` | Play in sequence |
| `start` / `cancel` | Control |
| `duration=(value : Int32)` | Set duration on all animators |

---

## `Native::Dialog`

### `AlertDialog`
```crystal
dialog = Native::Dialog::AlertDialog.new
dialog.title = "Confirm"
dialog.message = "Are you sure?"
dialog.positive_button = "OK"
dialog.on_positive { puts "confirmed" }
dialog.show
```
| Method | Description |
|---|---|
| `title=` / `title` | Dialog title |
| `message=` / `message` | Dialog message |
| `positive_button=` / `negative_button=` / `neutral_button=` | Button labels |
| `cancelable=` / `cancelable?` | Cancelable |
| `on_positive(&block : -> Nil)` | Positive button callback |
| `on_negative(&block : -> Nil)` | Negative button callback |
| `on_neutral(&block : -> Nil)` | Neutral button callback |
| `show` | Display the dialog |
| `dismiss` | Dismiss the dialog |

### `Toast`
| Method | Description |
|---|---|
| `Length` enum | `Short`, `Long` |
| `initialize(text = "", duration = Short)` | Create toast |
| `text=` / `text` | Toast text |
| `duration=` / `duration : Length` | Duration |
| `show` | Show the toast |
| `Toast.show(text, duration = Short)` | Class method shortcut |
| `Toast.show_short(text)` | Quick short toast |
| `Toast.show_long(text)` | Quick long toast |

---

## `Native::Audio` / `Native::Media`

### `Native::Audio`

#### Enums & structs
- `AudioFormat`: `PCM_16`, `PCM_8`, `MP3`, `AAC`
- `SoundConfig`: `volume : Float32 (1.0)`, `loop : Bool (false)`, `pitch : Float32 (1.0)`, `pan : Float32 (0.0)`

#### `Sound`
| Method | Description |
|---|---|
| `initialize(path : String)` | Load a sound |
| `load(path : String) : Bool` | Load/reload |
| `play(config = SoundConfig.new) : SoundInstance?` | Play |
| `stop_all : Nil` | Stop all instances |
| `duration : Float64` | Duration in seconds |
| `loaded? : Bool` | Loaded |
| `unload : Nil` | Free resources |

#### `SoundInstance`
| Method | Description |
|---|---|
| `stop : Nil` / `pause : Nil` / `resume : Nil` | Control |
| `volume=(value : Float32)` | Volume |
| `is_playing? : Bool` | Playing? |

#### `MusicPlayer`
| Method | Description |
|---|---|
| `initialize(path : String)` | Load music |
| `load(path : String) : Bool` | Load/reload |
| `play(loop : Bool = false) : Nil` | Play |
| `pause : Nil` / `resume : Nil` / `stop : Nil` | Control |
| `volume=` / `volume : Float32` | Volume |
| `is_playing? : Bool` | Playing? |
| `seek(position : Float64) : Nil` | Seek to seconds |
| `current_position : Float64` | Current position (seconds) |
| `duration : Float64` | Duration (seconds) |
| `unload : Nil` | Free resources |

#### `AudioRecorder`
| Method | Description |
|---|---|
| `initialize` | Create recorder |
| `start : Bool` | Start recording |
| `stop : Bytes?` | Stop and return audio bytes |
| `is_recording? : Bool` | Recording? |

#### `AudioMixer`
| Method | Description |
|---|---|
| `AudioMixer.master_volume=` / `master_volume : Float32` | Master volume |
| `AudioMixer.music_volume=` / `music_volume : Float32` | Music volume |
| `AudioMixer.sfx_volume=` / `sfx_volume : Float32` | SFX volume |

#### `Audio` (convenience module)
| Method | Description |
|---|---|
| `Audio.play_sound(path, volume = 1.0) : SoundInstance?` | Quick sound |
| `Audio.play_music(path, loop = true) : MusicPlayer` | Quick music |
| `Audio.stop_all : Nil` | Stop all |
| `Audio.pause_all : Nil` | Pause all |
| `Audio.resume_all : Nil` | Resume all |

### `Native::Media::Camera`

#### Enums
- `Facing`: `Back`, `Front`
- `FlashMode`: `Off`, `On`, `Auto`
- `Quality`: `Low`, `Medium`, `High`

#### `Camera` class
| Method | Description |
|---|---|
| `initialize` | Create camera |
| `facing=` / `facing : Facing` | Which camera |
| `flash_mode=` / `flash_mode : FlashMode` | Flash |
| `quality=` / `quality : Quality` | Capture quality |
| `start_preview(view : UI::View)` | Show preview in a view |
| `stop_preview` | Stop preview |
| `take_photo` | Capture a photo |
| `start_recording(output_path : String)` | Start video recording |
| `stop_recording` | Stop video recording |
| `switch_camera` | Switch front/back |
| `on_photo_captured(&block : Bytes, Int32, Int32 -> Nil)` | Photo callback (data, width, height) |
| `on_error(&block : String -> Nil)` | Error callback |

### `Native::Media::VideoPlayer`

A `UI::View` that plays video.

#### Enum
- `ScaleType`: `FitXY`, `FitCenter`, `FitStart`, `FitEnd`, `Center`, `CenterCrop`, `CenterInside`

#### Methods
| Method | Description |
|---|---|
| `initialize` | Create player |
| `load(path : String)` | Load a video |
| `play` / `pause` / `stop` | Control |
| `playing? : Bool` | Playing? |
| `looping=` / `looping? : Bool` | Loop |
| `volume=` / `volume : Float32` | Volume |
| `scale_type=` / `scale_type : ScaleType` | Scaling |
| `seek_to(msec : Int32)` | Seek to position |
| `current_position : Int32` | Position (ms) |
| `duration : Int32` | Duration (ms) |
| `on_prepared(&block : -> Nil)` | Ready to play |
| `on_completion(&block : -> Nil)` | Playback finished |
| `on_error(&block : String -> Nil)` | Error |
| `on_info(&block : Int32, Int32 -> Nil)` | Info event |

---

## `Native::UI`

All UI components live under `Native::UI` and inherit from `View`.

### `View` (base class)
| Method / Property | Description |
|---|---|
| `x=` / `x : Int32` | X position |
| `y=` / `y : Int32` | Y position |
| `width=` / `width : Int32` | Width |
| `height=` / `height : Int32` | Height |
| `visible=` / `visible? : Bool` | Visibility |
| `enabled=` / `enabled? : Bool` | Enabled state |
| `tag=` / `tag : String?` | Tag |
| `background_color=(color : Native::Math::Color)` | Background color |
| `native_ptr : Int64` | Underlying native pointer |

### `TextView < View`
| Method | Description |
|---|---|
| `initialize(text : String = "")` | Create label |
| `text=` / `text : String` | Text |
| `text_size=` / `text_size : Int32` | Font size |
| `text_color=` / `text_color : Native::Math::Color` | Text color |
| `gravity=` / `gravity : Int32` | Gravity (raw) |
| `center` / `center_horizontal` / `center_vertical` / `left` / `right` | Gravity helpers |
| `max_lines=` / `max_lines : Int32` | Max lines |
| `ellipsize_end` | Ellipsize at end |

### `Button < View`
| Method | Description |
|---|---|
| `initialize(text : String = "")` | Create button |
| `text=` / `text : String` | Label |
| `text_size=` / `text_size : Int32` | Font size |
| `text_color=` / `text_color : Native::Math::Color` | Text color |
| `background_color=` / `background_color : Native::Math::Color` | Background |
| `all_caps=` / `all_caps? : Bool` | All caps |
| `on_click(&block : -> Nil)` | Click handler |
| `on_long_click(&block : -> Nil)` | Long click handler |

### `EditText < View`
| Method | Description |
|---|---|
| `initialize(text : String = "")` | Create input |
| `text=` / `text : String` | Text (getter reads from native) |
| `hint=` / `hint : String` | Placeholder |
| `text_size=` / `text_size : Int32` | Font size |
| `text_color=` / `text_color : Native::Math::Color` | Text color |
| `hint_color=(value : Native::Math::Color)` | Hint color |
| `input_type=` / `input_type : Int32` | Raw input type |
| `password` / `email` / `number` / `phone` / `multiline` | Input type presets |
| `lines=` / `lines : Int32` | Number of lines |
| `max_length=` / `max_length : Int32` | Max characters |
| `on_text_changed(&block : String -> Nil)` | Text change callback |

### `ImageView < View`
#### Enum
- `ScaleType`: `FitXY`, `FitCenter`, `FitStart`, `FitEnd`, `Center`, `CenterCrop`, `CenterInside`

#### Methods
| Method | Description |
|---|---|
| `initialize` | Create image view |
| `setImageResource(resource_id : Int32)` | Set from resource |
| `setImagePath(path : String)` | Set from file path |
| `setImageData(data : Bytes)` | Set from bytes |
| `scale_type=` / `scale_type : ScaleType` | Scaling |
| `alpha=` / `alpha : Float32` | Opacity |

### `LinearLayout < View`
#### Enums
- `Orientation`: `Vertical`, `Horizontal`
- `Gravity`: `Top (48)`, `Bottom (80)`, `Left (3)`, `Right (5)`, `Center (17)`, `CenterHorizontal (1)`, `CenterVertical (16)`, `Fill (119)`, `FillHorizontal (7)`, `FillVertical (112)`

#### Methods
| Method | Description |
|---|---|
| `initialize(orientation = Vertical)` | Create layout |
| `orientation=` / `orientation : Orientation` | Stack direction |
| `gravity=` / `gravity : Gravity` | Child gravity |
| `weight_sum=` / `weight_sum : Float32` | Weight sum |
| `set_padding(left, top, right, bottom)` | Padding |
| `addView(view : View, weight : Float32 = 0.0)` | Add a child |
| `addView(view : View, width : Int32, height : Int32, weight : Float32 = 0.0)` | Add with size |
| `removeView(view : View)` | Remove a child |
| `removeAllViews` | Remove all children |
| `getChildAt(index : Int32) : View?` | Child by index |
| `childCount : Int32` | Number of children |

### `ScrollView < View`
#### Enums
- `ScrollDirection`: `Vertical`, `Horizontal`
- `ScrollBarStyle`: `InsideOverlay`, `InsideInset`, `OutsideOverlay`, `OutsideInset`

#### Methods
| Method | Description |
|---|---|
| `initialize(direction = Vertical)` | Create scroll view |
| `addView(view : View)` | Add a child |
| `removeView(view : View)` | Remove a child |
| `scroll_to(x, y, animated = true)` | Scroll to position |
| `scroll_to_bottom(animated = true)` / `scroll_to_top(animated = true)` | Scroll shortcuts |
| `scroll_x : Int32` / `scroll_y : Int32` | Current scroll |
| `max_scroll_x : Int32` / `max_scroll_y : Int32` | Max scroll |
| `scroll_bar_style=` / `scroll_bar_style : ScrollBarStyle` | Scrollbar style |
| `is_scrolling? : Bool` | Currently scrolling |
| `on_scroll_changed(&block : Int32, Int32 -> Nil)` | Scroll change callback |
| `on_scroll_state_changed(&block : Bool -> Nil)` | Scroll state callback |

### `CardView < View`
| Method | Description |
|---|---|
| `initialize` | Create card |
| `elevation=` / `elevation : Float32` | Shadow elevation |
| `radius=` / `radius : Float32` | Corner radius |
| `content_padding=` / `content_padding : Int32` | Content padding |
| `addView(view : View)` / `removeView(view : View)` | Add / remove child |
| `background_color=(color : Native::Math::Color)` | Background |

### `CheckBox < View`
| Method | Description |
|---|---|
| `initialize(text : String = "")` | Create checkbox |
| `checked=` / `checked? : Bool` | Checked state |
| `toggle` | Toggle |
| `text=` / `text : String` | Label |
| `text_color=(value : Native::Math::Color)` | Text color |
| `text_size=` / `text_size : Int32` | Font size |
| `on_checked_change(&block : Bool -> Nil)` | Change callback |

### `Switch < View`
| Method | Description |
|---|---|
| `initialize` | Create switch |
| `checked=` / `checked? : Bool` | Checked state |
| `toggle` | Toggle |
| `text_on=` / `text_on : String` | On label |
| `text_off=` / `text_off : String` | Off label |
| `show_text=(value : Bool)` | Show text labels |
| `on_checked_change(&block : Bool -> Nil)` | Change callback |

### `RadioButton < View` & `RadioGroup`
#### `RadioButton`
| Method | Description |
|---|---|
| `initialize(text : String = "")` | Create radio button |
| `checked=` / `checked? : Bool` | Checked |
| `text=` / `text : String` | Label |
| `group=` / `group : RadioGroup?` | Assign to a group |
| `text_color=(value : Native::Math::Color)` | Text color |
| `text_size=` / `text_size : Int32` | Font size |
| `on_checked_change(&block : Bool -> Nil)` | Change callback |

#### `RadioGroup`
| Method | Description |
|---|---|
| `addButton(button : RadioButton)` | Add a radio button |
| `removeButton(button : RadioButton)` | Remove a radio button |
| `selected_button : RadioButton?` / `selected_button=` | Selected button |
| `on_selected_change(&block : RadioButton -> Nil)` | Selection callback |
| `clearSelection` | Clear selection |

### `ProgressBar < View`
| Method | Description |
|---|---|
| `initialize` | Create progress bar |
| `progress=` / `progress : Int32` | Current progress |
| `max=` / `max : Int32` | Maximum |
| `indeterminate=` / `indeterminate? : Bool` | Indeterminate mode |
| `horizontal` | Set horizontal style |

### `CircularProgressBar < ProgressBar`
A circular progress indicator. `initialize`.

### `SeekBar < View`
| Method | Description |
|---|---|
| `initialize` | Create seek bar |
| `progress=` / `progress : Int32` | Current value |
| `max=` / `max : Int32` | Maximum |
| `on_progress_changed(&block : Int32 -> Nil)` | Progress changed |
| `on_start_touch(&block : -> Nil)` | Touch started |
| `on_stop_touch(&block : -> Nil)` | Touch ended |

### `Spinner < View`
| Method | Description |
|---|---|
| `initialize` | Create spinner (dropdown) |
| `items=` / `items : Array(String)` | Items |
| `selected_position=` / `selected_position : Int32` | Selection |
| `selected_item : String?` | Selected item |
| `prompt=` / `prompt : String` | Dropdown title |
| `dropdown_width=` / `dropdown_width : Int32` | Dropdown width |
| `on_item_selected(&block : Int32, String -> Nil)` | Selection callback |

### `RecyclerView < View`
#### Enum
- `LayoutManager`: `Linear`, `Grid`, `StaggeredGrid`

#### `RecyclerViewAdapter` (abstract)
| Method | Description |
|---|---|
| `item_count : Int32` | **Abstract** — number of items |
| `create_view(env, position) : Int64` | **Abstract** — create a view |
| `bind_view(env, view, position)` | **Abstract** — bind data |
| `get_item_id(position : Int32) : Int64` | Item ID |
| `on_item_click(position : Int32)` / `on_item_long_click(position : Int32)` | Click hooks |

#### `RecyclerView` methods
| Method | Description |
|---|---|
| `initialize` | Create recycler view |
| `adapter=` / `adapter : RecyclerViewAdapter?` | Set adapter |
| `layout_manager=` / `layout_manager : LayoutManager` | Layout manager |
| `set_layout_manager(manager : LayoutManager)` | Set layout manager |
| `on_item_click(&block : Int32 -> Nil)` | Item click callback |
| `on_item_long_click(&block : Int32 -> Nil)` | Item long click callback |
| `scroll_to_position(position, smooth = false)` | Scroll to position |
| `scroll_to_top(smooth = false)` | Scroll to top |
| `notify_data_changed` | Refresh all |
| `notify_item_inserted(position : Int32)` | Item inserted |
| `notify_item_removed(position : Int32)` | Item removed |

#### `SimpleAdapter < RecyclerViewAdapter`
| Method | Description |
|---|---|
| `initialize(items : Array(String))` | Create with strings |
| `item_count : Int32` | Count |
| `create_view(env, position) : Int64` | Creates a `TextView` |
| `bind_view(env, view, position)` | Sets text |
| `on_bind(&block : TextView, String, Int32 -> Nil)` | Custom bind callback |

### `WebView < View`
| Method | Description |
|---|---|
| `initialize` | Create web view |
| `url=` / `url : String` | Load a URL |
| `load_html(html : String, base_url : String = "")` | Load HTML |
| `java_script_enabled=` / `java_script_enabled? : Bool` | JS enabled |
| `dom_storage_enabled=` / `dom_storage_enabled? : Bool` | DOM storage |
| `can_go_back? : Bool` / `can_go_forward? : Bool` | Navigation history |
| `go_back` / `go_forward` / `reload` / `stop_loading` | Navigation |
| `on_page_started(&block : String -> Nil)` | Page started loading |
| `on_page_finished(&block : String -> Nil)` | Page finished |
| `on_error(&block : String -> Nil)` | Load error |

### `Icon < TextView`
#### Enum
- `IconSet`: `Material`, `FontAwesome`, `Ionicons`, `Custom`

#### Methods
| Method | Description |
|---|---|
| `initialize(icon_set = Material, icon_code = "")` | Create icon |
| `set_icon(icon_code : String)` | Set icon by code |
| `icon_code : String` | Current code |
| `icon_set=` / `icon_set : IconSet` | Icon set |
| `size=(value : Int32)` | Size (sets text size) |
| `color=(value : Native::Math::Color)` | Color (sets text color) |

#### `MaterialIcons` module
Class methods returning icon code strings: `home`, `home_filled`, `search`, `favorite`, `favorite_filled`, `settings`, `person`, `person_filled`, `menu`, `back`, `close`, `more_vert`, `more_horiz`, `add`, `remove`, `delete`, `edit`, `check`, `arrow_back`, `arrow_forward`, `refresh`, `share`, `star`, `star_filled`, `info`, `warning`, `error`, `check_circle`, `help`, `lock`, `visibility`, `visibility_off`, `photo_camera`, `videocam`, `mic`, `mic_off`, `volume_up`, `volume_off`, `play_arrow`, `pause`, `stop`, `cloud`, `cloud_upload`, `cloud_download`.

#### `FontAwesomeIcons` module
Class methods: `home`, `user`, `search`, `heart`, `star`, `cog`, `trash`, `pencil`, `check`, `times`, `plus`, `minus`, `camera`, `video`, `music`, `envelope`, `phone`, `map_marker`, `calendar`.

---

## `Native::Navigation`

### `Toolbar < UI::View`
#### `MenuItem` (nested class)
`id : Int32`, `title : String`, `icon : Int32`, `show_as_action : Bool`

#### Methods
| Method | Description |
|---|---|
| `initialize` | Create toolbar |
| `title=` / `title : String` | Toolbar title |
| `subtitle=` / `subtitle : String` | Toolbar subtitle |
| `navigation_icon=` / `navigation_icon : Int32` | Back/nav icon resource |
| `on_navigation_click(&block : -> Nil)` | Nav icon click |
| `add_menu_item(id, title, icon = 0, show_as_action = false)` | Add menu item |
| `on_menu_item_click(&block : Int32 -> Nil)` | Menu item click callback |

---

## `Native::Core`

Internal helpers for the dev server and state management (not intended for app code).

### `Native::Core::Process`
- `Config`: `entry_point`, `watch_paths`, `build_output`, `state_file`, `compile_timeout`, `release`
- `Watcher`: file change watcher (`check`, `initialize(paths, &callback)`)
- `Manager`: desktop preview process manager (`start`, `stop`, `fast_restart`)
- `ProcessError`, `CompileError`: exception types

### `Native::Core::State`
| Method | Description |
|---|---|
| `State.save(obj : JSON::Serializable) : String` | Serialize to JSON |
| `State.load(json, klass) : JSON::Serializable` | Deserialize |
| `State.capture_and_restore(obj, &block)` | Save, run block, restore |
| `State.valid_json?(json : String) : Bool` | Validate JSON |
- `SerializationError`, `DeserializationError`: exception types

---

## CLI Commands

Invoked via the `native.cr` binary (see [Top-Level `Native`](#top-level-native)).

### `create`
Scaffolds a new project. Generates a `shard.yml`, `src/main.cr`, and platform project files.

### `build`
Compiles the project. Flags: `--release`, `--android`, `--ios`, `--output`, `--help`.

### `reload`
Starts the desktop dev server with fast reload and state preservation.

### `doctor`
Checks that the required toolchain (Crystal compiler, Android SDK/NDK, Xcode) is installed.

### `sign`
Signs Android APKs / iOS IPAs. Flags for keystore / provisioning profile.

### `Apk.build(android_project, release = false) : String?`
Builds an APK from an Android project directory.

### `Ipa.build(ios_project, release = false) : String?`
Builds an IPA from an iOS project directory.

### `AndroidGenerator` / `IOSGenerator`
Internal project generators used by `create`. Each takes `(project_name, output_dir)` and has a `generate` method.
