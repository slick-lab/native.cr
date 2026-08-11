# Tutorial: Task Manager

Build a complete task management app with lists, input, and persistence.

**Time:** 30 minutes
**Difficulty:** Beginner

---

## What You'll Build

A full-featured task manager with:

- Add new tasks with text input
- Display tasks in a scrollable list
- Mark tasks complete/incomplete
- Delete tasks
- Data persists between app launches

---

## Step 1: Define the Data Model

Create `src/app/models/task.cr`:

```crystal
struct Task
  include JSON::Serializable

  property id : String
  property title : String
  property completed : Bool
  property created_at : String

  def initialize(@title : String, @id : String = UUID.random.to_s)
    @completed = false
    @created_at = Time.utc.to_iso8601
  end
end
```

This struct:

- Uses `JSON::Serializable` for persistence
- Has a unique ID for each task
- Tracks completion state
- Records creation time

---

## Step 2: Build the Main App

Create `src/app/main.cr`:

```crystal
require "native"
require "./models/task"

class TaskManagerApp < Native::App
  @[Preserve]
  property tasks : Array(Task) = [] of Task

  @layout : Native::UI::LinearLayout
  @task_list : Native::UI::LinearLayout
  @input : Native::UI::EditText
  @empty_label : Native::UI::TextView

  def setup
    load_tasks
    build_ui
    refresh_task_list
  end

  def build_ui
    # Main container
    @layout = Native::UI::LinearLayout.new
    @layout.orientation = Native::UI::LinearLayout::Orientation::Vertical
    @layout.set_padding(16, 16, 16, 16)

    # Header
    header = build_header

    # Task list container
    @task_list = Native::UI::LinearLayout.new
    @task_list.orientation = Native::UI::LinearLayout::Orientation::Vertical

    # Empty state
    @empty_label = Native::UI::TextView.new("No tasks yet. Add one below!")
    @empty_label.text_size = 16
    @empty_label.text_color = Native::Math::Color.from_rgba(150, 150, 150, 255)
    @empty_label.center

    # Scroll view for tasks
    scroll = Native::UI::ScrollView.new
    scroll.addView(@task_list)

    # Input area
    input_area = build_input_area

    @layout.addView(header)
    @layout.addView(scroll)
    @layout.addView(@empty_label)
    @layout.addView(input_area)
  end

  def build_header : Native::UI::View
    header = Native::UI::LinearLayout.new
    header.orientation = Native::UI::LinearLayout::Orientation::Vertical
    header.set_padding(0, 0, 0, 16)

    title = Native::UI::TextView.new("My Tasks")
    title.text_size = 28
    title.text_color = Native::Math::Color.from_rgba(33, 33, 33, 255)

    # Task count
    @count_label = Native::UI::TextView.new("0 tasks")
    @count_label.text_size = 14
    @count_label.text_color = Native::Math::Color.from_rgba(100, 100, 100, 255)

    header.addView(title)
    header.addView(@count_label)
    header
  end

  def build_input_area : Native::UI::View
    container = Native::UI::LinearLayout.new
    container.orientation = Native::UI::LinearLayout::Orientation::Horizontal
    container.set_padding(0, 16, 0, 0)

    # Text input
    @input = Native::UI::EditText.new
    @input.hint = "Add a new task..."
    @input.width = 0  # Will use weight
    # Note: weight requires special handling in addView

    # Add button
    add_btn = Native::UI::Button.new("Add")
    add_btn.width = 100
    add_btn.height = 48
    add_btn.background_color = Native::Math::Color.blue
    add_btn.text_color = Native::Math::Color.white
    add_btn.on_click { add_task }

    container.addView(@input)
    container.addView(add_btn)
    container
  end

  def add_task
    text = @input.text.strip
    return if text.empty?

    task = Task.new(text)
    @tasks << task
    @input.text = ""

    save_tasks
    refresh_task_list
  end

  def toggle_task(index : Int32)
    @tasks[index].completed = !@tasks[index].completed
    save_tasks
    refresh_task_list
  end

  def delete_task(index : Int32)
    @tasks.delete_at(index)
    save_tasks
    refresh_task_list
  end

  def refresh_task_list
    @task_list.removeAllViews

    if @tasks.empty?
      @empty_label.visible = true
    else
      @empty_label.visible = false
      @tasks.each_with_index do |task, index|
        row = build_task_row(task, index)
        @task_list.addView(row)
      end
    end

    update_count_label
  end

  def build_task_row(task : Task, index : Int32) : Native::UI::View
    row = Native::UI::LinearLayout.new
    row.orientation = Native::UI::LinearLayout::Orientation::Horizontal
    row.set_padding(12, 12, 12, 12)

    # Checkbox
    checkbox = Native::UI::Checkbox.new
    checkbox.checked = task.completed
    checkbox.on_check_change { |checked| toggle_task(index) }

    # Task title
    title = Native::UI::TextView.new(task.title)
    title.text_size = 16
    title.text_color = task.completed ?
      Native::Math::Color.from_rgba(150, 150, 150, 255) :
      Native::Math::Color.from_rgba(33, 33, 33, 255)

    # Delete button
    delete_btn = Native::UI::Button.new("×")
    delete_btn.text_size = 20
    delete_btn.width = 50
    delete_btn.height = 40
    delete_btn.background_color = Native::Math::Color.from_rgba(0.9, 0.2, 0.2, 1.0)
    delete_btn.text_color = Native::Math::Color.white
    delete_btn.on_click { delete_task(index) }

    row.addView(checkbox)
    row.addView(title)
    row.addView(delete_btn)
    row
  end

  def update_count_label
    completed = @tasks.count(&.completed)
    total = @tasks.size
    pending = total - completed

    @count_label.text = "#{pending} pending, #{completed} completed"
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
  rescue
    @tasks = [] of Task
  end

  def on_pause
    save_tasks
  end
end

Native::App.registered_subclass = TaskManagerApp
```

