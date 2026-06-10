// src/native/engine/android/java/com/nativecr/MusicPlayer.java

package com.nativecr;

import android.content.Context;
import android.media.MediaPlayer;
import android.net.Uri;
import android.util.Log;
import java.util.HashMap;
import java.util.Map;

public class MusicPlayer {
    private static Map<Long, MediaPlayer> playerMap = new HashMap<>();
    private static long nextPlayerId = 1;
    private static Context appContext;

    public static void init(Context context) {
        appContext = context.getApplicationContext();
    }

    public static long load(Context context, String path) {
        init(context);
        final long playerId = nextPlayerId++;
        try {
            MediaPlayer mediaPlayer;
            int resId = context.getResources().getIdentifier(path, "raw", context.getPackageName());
            if (resId != 0) {
                mediaPlayer = MediaPlayer.create(context, resId);
            } else {
                Uri uri = Uri.parse(path);
                mediaPlayer = MediaPlayer.create(context, uri);
            }
            if (mediaPlayer != null) {
                playerMap.put(playerId, mediaPlayer);
                return playerId;
            } else {
                return 0;
            }
        } catch (Exception e) {
            Log.e("MusicPlayer", "Error loading music: " + e.getMessage());
            return 0;
        }
    }

    public static void play(long playerId, boolean loop) {
        MediaPlayer player = playerMap.get(playerId);
        if (player != null) {
            player.setLooping(loop);
            player.start();
        }
    }

    public static void pause(long playerId) {
        MediaPlayer player = playerMap.get(playerId);
        if (player != null && player.isPlaying()) {
            player.pause();
        }
    }

    public static void resume(long playerId) {
        MediaPlayer player = playerMap.get(playerId);
        if (player != null && !player.isPlaying()) {
            player.start();
        }
    }

    public static void stop(long playerId) {
        MediaPlayer player = playerMap.get(playerId);
        if (player != null) {
            if (player.isPlaying()) {
                player.stop();
            }
            player.reset();
        }
    }

    public static void setVolume(long playerId, float volume) {
        MediaPlayer player = playerMap.get(playerId);
        if (player != null) {
            player.setVolume(volume, volume);
        }
    }

    public static void seek(long playerId, double position) {
        MediaPlayer player = playerMap.get(playerId);
        if (player != null) {
            player.seekTo((int) position);
        }
    }

    public static double getPosition(long playerId) {
        MediaPlayer player = playerMap.get(playerId);
        if (player != null && player.isPlaying()) {
            return player.getCurrentPosition();
        }
        return 0;
    }

    public static double getDuration(long playerId) {
        MediaPlayer player = playerMap.get(playerId);
        if (player != null) {
            return player.getDuration();
        }
        return 0;
    }

    public static void unload(long playerId) {
        MediaPlayer player = playerMap.get(playerId);
        if (player != null) {
            if (player.isPlaying()) {
                player.stop();
            }
            player.release();
            playerMap.remove(playerId);
        }
    }
}
