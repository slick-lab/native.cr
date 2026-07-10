# Tutorial: Your First App

Build a complete task management app from scratch. By the end, you'll understand views, layouts, state management, user input, and data persistence.

---

## What You'll Build

A task manager app with these features:

- Add new tasks
- Mark tasks complete
- Delete tasks
- Persist tasks between sessions
- Clean, native UI

---

## Prerequisites

Complete [Getting Started](getting-started.md) first. You should have:

- Crystal installed
- Android SDK or Xcode configured
- A working project created

---

## Step 1: Project Setup

Create a new project:

```bash
crystal main.cr create TaskApp
cd TaskApp
```

Open `src/app/main.cr` in your editor. Replace the contents with:

```crystal
require "native"

class TaskApp < Native::App
  @[Preserve]
  property tasks = [] of Task

  def setup
    @root = build_ui
  end

  def build_ui
    container = Native::UI::LinearLayout.new
    container.orientation = Native::UI::LinearLayout::Orientation::Vertical
    container
  end
end

struct Task
  property id : String
  property title : String
  property completed : Bool

  def initialize(@title : String, @id : String = UUID.random.to_s, @completed : Bool = false)
  end
end
```

This creates the basic structure. The `tasks` array holds our data, marked with `@[Preserve]` so it survives hot reloads.

---

## Step 2: Build the Header

Add a title and input field at the top:

```crystal
def build_ui
  container = Native::UI::LinearLayout.new
  container.orientation = Native::UI::LinearLayout::Orientation::Vertical
  container.padding = 16

  # Header
  title = Native::UI::TextView.new("My Tasks")
  title.text_size = 24.0
  title.padding_bottom = 16
  container.addView(title)

  # Input row
  input_row = Native::UI::LinearLayout.new
  input_row.orientation = Native::UI::LinearLayout::Orientation::Horizontal

  @input = Native::UI::EditText.new
  @input.hint = "Add a new task..."
  @input.layout_weight = 1.0
  @input.on_enter { add_task }
  input_row.addView(@input)

  add_btn = Native::UI::Button.new("Add")
  add_btn.on_click { add_task }
  input_row.addView(add_btn)

  container.addView(input_row)
  container
end
```

You'll need to add `@input` as an instance variable:

```crystal
class TaskApp < Native::App
  @[Preserve]
  property tasks = [] of Task

  @input : Native::UI::EditText

  # ...
end
```

---

## Step 3: Implement Add Task

Add the `add_task` method:

```crystal
def add_task
  text = @input.text.strip
  return if text.empty?

  task = Task.new(text)
  @tasks << task
  @input.text = ""
  refresh_list
end
```

When the user adds a task:

1. Get the text from the input field
2. Trim whitespace
3. Return early if empty
4. Create a new Task
5. Add to our array
6. Clear the input
7. Refresh the list view

---

## Step 4: Display the Task List

Create a RecyclerView to display tasks:

```crystal
def build_ui
  container = Native::UI::LinearLayout.new
  container.orientation = Native::UI::LinearLayout::Orientation::Vertical
  container.padding = 16

  # ... header and input code ...

  # Task list
  @recycler = Native::UI::RecyclerView.new
  @recycler.layout_weight = 1.0
  @recycler.adapter = TaskAdapter.new(self)
  container.addView(@recycler)

  container
end
```

Now create the adapter:

```crystal
class TaskAdapter < Native::UI::RecyclerView::Adapter
  def initialize(@app : TaskApp)
  end

  def item_count : Int32
    @app.tasks.size
  end

  def on_bind_view(holder : Native::UI::RecyclerView::ViewHolder, position : Int32)
    task = @app.tasks[position]
    # Update the view holder with task data
  end

  def on_create_view(parent : Native::UI::ViewGroup, view_type : Int32) : Native::UI::RecyclerView::ViewHolder
    # Create view for each item
  end
end
```

For simplicity, let's use a simpler approach with a LinearLayout:

```crystal
def refresh_list
  # Clear existing task views
  @task_container.clear if @task_container

  @tasks.each_with_index do |task, index|
    row = build_task_row(task, index)
    @task_container.addView(row)
  end
end

def build_task_row(task : Task, index : Int32) : Native::UI::View
  row = Native::UI::LinearLayout.new
  row.orientation = Native::UI::LinearLayout::Orientation::Horizontal
  row.padding = 12
  row.background_color = 0xFFF5F5F5

  # Checkbox
  checkbox = Native::UI::Checkbox.new
  checkbox.checked = task.completed
  checkbox.on_check_change { |checked| toggle_task(index, checked) }
  row.addView(checkbox)

  # Title
  label = Native::UI::TextView.new(task.title)
  label.layout_weight = 1.0
  label.padding_left = 12
  label.text_color = task.completed ? 0xFF999999 : 0xFF000000
  row.addView(label)

  # Delete button
  delete = Native::UI::Button.new("×")
  delete.on_click { delete_task(index) }
  row.addView(delete)

  row
end
```