---

## Step 3: Understanding EditText

EditText provides text input:

```crystal
@input = Native::UI::EditText.new
@input.hint = "Add a new task..."  # Placeholder text
@input.text = ""                    # Get/set current text
@input.input_type = Native::UI::EditText::InputType::Text  # Input mode
```

### Input Types

| Type | Use Case |
|------|----------|
| `Text` | Regular text |
| `Number` | Numbers only |
| `Phone` | Phone numbers |
| `Email` | Email addresses |
| `Password` | Hidden text |

### Getting Text

```crystal
text = @input.text.strip  # Get text and remove whitespace
return if text.empty?      # Don't add empty tasks
```

---

## Step 4: Understanding Checkbox

Checkbox provides boolean selection:

```crystal
checkbox = Native::UI::Checkbox.new
checkbox.checked = true  # Set state
checkbox.on_check_change { |checked| handle_change(checked) }
```

The callback receives the new checked state.

---

## Step 5: Removing Views

When the list changes, rebuild it:

```crystal
@task_list.removeAllViews  # Clear all children

@tasks.each_with_index do |task, index|
  row = build_task_row(task, index)
  @task_list.addView(row)
end
```

---

## Step 6: ScrollView

Wrap the task list in a ScrollView for scrolling:

```crystal
scroll = Native::UI::ScrollView.new
scroll.addView(@task_list)
```

ScrollView enables vertical scrolling when content exceeds screen height.

---

## Complete Enhanced Version

Here's a more polished version with better styling:

