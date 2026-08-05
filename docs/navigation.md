# Navigation

native.cr ships a lightweight stack-based screen system so your app can
consist of multiple pages with push/pop transitions.

---

## Quick start

```crystal
require "native"

# ── Define your screens ──────────────────────────────────────────────────────

class HomeScreen < Native::Navigation::Screen
  def initialize(@nav : Native::Navigation::Navigator)
  end

  def build : Native::UI::View
    layout = Native::UI::LinearLayout.new

    btn = Native::UI::Button.new("Open Detail")
    btn.on_click { @nav.push(DetailScreen.new(@nav)) }

    layout.addView(btn)
    layout
  end
end

class DetailScreen < Native::Navigation::Screen
  def initialize(@nav : Native::Navigation::Navigator)
  end

  def build : Native::UI::View
    layout = Native::UI::LinearLayout.new

    label = Native::UI::TextView.new("Detail page")

    back = Native::UI::Button.new("← Back")
    back.on_click { @nav.pop }

    layout.addView(label)
    layout.addView(back)
    layout
  end
end

# ── Wire it into your App ────────────────────────────────────────────────────

class MyApp < Native::App
  @nav : Native::Navigation::Navigator? = nil

  def setup
    nav = Native::Navigation::Navigator.new(self)
    @nav = nav
    nav.push(HomeScreen.new(nav))   # ← first screen, displayed immediately
  end

  # Forward the hardware Back key to the navigator
  def on_key_pressed(key : Int32)
    if key == 4   # KEYCODE_BACK
      @nav.try(&.back)
    end
  end
end

Native::App.registered_subclass = MyApp
```

---

## Screen lifecycle

| Callback | When it fires |
|---|---|
| `build` | First time the screen is shown (result is cached). |
| `on_appear` | Every time this screen becomes the top of the stack. |
| `on_disappear` | Every time this screen is covered by another or popped. |
| `on_back` | Hardware Back pressed while this screen is on top. Return `true` to consume and prevent pop. |

To force a screen to rebuild its view (e.g. after a data change), call
`invalidate` before pushing it again or while it is on top:

```crystal
screen.invalidate   # clears cached view; next call to view rebuilds
```

---

## Navigator API

```crystal
nav = Native::Navigation::Navigator.new(app)

nav.push(screen)        # push a new screen on top
nav.pop                 # remove top screen, return to previous (Bool)
nav.replace(screen)     # swap top screen in-place (no stack growth)
nav.pop_to_root         # pop everything back to the first screen
nav.back                # handle Back: asks top screen first, then pops
nav.current             # Screen? currently on top
nav.depth               # Int32, number of screens in the stack
nav.stack               # Array(Screen), full stack (bottom → top)
```

---

## Convenience methods on Screen

From inside a Screen you can navigate without holding a Navigator reference:

```crystal
class MyScreen < Native::Navigation::Screen
  def build
    btn = Native::UI::Button.new("Next")
    btn.on_click { push(NextScreen.new) }  # calls navigator.push
    # ...
  end
end
```

`push(screen)` and `pop` are delegated to `self.navigator` automatically.

---

## How root-view attachment works (Android)

When `Navigator#push` (or `App#root=`) is called, native.cr calls
`com.nativecr.NativeHelper.setContentView(activity, view)` which uses
`Activity.runOnUiThread` to dispatch `setContentView` on the main thread.
This is safe to call from Crystal's background thread.

---

## Toolbar

`Native::Navigation::Toolbar` is a separate widget — it is not coupled to
`Navigator` and can be used standalone. You are responsible for placing it
at the top of your screen's layout and calling `setupWithActivity` if you
want it used as the app's ActionBar.