---

## Step 5: Complete the App

Here's the complete `main.cr`:

```crystal
require "native"

struct Task
  include JSON::Serializable

  property id : String
  property title : String
  property completed : Bool

  def initialize(@title : String, @id : String = UUID.random.to_s, @completed : Bool = false)
  end
end

class TaskApp < Native::App
  @[Preserve]
  property tasks = [] of Task

  @input : Native::UI::EditText
  @task_container : Native::UI::LinearLayout

  def setup
    load_tasks
    @root = build_ui
    refresh_list
  end

  def build_ui
    container = Native::UI::LinearLayout.new
    container.orientation = Native::UI::LinearLayout::Orientation::Vertical
    container.padding = 16

    # Header
    title = Native::UI::TextView.new("My Tasks")
    title.text_size = 24.0
    title.padding_bottom = 16
    container.addView(title)

    # Input row
    input_row = Native::UI::LinearLayout.new
    input_row.orientation = Native::UI::LinearLayout::Orientation::Horizontal

    @input = Native::UI::EditText.new
    @input.hint = "Add a new task..."
    @input.layout_weight = 1.0
    @input.on_enter { add_task }
    input_row.addView(@input)

    add_btn = Native::UI::Button.new("Add")
    add_btn.on_click { add_task }
    input_row.addView(add_btn)

    container.addView(input_row)

    # Task list container
    @task_container = Native::UI::LinearLayout.new
    @task_container.orientation = Native::UI::LinearLayout::Orientation::Vertical
    @task_container.padding_top = 16
    container.addView(@task_container)

    container
  end

  def add_task
    text = @input.text.strip
    return if text.empty?

    task = Task.new(text)
    @tasks << task
    @input.text = ""
    save_tasks
    refresh_list
  end

  def toggle_task(index : Int32, completed : Bool)
    @tasks[index].completed = completed
    save_tasks
    refresh_list
  end

  def delete_task(index : Int32)
    @tasks.delete_at(index)
    save_tasks
    refresh_list
  end

  def refresh_list
    @task_container.clear

    if @tasks.empty?
      empty = Native::UI::TextView.new("No tasks yet. Add one above!")
      empty.text_color = 0xFF999999
      empty.padding = 32
      @task_container.addView(empty)
      return
    end

    @tasks.each_with_index do |task, index|
      row = build_task_row(task, index)
      @task_container.addView(row)
    end
  end

  def build_task_row(task : Task, index : Int32) : Native::UI::View
    row = Native::UI::LinearLayout.new
    row.orientation = Native::UI::LinearLayout::Orientation::Horizontal
    row.padding = 12

    # Checkbox
    checkbox = Native::UI::Checkbox.new
    checkbox.checked = task.completed
    checkbox.on_check_change { |checked| toggle_task(index, checked) }
    row.addView(checkbox)

    # Title
    label = Native::UI::TextView.new(task.title)
    label.layout_weight = 1.0
    label.padding_left = 12
    label.text_color = task.completed ? 0xFF999999 : 0xFF000000
    row.addView(label)

    # Delete button
    delete = Native::UI::Button.new("Delete")
    delete.on_click { delete_task(index) }
    delete.text_color = 0xFFFF0000
    row.addView(delete)

    row
  end

  def save_tasks
    prefs = Native::Storage::Preferences.new
    prefs.set("tasks", @tasks.to_json)
  end

  def load_tasks
    prefs = Native::Storage::Preferences.new
    json = prefs.get_string("tasks")
    @tasks = if json && !json.empty?
      Array(Task).from_json(json)
    else
      [] of Task
    end
  end

  def on_pause
    save_tasks
  end
end
```

---

## Step 6: Run the App

Build and run:

```bash
# Android
crystal build android
adb install -r build/android/app.apk

# Or with hot reload for development
crystal reload 
```

---

## What You Learned

- **View Hierarchy**: Building UI with nested layouts
- **User Input**: EditText and handling enter key
- **Event Handling**: Button clicks and checkbox changes
- **State Management**: `@[Preserve]` for surviving hot reloads
- **Data Persistence**: Saving and loading with Preferences
- **Dynamic Lists**: Building and rebuilding views programmatically

---

## Next Steps

Improve the app:

- Edit existing tasks (tap to edit)
- Filter by completed/pending
- Add due dates
- Support categories
- Add swipe-to-delete

Learn more:

- [UI Components](ui-components.md) — All available widgets
- [Layouts and Styling](layout.md) — Positioning and theming
- [Navigation](navigation.md) — Multiple screens
- [State Management](state.md) — Advanced patterns
