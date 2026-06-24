// src/native/engine/android/native.c

#include <android/native_activity.h>
#include <android/log.h>
#include <pthread.h>
#include <stdlib.h>

#define LOGI(...) ((void)__android_log_print(ANDROID_LOG_INFO, "native.cr", __VA_ARGS__))
#define LOGE(...) ((void)__android_log_print(ANDROID_LOG_ERROR, "native.cr", __VA_ARGS__))

static ANativeActivity* g_activity = NULL;
static JNIEnv* g_env = NULL;
static jobject g_activity_obj = NULL;
static jclass g_activity_class = NULL;
static JavaVM* g_vm = NULL;

jobject get_activity() {
    return g_activity_obj;
}

JNIEnv* get_jni_env() {
    return g_env;
}

jclass get_activity_class() {
    return g_activity_class;
}

// Forward declaration
extern void crystal_android_main(JNIEnv* env, jobject activity, jclass activity_class);

// Background thread that runs Crystal code
static void* crystal_thread(void* arg) {
    ANativeActivity* activity = (ANativeActivity*)arg;

    // Attach thread to JVM
    if ((*g_vm)->AttachCurrentThread(g_vm, &g_env, NULL) != JNI_OK) {
        LOGE("Failed to attach thread to JVM");
        return NULL;
    }

    // Get activity object and class
    g_activity_obj = activity->clazz;
    g_activity_class = (*g_env)->GetObjectClass(g_env, g_activity_obj);

    if (g_activity_class == NULL) {
        LOGE("Failed to get activity class");
        (*g_vm)->DetachCurrentThread(g_vm);
        return NULL;
    }

    LOGI("Android engine ready, calling Crystal main");

    // Call into Crystal
    crystal_android_main(g_env, g_activity_obj, g_activity_class);

    LOGI("Crystal main returned");

    // Detach thread
    (*g_vm)->DetachCurrentThread(g_vm);
    g_env = NULL;

    return NULL;
}

// Lifecycle callbacks
static void on_destroy(ANativeActivity* activity) {
    LOGI("Activity destroyed");
    // TODO: Signal Crystal to shutdown gracefully
}

static void on_pause(ANativeActivity* activity) {
    LOGI("Activity paused");
    // TODO: Signal Crystal to pause
}

static void on_resume(ANativeActivity* activity) {
    LOGI("Activity resumed");
    // TODO: Signal Crystal to resume
}

// Main entry point - called by NativeActivity
void ANativeActivity_onCreate(ANativeActivity* activity, void* savedState, size_t savedStateSize) {
    LOGI("ANativeActivity_onCreate called");

    g_activity = activity;

    // Get JavaVM from activity
    JNIEnv* env = activity->env;
    (*env)->GetJavaVM(env, &g_vm);

    // Set up lifecycle callbacks
    activity->callbacks->onDestroy = on_destroy;
    activity->callbacks->onPause = on_pause;
    activity->callbacks->onResume = on_resume;

    // Start Crystal on background thread (don't block main thread)
    pthread_t thread;
    if (pthread_create(&thread, NULL, crystal_thread, activity) != 0) {
        LOGE("Failed to create Crystal thread");
        return;
    }

    // Detach thread so it cleans up automatically
    pthread_detach(thread);

    LOGI("Crystal thread started");
}
