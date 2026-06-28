require "./nodes"
require "./imgui/lib_sdl"
require "./imgui/lib_gl"
require "./imgui/lib_imgui"

module Native::Interpreter
  class Renderer
    WINDOW_W = 480
    WINDOW_H = 720

    @window : Void* = Pointer(Void).null
    @gl_ctx : Void* = Pointer(Void).null
    @running : Bool = false
    @app : AppNode = AppNode.new
    @app_mutex : Mutex = Mutex.new
    @input_buffers : Hash(String, Bytes) = {} of String => Bytes
    @checkbox_states : Hash(String, Bool) = {} of String => Bool
    @slider_states : Hash(String, Float32) = {} of String => Float32
    @status_msg : String = ""
    @status_timer : Float64 = 0.0

    def update_app(app : AppNode)
      @app_mutex.synchronize { @app = app }
    end

    def stop
      @running = false
    end

    def run
      init_sdl_and_imgui
      main_loop
    ensure
      shutdown
    end

    private def init_sdl_and_imgui
      if SDL.init_video != 0
        raise "SDL_Init failed: #{SDL.get_error}"
      end

      SDL.setup_gl_attributes

      @window = SDL.create_window("native.cr — Desktop Preview", WINDOW_W, WINDOW_H)
      if @window.null?
        raise "SDL_CreateWindow failed: #{SDL.get_error}"
      end

      @gl_ctx = SDL.gl_create_context(@window)
      if @gl_ctx.null?
        raise "SDL_GL_CreateContext failed: #{SDL.get_error}"
      end

      SDL.gl_set_swap_interval(1)

      ImGui.create_context
      ImGui.style_dark

      unless ImGui.backend_init(@window, @gl_ctx)
        raise "ImGui backend init failed"
      end

      @running = true
      puts "[native.cr] Desktop window open"
    end

    private def main_loop
      while @running
        process_events
        render_frame
        SDL.gl_swap_window(@window)
      end
    end

    private def process_events
      while event = SDL.poll_event
        raw = pointerof(event).as(Void*)
        ImGui.backend_process_event(raw)

        case event.type
        when LibSDL::SDL_QUIT
          @running = false
        when LibSDL::SDL_KEYDOWN
          @running = false if event.key.keysym.sym == LibSDL::SDLK_ESCAPE
        end
      end
    end

    private def render_frame
      win_w, win_h = SDL.get_window_size(@window)
      GL.viewport(0, 0, win_w, win_h)
      GL.clear_color(0.08f32, 0.08f32, 0.10f32, 1.0f32)
      GL.clear

      ImGui.backend_new_frame(@window)
      ImGui.new_frame

      app = @app_mutex.synchronize { @app }
      render_app(app, win_w.to_f32, win_h.to_f32)

      ImGui.render
      ImGui.backend_render(ImGui.get_draw_data)
    end

    private def render_app(app : AppNode, win_w : Float32, win_h : Float32)
      if err = app.error_message
        render_error_window(err, win_w, win_h)
        return
      end

      render_toolbar(app, win_w)

      toolbar_h = 36.0f32
      ImGui.set_next_window_pos(0.0f32, toolbar_h)
      ImGui.set_next_window_size(win_w, win_h - toolbar_h)

      flags = ImGui::WINDOW_NO_TITLE_BAR |
              ImGui::WINDOW_NO_RESIZE |
              ImGui::WINDOW_NO_MOVE |
              ImGui::WINDOW_NO_SAVED_SETTINGS

      if ImGui.begin("##main_content", flags)
        if root = app.root
          render_node(root)
        else
          ImGui.text("No UI defined in setup()")
        end

        render_status_bar
      end
      ImGui.end
    end

    private def render_toolbar(app : AppNode, win_w : Float32)
      ImGui.set_next_window_pos(0.0f32, 0.0f32)
      ImGui.set_next_window_size(win_w, 36.0f32)

      flags = ImGui::WINDOW_NO_TITLE_BAR |
              ImGui::WINDOW_NO_RESIZE |
              ImGui::WINDOW_NO_MOVE |
              ImGui::WINDOW_NO_SAVED_SETTINGS |
              ImGui::WINDOW_NO_SCROLLBAR

      ImGui.push_style_color(ImGui::COL_WINDOW_BG, 0.12f32, 0.12f32, 0.16f32)

      if ImGui.begin("##toolbar", flags)
        ImGui.push_font_scale(0.85f32)
        ImGui.text_colored(0.45f32, 0.75f32, 1.0f32, 1.0f32, "native.cr")
        ImGui.same_line
        ImGui.text_colored(0.55f32, 0.55f32, 0.60f32, 1.0f32, "—")
        ImGui.same_line
        ImGui.text(app.title)
        ImGui.same_line(0.0f32, 12.0f32)
        ImGui.text_colored(0.35f32, 0.80f32, 0.40f32, 1.0f32, "● Live")
        ImGui.pop_font_scale
      end
      ImGui.end
      ImGui.pop_style_color
    end

    private def render_error_window(err : String, win_w : Float32, win_h : Float32)
      ImGui.set_next_window_pos(0.0f32, 0.0f32)
      ImGui.set_next_window_size(win_w, win_h)

      flags = ImGui::WINDOW_NO_TITLE_BAR |
              ImGui::WINDOW_NO_RESIZE |
              ImGui::WINDOW_NO_MOVE |
              ImGui::WINDOW_NO_SAVED_SETTINGS

      ImGui.push_style_color(ImGui::COL_WINDOW_BG, 0.10f32, 0.05f32, 0.05f32)

      if ImGui.begin("##error", flags)
        ImGui.push_font_scale(1.1f32)
        ImGui.text_colored(1.0f32, 0.35f32, 0.35f32, 1.0f32, "⚠ Parse Error")
        ImGui.pop_font_scale
        ImGui.separator
        ImGui.spacing
        ImGui.text_wrapped(err)
        ImGui.spacing
        ImGui.separator
        ImGui.text_colored(0.55f32, 0.55f32, 0.60f32, 1.0f32, "Fix the error in your source file — preview will update automatically.")
      end
      ImGui.end
      ImGui.pop_style_color
    end

    private def render_node(node : UINode)
      return unless node.visible

      case node
      when LinearLayoutNode
        render_layout(node)
      when CardViewNode
        render_card(node)
      when ScrollViewNode
        render_scroll(node)
      when TextViewNode
        render_text_view(node)
      when ButtonNode
        render_button(node)
      when EditTextNode
        render_edit_text(node)
      when CheckboxNode
        render_checkbox(node)
      when SliderNode
        render_slider(node)
      when ProgressBarNode
        render_progress_bar(node)
      when SeparatorNode
        ImGui.separator
      when SpacerNode
        ImGui.dummy(0.0f32, node.height.to_f32)
      when ImageViewNode
        render_image_placeholder(node)
      end
    end

    private def render_layout(node : LinearLayoutNode)
      if node.orientation == Orientation::Horizontal
        node.children.each_with_index do |child, i|
          render_node(child)
          ImGui.same_line if i < node.children.size - 1
        end
      else
        node.children.each { |child| render_node(child) }
      end
    end

    private def render_card(node : CardViewNode)
      ImGui.push_style_color(ImGui::COL_WINDOW_BG, 0.14f32, 0.14f32, 0.18f32)
      ImGui.push_style_var(ImGui::STYLE_VAR_WINDOW_ROUNDING, 6.0f32)

      child_h = estimate_children_height(node.children)
      if ImGui.begin_child("##card_#{node.id}", -1.0f32, child_h + 16.0f32, true)
        node.children.each { |child| render_node(child) }
      end
      ImGui.end_child

      ImGui.pop_style_color
      ImGui.pop_style_var
      ImGui.spacing
    end

    private def render_scroll(node : ScrollViewNode)
      child_h = 200.0f32
      if ImGui.begin_child("##scroll_#{node.id}", -1.0f32, child_h, false, ImGui::WINDOW_HORIZONTAL_SCROLLBAR)
        node.children.each { |child| render_node(child) }
      end
      ImGui.end_child
    end

    private def render_text_view(node : TextViewNode)
      if node.text.empty?
        ImGui.spacing
        return
      end

      scale = node.text_size > 14 ? (node.text_size / 14.0f32) : 1.0f32
      scale = scale.clamp(0.7f32, 2.5f32)

      if scale != 1.0f32
        ImGui.push_font_scale(scale)
      end

      r, g, b = node.color
      if r != 1.0f32 || g != 1.0f32 || b != 1.0f32
        ImGui.text_colored(r, g, b, 1.0f32, node.text)
      else
        ImGui.text_wrapped(node.text)
      end

      if scale != 1.0f32
        ImGui.pop_font_scale
      end

      ImGui.spacing
    end

    private def render_button(node : ButtonNode)
      ImGui.push_style_color(ImGui::COL_BUTTON, 0.20f32, 0.35f32, 0.75f32)
      ImGui.push_style_color(ImGui::COL_BUTTON_HOVERED, 0.30f32, 0.50f32, 0.95f32)
      ImGui.push_style_color(ImGui::COL_BUTTON_ACTIVE, 0.15f32, 0.28f32, 0.60f32)

      if ImGui.button(node.label, -1.0f32, 32.0f32)
        @status_msg = "#{node.label} clicked"
        @status_timer = Time.monotonic.total_seconds
      end

      ImGui.pop_style_color(3)
      ImGui.spacing
    end

    private def render_edit_text(node : EditTextNode)
      buf = @input_buffers[node.id] ||= Bytes.new(256, 0_u8)

      ImGui.push_style_color(ImGui::COL_FRAME_BG, 0.16f32, 0.16f32, 0.22f32)
      ImGui.push_style_color(ImGui::COL_FRAME_BG_HOVERED, 0.20f32, 0.20f32, 0.30f32)

      if node.multiline
        ImGui.input_text_multiline("##et_#{node.id}", buf, -1.0f32, 80.0f32)
      else
        ImGui.input_text("#{node.placeholder}##et_#{node.id}", buf)
      end

      ImGui.pop_style_color(2)
      ImGui.spacing
    end

    private def render_checkbox(node : CheckboxNode)
      state = @checkbox_states.fetch(node.id, node.checked)
      _, new_state = ImGui.checkbox(node.label, state)
      @checkbox_states[node.id] = new_state
      ImGui.spacing
    end

    private def render_slider(node : SliderNode)
      value = @slider_states.fetch(node.id, node.value)
      _, new_val = ImGui.slider_float(node.label, value, node.min, node.max)
      @slider_states[node.id] = new_val
      ImGui.spacing
    end

    private def render_progress_bar(node : ProgressBarNode)
      ImGui.progress_bar(node.value, -1.0f32, 0.0f32, "#{(node.value * 100).to_i}%")
      ImGui.spacing
    end

    private def render_image_placeholder(node : ImageViewNode)
      ImGui.push_style_color(ImGui::COL_FRAME_BG, 0.16f32, 0.16f32, 0.22f32)
      if ImGui.begin_child("##img_#{node.id}", -1.0f32, 80.0f32, true)
        ImGui.text_colored(0.50f32, 0.50f32, 0.55f32, 1.0f32, "[ImageView: #{node.src.empty? ? "no src" : node.src}]")
      end
      ImGui.end_child
      ImGui.pop_style_color
      ImGui.spacing
    end

    private def render_status_bar
      return if @status_msg.empty?

      elapsed = Time.monotonic.total_seconds - @status_timer
      if elapsed > 2.0
        @status_msg = ""
        return
      end

      alpha = elapsed > 1.5 ? ((2.0 - elapsed) / 0.5).to_f32 : 1.0f32
      ImGui.spacing
      ImGui.separator
      ImGui.text_colored(0.40f32, 0.85f32, 0.45f32, alpha, @status_msg)
    end

    private def estimate_children_height(children : Array(UINode)) : Float32
      h = 0.0f32
      children.each do |child|
        h += case child
             when TextViewNode   then 28.0f32
             when ButtonNode     then 44.0f32
             when EditTextNode   then 36.0f32
             when CheckboxNode   then 28.0f32
             when SliderNode     then 36.0f32
             when SeparatorNode  then 12.0f32
             when SpacerNode     then child.height.to_f32
             else                    40.0f32
             end
      end
      h.clamp(40.0f32, 400.0f32)
    end

    private def shutdown
      ImGui.backend_shutdown
      ImGui.destroy_context
      SDL.gl_delete_context(@gl_ctx) unless @gl_ctx.null?
      SDL.destroy_window(@window)   unless @window.null?
      SDL.quit
    end
  end
end
