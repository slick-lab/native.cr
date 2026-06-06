#include <android_native_app_glue.h>
#include <android/log.h>
#include <EGL/egl.h>
#include <GLES2/gl2.h>
#include <stdlib.h>
#include <string.h>

#define LOGI(...) ((void)__android_log_print(ANDROID_LOG_INFO, "native.cr", __VA_ARGS__))
#define LOGE(...) ((void)__android_log_print(ANDROID_LOG_ERROR, "native.cr", __VA_ARGS__))

struct engine {
  struct android_app* app;
  EGLDisplay display;
  EGLSurface surface;
  EGLContext context;
  int32_t width;
  int32_t height;
  int32_t color_r;
  int32_t color_g;
  int32_t color_b;
};

static void engine_init_display(struct engine* engine) {
  const EGLint attribs[] = {
    EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
    EGL_BLUE_SIZE, 8,
    EGL_GREEN_SIZE, 8,
    EGL_RED_SIZE, 8,
    EGL_NONE
  };
  
  EGLint w, h, format;
  EGLint numConfigs;
  EGLConfig config;
  
  engine->display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
  eglInitialize(engine->display, 0, 0);
  eglChooseConfig(engine->display, attribs, &config, 1, &numConfigs);
  eglGetConfigAttrib(engine->display, config, EGL_NATIVE_VISUAL_ID, &format);
  eglCreateWindowSurface(engine->display, config, engine->app->window, NULL);
  eglCreateContext(engine->display, config, NULL, NULL);
  eglMakeCurrent(engine->display, engine->surface, engine->surface, engine->context);
  eglQuerySurface(engine->display, engine->surface, EGL_WIDTH, &w);
  eglQuerySurface(engine->display, engine->surface, EGL_HEIGHT, &h);
  
  engine->width = w;
  engine->height = h;
}

static void engine_draw_frame(struct engine* engine) {
  glClearColor(engine->color_r / 255.0f, engine->color_g / 255.0f, engine->color_b / 255.0f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT);
  eglSwapBuffers(engine->display, engine->surface);
}

static void engine_terminate_display(struct engine* engine) {
  if (engine->display != EGL_NO_DISPLAY) {
    eglMakeCurrent(engine->display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
    if (engine->context != EGL_NO_CONTEXT) eglDestroyContext(engine->display, engine->context);
    if (engine->surface != EGL_NO_SURFACE) eglDestroySurface(engine->display, engine->surface);
    eglTerminate(engine->display);
  }
  engine->display = EGL_NO_DISPLAY;
  engine->context = EGL_NO_CONTEXT;
  engine->surface = EGL_NO_SURFACE;
}

static int32_t engine_handle_input(struct android_app* app, AInputEvent* event) {
  struct engine* engine = (struct engine*)app->userData;
  if (AInputEvent_getType(event) == AINPUT_EVENT_TYPE_MOTION) {
    engine->color_r = (engine->color_r + 10) % 255;
    engine->color_g = (engine->color_g + 20) % 255;
    engine->color_b = (engine->color_b + 30) % 255;
    engine_draw_frame(engine);
    return 1;
  }
  return 0;
}

static void engine_handle_cmd(struct android_app* app, int32_t cmd) {
  struct engine* engine = (struct engine*)app->userData;
  switch (cmd) {
    case APP_CMD_INIT_WINDOW:
      if (app->window != NULL) {
        engine_init_display(engine);
        engine_draw_frame(engine);
      }
      break;
    case APP_CMD_TERM_WINDOW:
      engine_terminate_display(engine);
      break;
  }
}

void android_main(struct android_app* state) {
  struct engine engine;
  
  memset(&engine, 0, sizeof(engine));
  engine.color_r = 100;
  engine.color_g = 150;
  engine.color_b = 200;
  state->userData = &engine;
  state->onAppCmd = engine_handle_cmd;
  state->onInputEvent = engine_handle_input;
  engine.app = state;
  
  while (1) {
    int ident;
    int events;
    struct android_poll_source* source;
    
    while ((ident = ALooper_pollOnce(0, NULL, &events, (void**)&source)) >= 0) {
      if (source != NULL) {
        source->process(state, source);
      }
      if (state->destroyRequested != 0) {
        engine_terminate_display(&engine);
        return;
      }
    }
  }
}
