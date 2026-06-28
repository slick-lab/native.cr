#pragma once

#ifdef __cplusplus
extern "C" {
#endif

typedef void* SDL_Window_ptr;
typedef void* SDL_GLContext_ptr;
typedef void* ImDrawData_ptr;
typedef void* SDL_Event_ptr;

int  imgui_backend_init(SDL_Window_ptr window, SDL_GLContext_ptr gl_context);
void imgui_backend_shutdown(void);
void imgui_backend_new_frame(SDL_Window_ptr window);
void imgui_backend_render(ImDrawData_ptr draw_data);
int  imgui_backend_process_event(SDL_Event_ptr event);

void imgui_context_create(void);
void imgui_context_destroy(void);
void imgui_style_dark(void);
void imgui_new_frame(void);
void imgui_render(void);
void* imgui_get_draw_data(void);

int   imgui_begin(const char* name, int flags);
void  imgui_end(void);
void  imgui_text(const char* text);
void  imgui_text_colored(float r, float g, float b, float a, const char* text);
void  imgui_text_wrapped(const char* text);
void  imgui_separator(void);
void  imgui_spacing(void);
void  imgui_dummy(float w, float h);
int   imgui_button(const char* label, float w, float h);
int   imgui_input_text(const char* label, char* buf, int buf_size);
int   imgui_input_text_multiline(const char* label, char* buf, int buf_size, float w, float h);
int   imgui_checkbox(const char* label, int* v);
int   imgui_slider_float(const char* label, float* v, float min, float max);
void  imgui_progress_bar(float fraction, float w, float h, const char* overlay);
void  imgui_set_next_window_pos(float x, float y);
void  imgui_set_next_window_size(float w, float h);
void  imgui_push_font_scale(float scale);
void  imgui_pop_font_scale(void);
void  imgui_push_style_color(int idx, float r, float g, float b, float a);
void  imgui_pop_style_color(int count);
void  imgui_push_style_var_float(int idx, float val);
void  imgui_pop_style_var(int count);
int   imgui_begin_child(const char* id, float w, float h, int border, int flags);
void  imgui_end_child(void);
void  imgui_same_line(float offset_from_start_x, float spacing);
void  imgui_get_display_size(float* w, float* h);
float imgui_get_font_size(void);

#ifdef __cplusplus
}
#endif
