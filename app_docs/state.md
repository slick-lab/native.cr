# State Management

Manage data flow and state in your application.

---

## What is State?

State is data that changes over time and affects what the user sees. Examples:

- Current screen
- User input in forms
- Items in a list
- Loading/error states
- User session

---

## Local State

The simplest approach: store state in instance variables.

```crystal
class MyApp < Native::App
  @[Preserve]
  property counter = 0

  @[Preserve]
  property username = ""

  def setup
    @root = build_ui
  end
end
```

Use `@[Preserve]` to maintain state across hot reloads during development.

---

## State and UI Synchronization

When state changes, update the UI:

```crystal
def increment
  @counter += 1
  update_counter_display
end

def update_counter_display
  @counter_label.text = "Count: #{@counter}"
end
```

For complex UIs, rebuild affected sections:

```crystal
def set_filter(new_filter : Symbol)
  @current_filter = new_filter
  refresh_item_list
end

def refresh_item_list
  @list_container.clear
  filtered_items.each do |item|
    @list_container.addView(build_item_row(item))
  end
end
```

---

## Reactive Pattern

Create a reactive state container:

```crystal
class Observable(T)
  @value : T
  @listeners = [] of (T -> Nil)

  def initialize(@value : T)
  end

  def value : T
    @value
  end

  def value=(new_value : T)
    if @value != new_value
      @value = new_value
      notify_listeners
    end
  end

  def observe(&callback : T -> Nil)
    @listeners << callback
    callback.call(@value)  # Initial call
  end

  def update(&transformer : T -> T)
    self.value = transformer.call(@value)
  end

  private def notify_listeners
    @listeners.each &.call(@value)
  end
end
```

Usage:

```crystal
class MyApp < Native::App
  @counter = Observable(Int32).new(0)
  @username = Observable(String).new("")

  def setup
    @counter.observe { |count| update_counter_ui(count) }
    @username.observe { |name| update_greeting_ui(name) }
    @root = build_ui
  end

  def increment
    @counter.update &.+(1)
  end

  def set_username(name : String)
    @username.value = name
  end
end
```

---

## State Container Pattern

For complex apps, centralize state:

```crystal
class AppState
  include JSON::Serializable

  # User
  property user : User?
  property logged_in : Bool = false

  # Navigation
  property current_screen : Symbol = :home
  property navigation_stack = [] of Symbol

  # Data
  property items = [] of Item
  property selected_item_id : String?

  # UI State
  property loading : Bool = false
  property error_message : String?

  def save(prefs : Native::Storage::Preferences)
    prefs.set("app_state", to_json)
  end

  def self.load(prefs : Native::Storage::Preferences) : AppState
    json = prefs.get_string("app_state")
    if json && !json.empty?
      from_json(json)
    else
      AppState.new
    end
  end
end
```

Using the container:

```crystal
class MyApp < Native::App
  @[Preserve]
  property state = AppState.new

  def setup
    @state = AppState.load(Native::Storage::Preferences.new)
    @root = build_ui
  end

  def login(user : User)
    @state.user = user
    @state.logged_in = true
    navigate_to(:home)
    persist_state
  end

  def logout
    @state.user = nil
    @state.logged_in = false
    navigate_to(:login)
    persist_state
  end

  def persist_state
    @state.save(Native::Storage::Preferences.new)
  end

  def on_pause
    persist_state
  end
end
```

---

## Data Flow

### Unidirectional Data Flow

Actions modify state, state updates UI:

```
User Action → Reducer → New State → UI Update
     ↑                                    │
     └────────────────────────────────────┘
```

Implementation:

```crystal
enum Action
  Increment
  Decrement
  Reset
  SetValue
end

class Store
  @state = 0
  @listeners = [] of (Int32 -> Nil)

  def state : Int32
    @state
  end

  def dispatch(action : Action, payload : Int32 = 0)
    @state = case action
             when Action::Increment then @state + 1
             when Action::Decrement then @state - 1
             when Action::Reset then 0
             when Action::SetValue then payload
             end
    notify_listeners
  end

  def subscribe(&callback : Int32 -> Nil)
    @listeners << callback
  end

  private def notify_listeners
    @listeners.each &.call(@state)
  end
end
```

---

## Async State

Handle loading and error states:

```crystal
class AsyncState(T)
  property loading : Bool = false
  property error : String?
  property data : T?

  def initialize(@initial : T? = nil)
    @data = @initial
  end

  def loading!
    @loading = true
    @error = nil
  end

  def success(data : T)
    @loading = false
    @error = nil
    @data = data
  end

  def error!(message : String)
    @loading = false
    @error = message
  end
end
```

Usage:

```crystal
class MyApp < Native::App
  @[Preserve]
  property posts_state = AsyncState(Array(Post)).new

  def load_posts
    @posts_state.loading!
    update_posts_ui

    spawn do
      begin
        posts = fetch_posts_from_api
        @posts_state.success(posts)
        schedule_on_main { update_posts_ui }
      rescue ex
        @posts_state.error!(ex.message)
        schedule_on_main { update_posts_ui }
      end
    end
  end

  def update_posts_ui
    @posts_container.clear

    if @posts_state.loading
      @posts_container.addView(build_loading_spinner)
    elsif @posts_state.error
      @posts_container.addView(build_error_view(@posts_state.error))
    elsif posts = @posts_state.data
      posts.each do |post|
        @posts_container.addView(build_post_card(post))
      end
    end
  end
end
```

---

## Persistence

Save and restore state across app launches:

### Preferences

For simple data:

```crystal
class MyApp < Native::App
  def save_high_score(score : Int32)
    prefs = Native::Storage::Preferences.new
    current = prefs.get_int("high_score", 0)
    prefs.set("high_score", score) if score > current
  end

  def load_high_score : Int32
    Native::Storage::Preferences.new.get_int("high_score", 0)
  end
end
```

### JSON Serialization

For complex state:

```crystal
class AppState
  include JSON::Serializable

  property items = [] of Item
  property settings = Settings.new

  def save
    prefs = Native::Storage::Preferences.new
    prefs.set("app_state", to_json)
  end

  def self.load : AppState
    prefs = Native::Storage::Preferences.new
    json = prefs.get_string("app_state")
    if json && !json.empty?
      AppState.from_json(json)
    else
      AppState.new
    end
  end
end
```

### File Storage

For large data:

```crystal
def save_items_to_file(items : Array(Item))
  docs = Native::Storage::FileStorage.new(
    Native::Storage::FileStorage::StorageType::Documents
  )
  docs.write("items.json", items.to_json)
end

def load_items_from_file : Array(Item)
  docs = Native::Storage::FileStorage.new(
    Native::Storage::FileStorage::StorageType::Documents
  )
  json = docs.read("items.json")
  if json && !json.empty?
    Array(Item).from_json(json)
  else
    [] of Item
  end
end
```

---

## Best Practices

1. **Single source of truth**: One place for each piece of state
2. **Immutable updates**: Don't mutate, create new values
3. **Serializable state**: Use JSON::Serializable for persistence
4. **Separate concerns**: Keep state logic separate from UI code
5. **Handle loading states**: Always show loading/error states for async data

---

## Next Steps

- [Data and Networking](data-and-networking.md) — Fetching and caching data
- [Navigation](navigation.md) — Navigation-aware state
- [Tutorial: Data App](tutorial-data-app.md) — Full state management example
