// src/native/engine/android/java/com/nativecr/NotificationHelper.java

package com.nativecr;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.os.Build;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;
import java.util.HashMap;
import java.util.Map;

public class NotificationHelper {
    private static Context appContext;
    private static NotificationManager notificationManager;
    private static Map<String, String> channelMap = new HashMap<>();

    public static void init(Context context) {
        appContext = context.getApplicationContext();
        notificationManager = (NotificationManager) appContext.getSystemService(Context.NOTIFICATION_SERVICE);
    }

    public static void createChannel(String id, String name, String description, int importance, boolean showBadge, boolean vibration, boolean soundEnabled, String soundUri) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(id, name, importance);
            channel.setDescription(description);
            channel.setShowBadge(showBadge);
            channel.enableVibration(vibration);
            channel.enableLights(true);
            channel.setLightColor(Color.BLUE);
            if (soundEnabled && soundUri != null) {
                channel.setSound(android.net.Uri.parse(soundUri), Notification.AUDIO_ATTRIBUTES_DEFAULT);
            }
            notificationManager.createNotificationChannel(channel);
        }
    }

    public static void showNotification(int id, String channelId, String title, String body, String subtitle,
                                        String largeIcon, String smallIcon, int badgeNumber, int priority,
                                        boolean autoCancel, String sound, boolean vibration, int color,
                                        String payload, boolean hasActions, String actionIds) {
        NotificationCompat.Builder builder = new NotificationCompat.Builder(appContext, channelId)
                .setContentTitle(title)
                .setContentText(body)
                .setSubText(subtitle)
                .setPriority(priority)
                .setAutoCancel(autoCancel)
                .setNumber(badgeNumber)
                .setColor(color);

        if (smallIcon != null) {
            int iconRes = appContext.getResources().getIdentifier(smallIcon, "drawable", appContext.getPackageName());
            if (iconRes != 0) {
                builder.setSmallIcon(iconRes);
            }
        }

        if (vibration) {
            builder.setVibrate(new long[]{0, 250, 100, 250});
        }

        if (sound && Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            builder.setDefaults(Notification.DEFAULT_SOUND);
        }

        Intent intent = new Intent(appContext, NotificationReceiver.class);
        intent.putExtra("payload", payload);
        intent.putExtra("notification_id", id);
        PendingIntent pendingIntent = PendingIntent.getBroadcast(appContext, id, intent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        builder.setContentIntent(pendingIntent);

        NotificationManagerCompat.from(appContext).notify(id, builder.build());
    }

    public static void scheduleNotification(int id, long timestamp, String channelId, String title, String body, String payload, boolean repeatDaily) {
        // Implementation for scheduled notifications using AlarmManager
        // For simplicity, omitted in this version
    }

    public static void cancelNotification(int id) {
        notificationManager.cancel(id);
    }

    public static void cancelAllNotifications() {
        notificationManager.cancelAll();
    }

    public static void setBadgeNumber(int count) {
        // wikk Implemente  for badge count (requires launcher specific code) soon
    }
}
