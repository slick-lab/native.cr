# Changelog

## 0.1.10

External review fixes — platform integration hardening.

### Android HTTP actually works now (critical)
- The JNI signature mismatch is gone: `HTTPClient.execute` is now a
  synchronous `(...)String` method matching exactly the signature
  Crystal looks up. Previously every synchronous Android request failed
  at GetStaticMethodID. The old callback-based method lives on as
  `executeAsync`.
- `StreamCallback` is now a real class (`new StreamCallback(J)`) with
  native dispatch methods bridging chunks/status/errors back into
  Crystal through exported JNI funs — it was an *interface* Crystal
  tried to instantiate, which always throws. Android streaming now
  delivers response chunks to `on_chunk`, the final status to
  `on_complete` and transport errors to `on_error` (both new optional
  `Request` hooks).
- Stream events are delivered from a dedicated single-thread Java
  executor, and the Crystal dispatch funs register that thread with
  the Boehm GC before any allocation.

### iOS streaming is real now (critical)
- `http_request_stream` uses a per-request `URLSessionDataDelegate`
  instead of firing and forgetting. Chunks, status and errors are
  delivered on the main queue (the thread the Crystal runtime lives
  on), through C trampolines into the same stream registry as Android.

### File storage hardening (high)
- Path traversal: filenames are validated on both sides of the bridge
  (Crystal `Native::Storage.valid_filename?` + Swift
  `safeStorageName`) — separators, `.`/`..` components and NUL are
  rejected before anything reaches a path builder. Applies to write,
  read, exists?, delete and list (subdirectory traversal likewise).
- Android file IO: `FileInputStream` construction now checks for
  pending JNI exceptions (a missing file used to poison every
  subsequent JNI call), and the write() byte array is released exactly
  once (it used to be deleted twice).

### Networking fixes found while fixing the above
- `Response.new(named args)` never compiled — an empty initialize
  rejected every error-path construction in the file. (Crystal only
  type-checks reachable code, and no spec/example reached them.)
- `HTTPClient#get` without a block didn't exist; `HTTP.get(url)` was
  therefore a compile error for any real app.
- `build_desktop_client` referenced `HTTP::Client`, which resolved to
  the `Native::Network::HTTP` convenience module inside this namespace
  — an undefined constant. Same for `HTTP::Request`/`HTTP::Headers`.
- Android and iOS response envelopes now include response headers
  (previously dropped on both platforms).

### Permissions
- Callbacks are no longer left pending when the Android activity is
  unavailable (or on desktop, which has no backend at all): they fire
  with NotDetermined immediately.
- CameraRoll, Speech and Motion now map to real Android permission
  strings (READ_MEDIA_IMAGES, RECORD_AUDIO, ACTIVITY_RECOGNITION)
  instead of the empty string.

### Misc
- README version badge matches shard.yml again (0.1.7 → 0.1.10).
- `native create` help no longer advertises a nonexistent `library`
  template.
- Desktop streaming honours the request method and timeout, and calls
  the new `on_complete`/`on_error` hooks.

## 0.1.9

### Hot-reload state is real now
`@[Preserve]` actually works. Annotate app state, it survives a reload:

```crystal
class CounterApp < Native::App
  @[Preserve]
  property count : Int32 = 0
end
```

`state_to_json` / `state_from_json` are macro-generated from the
annotated ivars of your subclass (per-subclass, not shared). Supported:
`Bool`, `Int32/64`, `Float32/64`, `String`, `Array(String|Int32|Float64)`,
`JSON::Any`, plus nilable variants — an unsupported type is a compile
error, not a silent skip. Corrupt state files are ignored with defaults
rather than crashing the reloaded app. Both `@[Preserve]` and
`@[Native::Preserve]` are accepted.

### DSL
- `UI::Column` / `UI::Row` — composable layouts with `spacing` and
  `alignment` (`Alignment::Center` etc.), with an optional block form:
  `Column.new { |c| c.spacing = 20 }`
- `add_child` / `add_view` / `remove_child` / `remove_view` — snake_case
  (camelCase originals kept as aliases)
- `button.on_click = ->{ increment }` — proc-assignment form next to the
  block form
- `text_view.color =` — short alias for `text_color=`
- `corner_radius = 24` or `CornerRadius.all(24)` on any view (Android
  GradientDrawable, iOS CALayer)
- `App#set_background_color(r, g, b)` — implemented (docs showed it; it
  never existed). Applies to the window/root, pending until `root=` if
  set before a root exists
- `Color.from_rgb(0.1, 0.2, 0.3)` float constructor
- `Native::Platform::HapticFeedback.light/medium/heavy`
- Top-level `UI` / `Color` / `Alignment` / `CornerRadius` aliases — both
  the bare and `Native::`-qualified styles work, in type and expression
  positions

### Fixes
- **Android app builds were broken since 0.1.0**: framework widgets
  referenced `JNIHelpers` bare, which resolves to nothing the moment a
  widget is instantiated (the CLI entry never instantiates widgets, so
  typecheck CI never caught it). Found by the new examples job; fixed
  with a `Native`-scope alias.
- **Threading**: `label.text = ...` from Crystal callbacks (background
  thread) now hops to the UI thread on Android via
  `NativeHelper.setTextOnUiThread` instead of risking
  `CalledFromWrongThreadException`. iOS already routed through `onMain`.
- `examples/` all compile now: hello-world `@root = @label` typo,
  mini_app never assigned `@root`, camera_app rewritten against the real
  Camera API, screens-app + basic_app return-type fixes.
- CI: new `examples` job (desktop build + android/ios typecheck per
  example) — the build finally proves the docs.
- postinstall: `curl -fL` (no more 404 pages saved as `.o` files) and
  sha256 verification against each release's `CHECKSUMS` manifest. The
  libgc/libpcre pin to v0.1.6 is deliberate (engine-linked runtime
  pair) and now documented as such.

### Not yet (tracked for next releases)
- Platform backend interface to replace per-widget `{% if flag %}`
  blocks (the big refactor — desktop widgets stay introspection-only
  until then)
- On-device/emulator smoke test of the counter app
- Per-corner radii on iOS (currently uniform via max)

## 0.1.8

iOS native runtime + end-to-end iOS CLI pipeline, push notifications,
226-fun LibIOS binding contract, JNIHelpers additions. Fixes: form-body
encoding (`URI.encode_www_form`), deprecated API sweep (`Time.monotonic`,
float `sleep`) — zero warnings, 122 specs green. Docs: four-part tutorial
series, image-picker reference, index repairs.

## 0.1.7

CLI `reload` entry-point handling, doctor improvements, storage
and permission hardening.

## 0.1.6

Prebuilt static libraries (libgc.a, libpcre.a) for Android/iOS linking,
postinstall download pipeline.

## 0.1.5 and earlier

See git history and release notes on GitHub.
