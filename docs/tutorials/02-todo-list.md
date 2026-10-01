# Tutorial 2 — A Persistent To-Do List

Wire input, lists, and `Native::Storage::Preferences` together. The list
survives app restarts.

---

## 1. Storage in one minute

`Native::Storage::Preferences` is a named key-value store backed by
SharedPreferences on Android and NSUserDefaults on iOS:

```crystal
store = Native::Storage::Preferences.new("todos")
store.set("last_open", "2026-10-01")
store.get_string("last_open")          # => "2026-10-01"
store.get_string("missing", "fallback") # => "fallback"
store.contains?("last_open")           # => true
```

Typed helpers exist too: `set/get_int`, `get_int64`, `get_float`,
`get_double`, `get_bool`.

Lists are stored as one serialized string. Keep it simple: one line per
item, joined with `\n`.

---

## 2. The app

```crystal
require "native"

class TodoApp < Native::App
  @[Preserve]
  property items : Array(String) = [] of String

  def setup
    load_items

    @list = Native::UI::TextView.new("")
    @list.text_size = 18

    @input = Native::UI::EditText.new("New item…")
    @input.width = 260

    add_btn = Native::UI::Button.new("Add")
    add_btn.on_click do
      text = @input.text.strip
      unless text.empty?
        @items << text
        @input.text = ""
        save_items
        render_list
      end
    end

    clear_btn = Native::UI::Button.new("Clear done ideas")
    clear_btn.on_click do
      @items.clear
      save_items
      render_list
    end

    layout = Native::UI::LinearLayout.new
    layout.orientation = Native::UI::LinearLayout::Orientation::Vertical
    layout.padding = 16

    row = Native::UI::LinearLayout.new
    row.orientation = Native::UI::LinearLayout::Orientation::Horizontal
    row.addView(@input)
    row.addView(add_btn)

    layout.addView(row)
    layout.addView(@list)
    layout.addView(clear_btn)
    @root = layout
  end

  private def render_list
    if @items.empty?
      @list.text = "Nothing yet — add your first task."
    else
      @list.text = @items.each_with_index
        .map { |item, i| "#{i + 1}. #{item}" }.join("\n")
    end
  end

  private def save_items
    Native::Storage::Preferences.new("todos").set("items", @items.join("\n"))
  end

  private def load_items
    saved = Native::Storage::Preferences.new("todos").get_string("items")
    @items = saved.split("\n").reject(&.empty?)
    render_list
  end
end

Native::App.registered_subclas = TodoApp
```

### Points worth noticing

- **State lives on the app class** (`@items`), storage is only persistence.
  Load once in `setup`, mutate the array, save on change.
- **`reject(&.empty?)`** guards against trailing newlines corrupting the list.
- The row is a horizontal `LinearLayout` — the same widget, different
  orientation.

---

## 3. Level up: delete an item

Store a "delete index" before re-rendering and clear it after:

```crystal
  @[Preserve]
  property delete_index : Int32 = -1

  # in setup, after the list:
  del_btn = Native::UI::Button.new("Delete last")
  del_btn.on_click do
    unless @items.empty?
      @items.pop
      save_items
      render_list
    end
  end
```

For per-item delete buttons, rebuild the list as one vertical `LinearLayout`
containing a row per item — each row a `TextView` plus a small `Button`
whose `on_click` removes that index.

---

## 4. Exercises

1. Persist a `get_bool("show_help")` flag and show a one-time hint.
2. Store the item count with `set("count", @items.size)` and display it.
3. Use `contains?("items")` to detect a first launch.

Next: [Tutorial 3 — Talking to the Network](03-network-app.md)
