#include "imgui.h"
#include "imgui_impl_sdl2.h"
#include "imgui_impl_opengl3.h"
#include "backend.h"
#include <SDL.h>
#include <SDL_opengl.h>
#include <cstring>
#include <cstdio>

static float s_font_scale = 1.0f;

extern "C" {

int imgui_backend_init(SDL_Window_ptr window, SDL_GLContext_ptr gl_context) {
    return ImGui_ImplSDL2_InitForOpenGL(
        (SDL_Window*)window,
        gl_context
    ) && ImGui_ImplOpenGL3_Init("#version 130");
}

void imgui_backend_shutdown(void) {
    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplSDL2_Shutdown();
}

void imgui_backend_new_frame(SDL_Window_ptr window) {
    ImGui_ImplOpenGL3_NewFrame();
    ImGui_ImplSDL2_NewFrame();
}

void imgui_backend_render(ImDrawData_ptr draw_data) {
    ImGui_ImplOpenGL3_RenderDrawData((ImDrawData*)draw_data);
}

int imgui_backend_process_event(SDL_Event_ptr event) {
    return ImGui_ImplSDL2_ProcessEvent((SDL_Event*)event) ? 1 : 0;
}

void imgui_context_create(void) {
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO();
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;
}

void imgui_context_destroy(void) {
    ImGui::DestroyContext();
}

void imgui_style_dark(void) {
    ImGui::StyleColorsDark();
    ImGuiStyle& style = ImGui::GetStyle();
    style.WindowRounding    = 6.0f;
    style.FrameRounding     = 4.0f;
    style.ItemSpacing       = ImVec2(8, 6);
    style.WindowPadding     = ImVec2(14, 14);
    style.FramePadding      = ImVec2(8, 4);
    style.ScrollbarRounding = 4.0f;
    style.GrabRounding      = 4.0f;

    ImVec4* colors = style.Colors;
    colors[ImGuiCol_WindowBg]       = ImVec4(0.10f, 0.10f, 0.12f, 1.00f);
    colors[ImGuiCol_Header]         = ImVec4(0.20f, 0.20f, 0.55f, 0.55f);
    colors[ImGuiCol_HeaderHovered]  = ImVec4(0.26f, 0.26f, 0.70f, 0.80f);
    colors[ImGuiCol_Button]         = ImVec4(0.20f, 0.35f, 0.75f, 0.75f);
    colors[ImGuiCol_ButtonHovered]  = ImVec4(0.28f, 0.45f, 0.90f, 0.90f);
    colors[ImGuiCol_ButtonActive]   = ImVec4(0.20f, 0.30f, 0.65f, 1.00f);
    colors[ImGuiCol_FrameBg]        = ImVec4(0.16f, 0.16f, 0.20f, 1.00f);
    colors[ImGuiCol_FrameBgHovered] = ImVec4(0.22f, 0.22f, 0.30f, 1.00f);
    colors[ImGuiCol_SliderGrab]     = ImVec4(0.28f, 0.45f, 0.90f, 1.00f);
    colors[ImGuiCol_CheckMark]      = ImVec4(0.28f, 0.56f, 1.00f, 1.00f);
}

void imgui_new_frame(void) {
    ImGui::NewFrame();
}

void imgui_render(void) {
    ImGui::Render();
}

void* imgui_get_draw_data(void) {
    return (void*)ImGui::GetDrawData();
}

int imgui_begin(const char* name, int flags) {
    return ImGui::Begin(name, nullptr, (ImGuiWindowFlags)flags) ? 1 : 0;
}

void imgui_end(void) {
    ImGui::End();
}

void imgui_text(const char* text) {
    ImGui::TextUnformatted(text);
}

void imgui_text_colored(float r, float g, float b, float a, const char* text) {
    ImGui::TextColored(ImVec4(r, g, b, a), "%s", text);
}

void imgui_text_wrapped(const char* text) {
    ImGui::TextWrapped("%s", text);
}

void imgui_separator(void) {
    ImGui::Separator();
}

void imgui_spacing(void) {
    ImGui::Spacing();
}

void imgui_dummy(float w, float h) {
    ImGui::Dummy(ImVec2(w, h));
}

int imgui_button(const char* label, float w, float h) {
    return ImGui::Button(label, ImVec2(w, h)) ? 1 : 0;
}

int imgui_input_text(const char* label, char* buf, int buf_size) {
    return ImGui::InputText(label, buf, (size_t)buf_size) ? 1 : 0;
}

int imgui_input_text_multiline(const char* label, char* buf, int buf_size, float w, float h) {
    return ImGui::InputTextMultiline(label, buf, (size_t)buf_size, ImVec2(w, h)) ? 1 : 0;
}

int imgui_checkbox(const char* label, int* v) {
    bool b = (*v != 0);
    bool changed = ImGui::Checkbox(label, &b);
    *v = b ? 1 : 0;
    return changed ? 1 : 0;
}

int imgui_slider_float(const char* label, float* v, float min, float max) {
    return ImGui::SliderFloat(label, v, min, max) ? 1 : 0;
}

void imgui_progress_bar(float fraction, float w, float h, const char* overlay) {
    ImGui::ProgressBar(fraction, ImVec2(w, h), overlay && overlay[0] ? overlay : nullptr);
}

void imgui_set_next_window_pos(float x, float y) {
    ImGui::SetNextWindowPos(ImVec2(x, y), ImGuiCond_Always);
}

void imgui_set_next_window_size(float w, float h) {
    ImGui::SetNextWindowSize(ImVec2(w, h), ImGuiCond_Always);
}

void imgui_push_font_scale(float scale) {
    s_font_scale = scale;
    ImGui::SetWindowFontScale(scale);
}

void imgui_pop_font_scale(void) {
    ImGui::SetWindowFontScale(1.0f);
    s_font_scale = 1.0f;
}

void imgui_push_style_color(int idx, float r, float g, float b, float a) {
    ImGui::PushStyleColor((ImGuiCol)idx, ImVec4(r, g, b, a));
}

void imgui_pop_style_color(int count) {
    ImGui::PopStyleColor(count);
}

void imgui_push_style_var_float(int idx, float val) {
    ImGui::PushStyleVar((ImGuiStyleVar)idx, val);
}

void imgui_pop_style_var(int count) {
    ImGui::PopStyleVar(count);
}

int imgui_begin_child(const char* id, float w, float h, int border, int flags) {
    return ImGui::BeginChild(id, ImVec2(w, h), border != 0, (ImGuiWindowFlags)flags) ? 1 : 0;
}

void imgui_end_child(void) {
    ImGui::EndChild();
}

void imgui_same_line(float offset_from_start_x, float spacing) {
    ImGui::SameLine(offset_from_start_x, spacing);
}

void imgui_get_display_size(float* w, float* h) {
    ImGuiIO& io = ImGui::GetIO();
    *w = io.DisplaySize.x;
    *h = io.DisplaySize.y;
}

float imgui_get_font_size(void) {
    return ImGui::GetFontSize();
}

} // extern "C"
