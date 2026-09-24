// src/native/engine/android/java/com/nativecr/PushManager.java
//
// Manages FCM token retrieval and storage.
// Call PushManager.getToken(activity, callback) from Crystal via JNI.

package com.nativecr;

import android.app.Activity;
import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

public class PushManager {
    private static final String TAG      = "NativeCR.Push";
    private static final String PREFS    = "native_cr_push";
    private static final String KEY_TOKEN = "fcm_token";

    // All native callbacks are posted to the main thread: the JNI
    // environment cached by the Crystal runtime is only valid on the
    // thread that obtained it, and every other framework callback
    // (UI, lifecycle) already arrives there.
    private static final Handler MAIN = new Handler(Looper.getMainLooper());

    private static void fireTokenReady(final String token) {
        MAIN.post(new Runnable() {
            @Override
            public void run() {
                try {
                    nativeOnTokenReady(token != null ? token : "");
                } catch (UnsatisfiedLinkError e) {
                    Log.w(TAG, "Native lib not ready: " + e.getMessage());
                } catch (Exception e) {
                    Log.e(TAG, "Error in token callback: " + e.getMessage());
                }
            }
        });
    }

    // Called from Crystal: retrieve the current FCM token asynchronously.
    // Fires nativeOnTokenReady(token) when done.
    public static void getToken(final Activity activity) {
        try {
            Class<?> fmClass = Class.forName(
                "com.google.firebase.messaging.FirebaseMessaging");
            Object fm = fmClass.getMethod("getInstance").invoke(null);

            // FirebaseMessaging.getInstance().getToken() returns a Task<String>
            Object task = fmClass.getMethod("getToken").invoke(fm);

            // Attach success listener via reflection to avoid hard Firebase dep.
            Class<?> listenerClass = Class.forName(
                "com.google.android.gms.tasks.OnSuccessListener");

            Object listener = java.lang.reflect.Proxy.newProxyInstance(
                listenerClass.getClassLoader(),
                new Class[]{listenerClass},
                (proxy, method, args) -> {
                    if ("onSuccess".equals(method.getName()) && args != null && args.length > 0) {
                        String token = args[0] != null ? (String) args[0] : "";
                        storeToken(token);
                        fireTokenReady(token);
                    }
                    return null;
                });

            taskClass.getMethod("addOnSuccessListener",
                Class.forName("com.google.android.gms.tasks.OnSuccessListener"))
                .invoke(task, listener);

        } catch (ClassNotFoundException e) {
            // Firebase not on classpath — return empty token.
            Log.w(TAG, "Firebase not available: " + e.getMessage());
            fireTokenReady("");
        } catch (Exception e) {
            Log.e(TAG, "getToken failed: " + e.getMessage());
            fireTokenReady("");
        }
    }

    // Called from FcmService.onNewToken and getToken success listener.
    public static void storeToken(String token) {
        // We need a context; piggyback on NotificationHelper's stored context.
        try {
            java.lang.reflect.Field f = NotificationHelper.class.getDeclaredField("appContext");
            f.setAccessible(true);
            Context ctx = (Context) f.get(null);
            if (ctx != null) {
                ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                   .edit().putString(KEY_TOKEN, token).apply();
            }
        } catch (Exception e) {
            Log.w(TAG, "Could not persist token: " + e.getMessage());
        }
    }

    // Crystal callback — implemented in push_notifications.cr bridge.
    private static native void nativeOnTokenReady(String token);
}
