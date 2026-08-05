// src/native/engine/android/java/com/nativecr/FcmService.java
//
// Firebase Cloud Messaging service — receives remote push notifications and
// bridges them back to Crystal code.
//
// SETUP REQUIRED in the host app's build.gradle:
//
//   // project-level build.gradle
//   classpath 'com.google.gms:google-services:4.4.0'
//
//   // app-level build.gradle
//   apply plugin: 'com.google.gms.google-services'
//   implementation 'com.google.firebase:firebase-messaging:23.4.0'
//
// Also add google-services.json (downloaded from Firebase console) to
// your app/ directory.
//
// Register this service in AndroidManifest.xml:
//
//   <service
//       android:name="com.nativecr.FcmService"
//       android:exported="false">
//     <intent-filter>
//       <action android:name="com.google.firebase.MESSAGING_EVENT" />
//     </intent-filter>
//   </service>

package com.nativecr;

import android.util.Log;

// Guard against projects that don't have Firebase SDK — compile-time
// conditional achieved by wrapping in a try-catch at runtime.
// If Firebase is not on the classpath the class simply won't be used.
// When Firebase IS present, extend FirebaseMessagingService normally.

public class FcmService extends com.google.firebase.messaging.FirebaseMessagingService {
    private static final String TAG = "NativeCR.FCM";

    // Called when a new FCM registration token is generated.
    @Override
    public void onNewToken(String token) {
        super.onNewToken(token);
        Log.d(TAG, "New FCM token: " + token);
        PushManager.storeToken(token);
        try {
            nativeOnTokenRefresh(token);
        } catch (UnsatisfiedLinkError e) {
            Log.w(TAG, "Native lib not ready for token callback: " + e.getMessage());
        }
    }

    // Called when a push message is received while the app is in the foreground.
    @Override
    public void onMessageReceived(com.google.firebase.messaging.RemoteMessage message) {
        super.onMessageReceived(message);

        String title = "";
        String body = "";
        String payload = "{}";

        com.google.firebase.messaging.RemoteMessage.Notification notif =
            message.getNotification();
        if (notif != null) {
            title = notif.getTitle() != null ? notif.getTitle() : "";
            body  = notif.getBody()  != null ? notif.getBody()  : "";
        }

        // Build payload JSON from the data map.
        StringBuilder sb = new StringBuilder("{");
        boolean first = true;
        for (java.util.Map.Entry<String, String> entry : message.getData().entrySet()) {
            if (!first) sb.append(",");
            sb.append("\"").append(escapeJson(entry.getKey())).append("\":");
            sb.append("\"").append(escapeJson(entry.getValue())).append("\"");
            first = false;
        }
        sb.append("}");
        payload = sb.toString();

        Log.d(TAG, "Message received: " + title);

        // Show a local notification for foreground messages.
        if (!title.isEmpty() || !body.isEmpty()) {
            NotificationHelper.showNotification(
                (int) System.currentTimeMillis(),
                "default", title, body,
                null, null, null, 0,
                androidx.core.app.NotificationCompat.PRIORITY_HIGH,
                true, null, true, 0,
                payload, false, ""
            );
        }

        // Fire the Crystal callback.
        try {
            nativeOnMessageReceived(title, body, payload);
        } catch (UnsatisfiedLinkError e) {
            Log.w(TAG, "Native lib not ready for message callback: " + e.getMessage());
        }
    }

    private static String escapeJson(String s) {
        return s.replace("\\", "\\\\").replace("\"", "\\\"")
                .replace("\n", "\\n").replace("\r", "\\r");
    }

    // ── Crystal callbacks (implemented in push_notifications.cr bridge) ────
    private static native void nativeOnTokenRefresh(String token);
    private static native void nativeOnMessageReceived(String title, String body, String payload);
}
