// src/native/engine/android/native.c

#include <jni.h>
#include <android_native_app_glue.h>
#include <android/log.h>
#include <stdlib.h>
#include <string.h>

#define LOGI(...) ((void)__android_log_print(ANDROID_LOG_INFO, "native.cr", __VA_ARGS__))
#define LOGE(...) ((void)__android_log_print(ANDROID_LOG_ERROR, "native.cr", __VA_ARGS__))

static struct android_app* g_app = NULL;
static JNIEnv* g_env = NULL;
static jobject g_activity = NULL;
static jclass g_activity_class = NULL;
static JavaVM* g_vm = NULL;

void android_main(struct android_app* state) {
  g_app = state;
  g_vm = state->activity->vm;
  
  if ((*g_vm)->AttachCurrentThread(g_vm, &g_env, NULL) != JNI_OK) {
    LOGE("Failed to attach thread to JVM");
    return;
  }
  
  g_activity = state->activity->clazz;
  g_activity_class = (*g_env)->GetObjectClass(g_env, g_activity);
  
  if (g_activity_class == NULL) {
    LOGE("Failed to get activity class");
    return;
  }
  
  LOGI("Android engine ready, JNI attached");
  
  extern void crystal_android_main(JNIEnv* env, jobject activity, jclass activity_class);
  crystal_android_main(g_env, g_activity, g_activity_class);
  
  while (1) {
    int ident;
    int events;
    struct android_poll_source* source;
    
    while ((ident = ALooper_pollAll(0, NULL, &events, (void**)&source)) >= 0) {
      if (source != NULL) {
        source->process(state, source);
      }
      
      if (state->destroyRequested != 0) {
        (*g_vm)->DetachCurrentThread(g_vm);
        LOGI("Android engine shutting down");
        return;
      }
    }
  }
}
