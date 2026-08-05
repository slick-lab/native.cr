// src/native/engine/android/java/com/nativecr/NotificationHelper.java

package com.nativecr;

import android.app.AlarmManager;
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
    private static final Map<String, String> channelMap = new HashMap<>();

    public static void init(Context context) {
        appContext = context.getApplicationContext();
        notificationManager = (NotificationManager)
            appContext.getSystemService(Context.NOTIFICATION_SERVICE);
    }

    public static void createChannel(String id, String name, String description,
                                     int importance, boolean showBadge,
                                     boolean vibration, boolean soundEnabled,
                                     String soundUri) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(id, name, importance);
            if (description != null) channel.setDescription(description);
            channel.setShowBadge(showBadge);
            channel.enableVibration(vibration);
            channel.enableLights(true);
            channel.setLightColor(Color.BLUE);
            if (soundEnabled && soundUri != null && !soundUri.isEmpty()) {
                channel.setSound(android.net.Uri.parse(soundUri),
                    Notification.AUDIO_ATTRIBUTES_DEFAULT);
            }
            notificationManager.createNotificationChannel(channel);
        }
        channelMap.put(id, name);
    }

    public static void showNotification(int id, String channelId, String title,
                                        String body, String subtitle,
                                        String largeIcon, String smallIcon,
                                        int badgeNumber, int priority,
                                        boolean autoCancel, String sound,
                                        boolean vibration, int color,
                                        String payload, boolean hasActions,
                                        String actionIds) {
        if (appContext == null) return;

        // Resolve small icon resource — fall back to app icon if not found.
        int iconRes = 0;
        if (smallIcon != null && !smallIcon.isEmpty()) {
            iconRes = appContext.getResources().getIdentifier(
                smallIcon, "drawable", appContext.getPackageName());
        }
        if (iconRes == 0) {
            iconRes = appContext.getApplicationInfo().icon;
        }

        NotificationCompat.Builder builder = new NotificationCompat.Builder(appContext, channelId)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(priority)
            .setAutoCancel(autoCancel)
            .setSmallIcon(iconRes);

        if (subtitle != null && !subtitle.isEmpty()) builder.setSubText(subtitle);
        if (badgeNumber > 0) builder.setNumber(badgeNumber);
        if (color != 0) builder.setColor(color);

        if (vibration) {
            builder.setVibrate(new long[]{0, 250, 100, 250});
        }

        // Sound (pre-Oreo only; channels handle sound on Oreo+).
        if (sound != null && !sound.isEmpty()
                && Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            builder.setDefaults(Notification.DEFAULT_SOUND);
        }

        // Tap intent → NotificationReceiver which bridges back to Crystal.
        Intent tapIntent = new Intent(appContext, NotificationReceiver.class);
        tapIntent.setAction(NotificationReceiver.ACTION_NOTIFICATION_TAPPED);
        tapIntent.putExtra("payload", payload != null ? payload : "{}");
        tapIntent.putExtra("notification_id", id);

        int flags = PendingIntent.FLAG_UPDATE_CURRENT;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags |= PendingIntent.FLAG_IMMUTABLE;
        }
        PendingIntent pendingIntent = PendingIntent.getBroadcast(
            appContext, id, tapIntent, flags);
        builder.setContentIntent(pendingIntent);

        try {
            NotificationManagerCompat.from(appContext).notify(id, builder.build());
        } catch (SecurityException e) {
            // POST_NOTIFICATIONS permission not granted (Android 13+).
        }
    }

    public static void scheduleNotification(int id, long timestampMs,
                                             String channelId, String title,
                                             String body, String payload,
                                             boolean repeatDaily) {
        if (appContext == null) return;

        Intent intent = new Intent(appContext, NotificationReceiver.class);
        intent.setAction(NotificationReceiver.ACTION_SCHEDULE_NOTIFY);
        intent.putExtra("notification_id", id);
        intent.putExtra("channel_id", channelId != null ? channelId : "default");
        intent.putExtra("title", title != null ? title : "");
        intent.putExtra("body", body != null ? body : "");
        intent.putExtra("payload", payload != null ? payload : "{}");

        int flags = PendingIntent.FLAG_UPDATE_CURRENT;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags |= PendingIntent.FLAG_IMMUTABLE;
        }
        PendingIntent pendingIntent = PendingIntent.getBroadcast(
            appContext, id, intent, flags);

        AlarmManager alarmManager =
            (AlarmManager) appContext.getSystemService(Context.ALARM_SERVICE);
        if (alarmManager == null) return;

        if (repeatDaily) {
            alarmManager.setRepeating(
                AlarmManager.RTC_WAKEUP,
                timestampMs,
                AlarmManager.INTERVAL_DAY,
                pendingIntent);
        } else {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP, timestampMs, pendingIntent);
            } else {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP, timestampMs, pendingIntent);
            }
        }
    }

    public static void cancelNotification(int id) {
        if (notificationManager != null) notificationManager.cancel(id);
        // Also cancel any scheduled alarm for this id.
        if (appContext != null) {
            Intent intent = new Intent(appContext, NotificationReceiver.class);
            intent.setAction(NotificationReceiver.ACTION_SCHEDULE_NOTIFY);
            intent.putExtra("notification_id", id);
            int flags = PendingIntent.FLAG_NO_CREATE;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                flags |= PendingIntent.FLAG_IMMUTABLE;
            }
            PendingIntent pending = PendingIntent.getBroadcast(
                appContext, id, intent, flags);
            if (pending != null) {
                AlarmManager am = (AlarmManager)
                    appContext.getSystemService(Context.ALARM_SERVICE);
                if (am != null) am.cancel(pending);
                pending.cancel();
            }
        }
    }

    public static void cancelAllNotifications() {
        if (notificationManager != null) notificationManager.cancelAll();
    }

    public static void setBadgeNumber(int count) {
    }
}
