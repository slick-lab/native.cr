@[Link(ldflags: "-L#{__DIR__}/../../../../vendor/imgui/lib -limgui_native -lSDL2 -lGL -ldl -lpthread -lstdc++")]
lib LibImGui
  fun imgui_context_create = "imgui_context_create"()
  fun imgui_context_destroy = "imgui_context_destroy"()
  fun imgui_style_dark = "imgui_style_dark"()
  fun imgui_new_frame = "imgui_new_frame"()
  fun imgui_render = "imgui_render"()
  fun imgui_get_draw_data = "imgui_get_draw_data"() : Void*

  fun imgui_begin = "imgui_begin"(name : UInt8*, flags : Int32) : Int32
  fun imgui_end = "imgui_end"()
  fun imgui_text = "imgui_text"(text : UInt8*)
  fun imgui_text_colored = "imgui_text_colored"(r : Float32, g : Float32, b : Float32, a : Float32, text : UInt8*)
  fun imgui_text_wrapped = "imgui_text_wrapped"(text : UInt8*)
  fun imgui_separator = "imgui_separator"()
  fun imgui_spacing = "imgui_spacing"()
  fun imgui_dummy = "imgui_dummy"(w : Float32, h : Float32)
  fun imgui_button = "imgui_button"(label : UInt8*, w : Float32, h : Float32) : Int32
  fun imgui_input_text = "imgui_input_text"(label : UInt8*, buf : UInt8*, buf_size : Int32) : Int32
  fun imgui_input_text_multiline = "imgui_input_text_multiline"(label : UInt8*, buf : UInt8*, buf_size : Int32, w : Float32, h : Float32) : Int32
  fun imgui_checkbox = "imgui_checkbox"(label : UInt8*, v : Int32*) : Int32
  fun imgui_slider_float = "imgui_slider_float"(label : UInt8*, v : Float32*, min : Float32, max : Float32) : Int32
  fun imgui_progress_bar = "imgui_progress_bar"(fraction : Float32, w : Float32, h : Float32, overlay : UInt8*)
  fun imgui_set_next_window_pos = "imgui_set_next_window_pos"(x : Float32, y : Float32)
  fun imgui_set_next_window_size = "imgui_set_next_window_size"(w : Float32, h : Float32)
  fun imgui_push_font_scale = "imgui_push_font_scale"(scale : Float32)
  fun imgui_pop_font_scale = "imgui_pop_font_scale"()
  fun imgui_push_style_color = "imgui_push_style_color"(idx : Int32, r : Float32, g : Float32, b : Float32, a : Float32)
  fun imgui_pop_style_color = "imgui_pop_style_color"(count : Int32)
  fun imgui_push_style_var_float = "imgui_push_style_var_float"(idx : Int32, val : Float32)
  fun imgui_pop_style_var = "imgui_pop_style_var"(count : Int32)
  fun imgui_begin_child = "imgui_begin_child"(id : UInt8*, w : Float32, h : Float32, border : Int32, flags : Int32) : Int32
  fun imgui_end_child = "imgui_end_child"()
  fun imgui_same_line = "imgui_same_line"(offset : Float32, spacing : Float32)
  fun imgui_get_display_size = "imgui_get_display_size"(w : Float32*, h : Float32*)
  fun imgui_get_font_size = "imgui_get_font_size"() : Float32

  fun imgui_backend_init = "imgui_backend_init"(window : Void*, gl_ctx : Void*) : Int32
  fun imgui_backend_shutdown = "imgui_backend_shutdown"()
  fun imgui_backend_new_frame = "imgui_backend_new_frame"(window : Void*)
  fun imgui_backend_render = "imgui_backend_render"(draw_data : Void*)
  fun imgui_backend_process_event = "imgui_backend_process_event"(event : Void*) : Int32
end