```crystal
require "native"
require "json"

struct Task
  include JSON::Serializable

  property id : String
  property title : String
  property completed : Bool
  property created_at : String

  def initialize(@title : String, @id : String = UUID.random.to_s)
    @completed = false
    @created_at = Time.utc.to_iso8601
  end
end

class TaskManagerApp < Native::App
  @[Preserve]
  property tasks : Array(Task) = [] of Task

  @layout : Native::UI::LinearLayout
  @task_list : Native::UI::LinearLayout
  @input : Native::UI::EditText
  @empty_label : Native::UI::TextView
  @count_label : Native::UI::TextView

  COLORS = {
    primary:    Native::Math::Color.from_rgba(0.0, 0.48, 1.0, 1.0),
    completed:  Native::Math::Color.from_rgba(0.6, 0.6, 0.6, 1.0),
    danger:     Native::Math::Color.from_rgba(0.9, 0.3, 0.3, 1.0),
    text_dark:  Native::Math::Color.from_rgba(0.13, 0.13, 0.13, 1.0),
    text_light: Native::Math::Color.from_rgba(0.6, 0.6, 0.6, 1.0),
    bg_task:    Native::Math::Color.from_rgba(0.98, 0.98, 0.98, 1.0),
  }

  def setup
    load_tasks
    build_ui
    refresh_task_list
  end

  def build_ui
    @layout = Native::UI::LinearLayout.new
    @layout.orientation = Native::UI::LinearLayout::Orientation::Vertical
    @layout.set_padding(16, 16, 16, 16)

    # Header section
    @layout.addView(build_header)

    # Empty state message
    @empty_label = Native::UI::TextView.new("No tasks yet")
    @empty_label.text_size = 16
    @empty_label.text_color = COLORS[:text_light]
    @empty_label.center
    @layout.addView(@empty_label)

    # Task list in scroll view
    @task_list = Native::UI::LinearLayout.new
    @task_list.orientation = Native::UI::LinearLayout::Orientation::Vertical

    scroll = Native::UI::ScrollView.new
    scroll.addView(@task_list)
    @layout.addView(scroll)

    # Input section at bottom
    @layout.addView(build_input_area)
  end

  def build_header : Native::UI::View
    container = Native::UI::LinearLayout.new
    container.orientation = Native::UI::LinearLayout::Orientation::Vertical
    container.set_padding(0, 0, 0, 24)

    title = Native::UI::TextView.new("Task Manager")
    title.text_size = 32
    title.text_color = COLORS[:text_dark]
    title.center

    @count_label = Native::UI::TextView.new("0 tasks")
    @count_label.text_size = 14
    @count_label.text_color = COLORS[:text_light]
    @count_label.center

    container.addView(title)
    container.addView(@count_label)
    container
  end

  def build_input_area : Native::UI::View
    container = Native::UI::LinearLayout.new
    container.orientation = Native::UI::LinearLayout::Orientation::Horizontal
    container.set_padding(0, 16, 0, 0)

    @input = Native::UI::EditText.new
    @input.hint = "What needs to be done?"
    @input.width = 250
    @input.height = 48

    add_btn = Native::UI::Button.new("Add")
    add_btn.width = 80
    add_btn.height = 48
    add_btn.background_color = COLORS[:primary]
    add_btn.text_color = Native::Math::Color.white
    add_btn.on_click { add_task }

    container.addView(@input)
    container.addView(add_btn)
    container
  end

  def add_task
    title = @input.text.strip
    return if title.empty? || title.size < 1

    task = Task.new(title)
    @tasks.unshift(task)  # Add to beginning
    @input.text = ""

    save_tasks
    refresh_task_list

    # Haptic feedback
    Native::Platform.vibrate(30)
  end

  def toggle_task(index : Int32)
    @tasks[index].completed = !@tasks[index].completed
    save_tasks
    refresh_task_list
  end

  def delete_task(index : Int32)
    @tasks.delete_at(index)
    save_tasks
    refresh_task_list
    Native::Platform.vibrate(20)
  end

  def refresh_task_list
    @task_list.removeAllViews

    @empty_label.visible = @tasks.empty?

    @tasks.each_with_index do |task, index|
      row = build_task_row(task, index)
      @task_list.addView(row)
    end

    update_count
  end

  def build_task_row(task : Task, index : Int32) : Native::UI::View
    row = Native::UI::LinearLayout.new
    row.orientation = Native::UI::LinearLayout::Orientation::Horizontal
    row.set_padding(16, 16, 16, 16)

    # Checkbox
    checkbox = Native::UI::Checkbox.new
    checkbox.checked = task.completed
    checkbox.on_check_change { |checked| toggle_task(index) }
    row.addView(checkbox)

    # Task text
    label = Native::UI::TextView.new(task.title)
    label.text_size = 16
    label.text_color = task.completed ? COLORS[:completed] : COLORS[:text_dark]
    label.width = 200
    row.addView(label)

    # Delete button
    delete_btn = Native::UI::Button.new("Del")
    delete_btn.width = 60
    delete_btn.height = 36
    delete_btn.text_size = 12
    delete_btn.background_color = COLORS[:danger]
    delete_btn.text_color = Native::Math::Color.white
    delete_btn.on_click { delete_task(index) }
    row.addView(delete_btn)

    row
  end

  def update_count
    total = @tasks.size
    completed = @tasks.count(&.completed)
    pending = total - completed

    case total
    when 0
      @count_label.text = "No tasks"
    when 1
      @count_label.text = "1 task"
    else
      @count_label.text = "#{total} tasks (#{pending} pending)"
    end
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
  rescue
    @tasks = [] of Task
  end

  def on_pause
    save_tasks
  end
end

Native::App.registered_subclass = TaskManagerApp
```

---

## What You Learned

- Building scrollable lists with ScrollView + LinearLayout
- Creating text input with EditText
- Using Checkbox for boolean states
- Persisting complex data with JSON serialization
- Dynamically rebuilding UI from state
- Managing collections of data

---

## Challenges

1. Add task editing (tap to edit)
2. Add categories/tags to tasks
3. Add due dates
4. Implement swipe to delete (advanced)
5. Add task search/filter

---

## Next Tutorial

Continue with [Weather App](weather-app.md) to learn about networking and APIs.
