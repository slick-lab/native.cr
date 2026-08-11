// src/native/engine/android/java/com/nativecr/NotificationReceiver.java

package com.nativecr;

import android.app.NotificationManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;
import androidx.core.app.NotificationCompat;

public class NotificationReceiver extends BroadcastReceiver {
    public static final String ACTION_NOTIFICATION_TAPPED =
        "com.nativecr.NOTIFICATION_TAPPED";
    public static final String ACTION_SCHEDULE_NOTIFY =
        "com.nativecr.SCHEDULE_NOTIFY";

    private static final String TAG = "NativeCR";

    @Override
    public void onReceive(Context context, Intent intent) {
        if (intent == null || intent.getAction() == null) return;

        String action = intent.getAction();

        if (ACTION_NOTIFICATION_TAPPED.equals(action)) {
            String payload = intent.getStringExtra("payload");
            int notificationId = intent.getIntExtra("notification_id", 0);
            fireTapCallback(payload != null ? payload : "{}", notificationId);

        } else if (ACTION_SCHEDULE_NOTIFY.equals(action)) {
            // Alarm fired — build and display the notification now.
            String channelId = intent.getStringExtra("channel_id");
            String title = intent.getStringExtra("title");
            String body = intent.getStringExtra("body");
            String payload = intent.getStringExtra("payload");
            int id = intent.getIntExtra("notification_id", 0);

            NotificationHelper.showNotification(
                id,
                channelId != null ? channelId : "default",
                title != null ? title : "",
                body != null ? body : "",
                null,   // subtitle
                null,   // largeIcon
                null,   // smallIcon
                0,      // badgeNumber
                NotificationCompat.PRIORITY_DEFAULT,
                true,   // autoCancel
                null,   // sound
                true,   // vibration
                0,      // color
                payload != null ? payload : "{}",
                false,  // hasActions
                ""      // actionIds
            );
        }
    }

    // ── Crystal callback bridge ────────────────────────────────────────────
    // Called when the user taps a notification. Delegates to Crystal via JNI.
    // The native symbol is registered by the Crystal side (bridge.cr).
    // If the native library is not yet loaded we log and skip rather than crash.

    private static void fireTapCallback(String payload, int id) {
        try {
            nativeOnNotificationTapped(payload, id);
        } catch (UnsatisfiedLinkError e) {
            Log.w(TAG, "Notification tapped but native lib not loaded: " + e.getMessage());
        } catch (Exception e) {
            Log.e(TAG, "Error in notification tap callback: " + e.getMessage());
        }
    }

    // Implemented on the Crystal side — see push_notifications.cr bridge.
    private static native void nativeOnNotificationTapped(String payload, int id);
}