module ImGui
  WINDOW_NO_TITLE_BAR  = 1 << 0
  WINDOW_NO_RESIZE     = 1 << 1
  WINDOW_NO_MOVE       = 1 << 2
  WINDOW_NO_SCROLLBAR  = 1 << 3
  WINDOW_NO_SCROLL_WITH_MOUSE = 1 << 4
  WINDOW_NO_COLLAPSE   = 1 << 5
  WINDOW_ALWAYS_AUTO_RESIZE = 1 << 6
  WINDOW_NO_BACKGROUND = 1 << 7
  WINDOW_NO_SAVED_SETTINGS = 1 << 8
  WINDOW_NO_MOUSE_INPUTS = 1 << 9
  WINDOW_MENU_BAR      = 1 << 10
  WINDOW_HORIZONTAL_SCROLLBAR = 1 << 11
  WINDOW_NO_FOCUS_ON_APPEARING = 1 << 12
  WINDOW_NO_BRING_TO_DISPLAY_FRONT = 1 << 13
  WINDOW_ALWAYS_VERTICAL_SCROLLBAR = 1 << 14
  WINDOW_ALWAYS_HORIZONTAL_SCROLLBAR = 1 << 15

  COL_TEXT              = 0
  COL_WINDOW_BG         = 2
  COL_FRAME_BG          = 7
  COL_FRAME_BG_HOVERED  = 8
  COL_TITLE_BG_ACTIVE   = 12
  COL_BUTTON            = 21
  COL_BUTTON_HOVERED    = 22
  COL_BUTTON_ACTIVE     = 23
  COL_SEPARATOR         = 27
  COL_SLIDER_GRAB       = 33

  STYLE_VAR_WINDOW_ROUNDING = 3
  STYLE_VAR_FRAME_ROUNDING  = 5
  STYLE_VAR_ITEM_SPACING    = 13
  STYLE_VAR_FRAME_PADDING   = 12

  def self.create_context
    LibImGui.imgui_context_create
  end

  def self.destroy_context
    LibImGui.imgui_context_destroy
  end

  def self.style_dark
    LibImGui.imgui_style_dark
  end

  def self.new_frame
    LibImGui.imgui_new_frame
  end

  def self.render
    LibImGui.imgui_render
  end

  def self.get_draw_data : Void*
    LibImGui.imgui_get_draw_data
  end

  def self.begin(name : String, flags : Int32 = 0) : Bool
    LibImGui.imgui_begin(name, flags) != 0
  end

  def self.end
    LibImGui.imgui_end
  end

  def self.text(str : String)
    LibImGui.imgui_text(str)
  end

  def self.text_colored(r : Float32, g : Float32, b : Float32, a : Float32, str : String)
    LibImGui.imgui_text_colored(r, g, b, a, str)
  end

  def self.text_wrapped(str : String)
    LibImGui.imgui_text_wrapped(str)
  end

  def self.separator
    LibImGui.imgui_separator
  end

  def self.spacing
    LibImGui.imgui_spacing
  end

  def self.dummy(w : Float32, h : Float32)
    LibImGui.imgui_dummy(w, h)
  end

  def self.button(label : String, w : Float32 = 0.0f32, h : Float32 = 0.0f32) : Bool
    LibImGui.imgui_button(label, w, h) != 0
  end

  def self.input_text(label : String, buf : Bytes) : Bool
    LibImGui.imgui_input_text(label, buf.to_unsafe, buf.size) != 0
  end

  def self.input_text_multiline(label : String, buf : Bytes, w : Float32 = -1.0f32, h : Float32 = 80.0f32) : Bool
    LibImGui.imgui_input_text_multiline(label, buf.to_unsafe, buf.size, w, h) != 0
  end

  def self.checkbox(label : String, checked : Bool) : {Bool, Bool}
    v = checked ? 1 : 0
    changed = LibImGui.imgui_checkbox(label, pointerof(v)) != 0
    {changed, v != 0}
  end

  def self.slider_float(label : String, value : Float32, min : Float32, max : Float32) : {Bool, Float32}
    v = value
    changed = LibImGui.imgui_slider_float(label, pointerof(v), min, max) != 0
    {changed, v}
  end

  def self.progress_bar(fraction : Float32, w : Float32 = -1.0f32, h : Float32 = 0.0f32, overlay : String = "")
    LibImGui.imgui_progress_bar(fraction, w, h, overlay)
  end

  def self.set_next_window_pos(x : Float32, y : Float32)
    LibImGui.imgui_set_next_window_pos(x, y)
  end

  def self.set_next_window_size(w : Float32, h : Float32)
    LibImGui.imgui_set_next_window_size(w, h)
  end

  def self.push_font_scale(scale : Float32)
    LibImGui.imgui_push_font_scale(scale)
  end

  def self.pop_font_scale
    LibImGui.imgui_pop_font_scale
  end

  def self.push_style_color(idx : Int32, r : Float32, g : Float32, b : Float32, a : Float32 = 1.0f32)
    LibImGui.imgui_push_style_color(idx, r, g, b, a)
  end

  def self.pop_style_color(count : Int32 = 1)
    LibImGui.imgui_pop_style_color(count)
  end

  def self.push_style_var(idx : Int32, val : Float32)
    LibImGui.imgui_push_style_var_float(idx, val)
  end

  def self.pop_style_var(count : Int32 = 1)
    LibImGui.imgui_pop_style_var(count)
  end

  def self.begin_child(id : String, w : Float32 = 0.0f32, h : Float32 = 0.0f32, border : Bool = false, flags : Int32 = 0) : Bool
    LibImGui.imgui_begin_child(id, w, h, border ? 1 : 0, flags) != 0
  end

  def self.end_child
    LibImGui.imgui_end_child
  end

  def self.same_line(offset : Float32 = 0.0f32, spacing : Float32 = -1.0f32)
    LibImGui.imgui_same_line(offset, spacing)
  end

  def self.get_display_size : {Float32, Float32}
    w = 0.0f32
    h = 0.0f32
    LibImGui.imgui_get_display_size(pointerof(w), pointerof(h))
    {w, h}
  end

  def self.font_size : Float32
    LibImGui.imgui_get_font_size
  end

  def self.backend_init(window : Void*, gl_ctx : Void*) : Bool
    LibImGui.imgui_backend_init(window, gl_ctx) != 0
  end

  def self.backend_shutdown
    LibImGui.imgui_backend_shutdown
  end

  def self.backend_new_frame(window : Void*)
    LibImGui.imgui_backend_new_frame(window)
  end

  def self.backend_render(draw_data : Void*)
    LibImGui.imgui_backend_render(draw_data)
  end

  def self.backend_process_event(event : Void*) : Bool
    LibImGui.imgui_backend_process_event(event) != 0
  end
end
