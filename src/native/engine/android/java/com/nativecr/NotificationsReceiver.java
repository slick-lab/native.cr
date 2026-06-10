// src/native/engine/android/java/com/nativecr/NotificationReceiver.java

package com.nativecr;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

public class NotificationReceiver extends BroadcastReceiver {
    public static final String ACTION_NOTIFICATION_TAPPED = "com.nativecr.NOTIFICATION_TAPPED";

    @Override
    public void onReceive(Context context, Intent intent) {
        if (intent.getAction() != null && intent.getAction().equals(ACTION_NOTIFICATION_TAPPED)) {
            String payload = intent.getStringExtra("payload");
            int notificationId = intent.getIntExtra("notification_id", 0);
            nativeOnNotificationTapped(payload, notificationId);
        }
    }

    private static native void nativeOnNotificationTapped(String payload, int notificationId);
}
