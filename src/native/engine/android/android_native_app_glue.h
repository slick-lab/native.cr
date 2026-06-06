/*
 * Copyright (C) 2010 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

#ifndef _ANDROID_NATIVE_APP_GLUE_H
#define _ANDROID_NATIVE_APP_GLUE_H

#include <android/configuration.h>
#include <android/looper.h>
#include <android/native_activity.h>

#ifdef __cplusplus
extern "C" {
#endif

struct android_app;

typedef void (*android_app_cmd_cb)(struct android_app* app, int32_t cmd);
typedef int32_t (*android_app_input_cb)(struct android_app* app, AInputEvent* event);

struct android_poll_source {
    int32_t id;
    struct android_app* app;
    void (*process)(struct android_app* app, struct android_poll_source* source);
};

struct android_app {
    ANativeActivity* activity;
    AConfiguration* config;
    void* savedState;
    size_t savedStateSize;
    AInputQueue* inputQueue;
    ALooper* looper;
    ANativeWindow* window;
    struct android_poll_source cmdPollSource;
    struct android_poll_source inputPollSource;
    int32_t running;
    int32_t stateSaved;
    int32_t destroyRequested;
    int32_t windowFocused;
    int32_t contentRectChanged;
    ARect contentRect;
    pthread_mutex_t mutex;
    pthread_cond_t cond;
    int msgread;
    int msgwrite;
    pthread_t thread;
    void* userData;
    android_app_cmd_cb onAppCmd;
    android_app_input_cb onInputEvent;
};

void android_app_set_input(struct android_app* app, AInputQueue* inputQueue);
void android_app_set_window(struct android_app* app, ANativeWindow* window);
void android_app_set_activity_state(struct android_app* app, int32_t cmd);
int8_t android_app_read_cmd(struct android_app* app);
void android_app_write_cmd(struct android_app* app, int8_t cmd);
void android_app_pre_exec_cmd(struct android_app* app, int32_t cmd);
void android_app_post_exec_cmd(struct android_app* app, int32_t cmd);

#ifdef __cplusplus
}
#endif

#endif /* _ANDROID_NATIVE_APP_GLUE_H */
