# Changelog

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
