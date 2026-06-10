// src/native/engine/android/java/com/nativecr/SoundPlayer.java

package com.nativecr;

import android.content.Context;
import android.media.AudioAttributes;
import android.media.SoundPool;
import android.util.Log;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class SoundPlayer {
    private static SoundPool soundPool;
    private static Map<Long, Integer> soundMap = new HashMap<>();
    private static Map<Long, Integer> streamMap = new HashMap<>();
    private static long nextSoundId = 1;
    private static long nextStreamId = 1;
    private static ExecutorService executor = Executors.newSingleThreadExecutor();
    private static Context appContext;

    public static void init(Context context) {
        if (soundPool == null) {
            appContext = context.getApplicationContext();
            AudioAttributes audioAttributes = new AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_GAME)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build();
            soundPool = new SoundPool.Builder()
                    .setMaxStreams(10)
                    .setAudioAttributes(audioAttributes)
                    .build();
        }
    }

    public static long load(Context context, String path) {
        init(context);
        final long soundId = nextSoundId++;
        executor.execute(() -> {
            try {
                int resId = context.getResources().getIdentifier(path, "raw", context.getPackageName());
                int loadedId;
                if (resId != 0) {
                    loadedId = soundPool.load(context, resId, 1);
                } else {
                    loadedId = soundPool.load(path, 1);
                }
                soundMap.put(soundId, loadedId);
            } catch (Exception e) {
                Log.e("SoundPlayer", "Error loading sound: " + e.getMessage());
                soundMap.put(soundId, -1);
            }
        });
        return soundId;
    }

    public static long play(long soundId, float volume, boolean loop, float pitch, float pan) {
        Integer loadedId = soundMap.get(soundId);
        if (loadedId == null || loadedId == -1) {
            return 0;
        }
        int loopCount = loop ? -1 : 0;
        float leftVolume = volume * (1 - Math.max(pan, 0));
        float rightVolume = volume * (1 + Math.min(pan, 0));
        int streamId = soundPool.play(loadedId, leftVolume, rightVolume, 1, loopCount, pitch);
        if (streamId != 0) {
            long streamKey = nextStreamId++;
            streamMap.put(streamKey, streamId);
            return streamKey;
        }
        return 0;
    }

    public static void stopAll(long soundId) {
        // Stop all streams (implementation would need to track streams per sound)
    }

    public static void stopInstance(long instanceId) {
        Integer streamId = streamMap.get(instanceId);
        if (streamId != null) {
            soundPool.stop(streamId);
            streamMap.remove(instanceId);
        }
    }

    public static void pause(long instanceId) {
        Integer streamId = streamMap.get(instanceId);
        if (streamId != null) {
            soundPool.pause(streamId);
        }
    }

    public static void resume(long instanceId) {
        Integer streamId = streamMap.get(instanceId);
        if (streamId != null) {
            soundPool.resume(streamId);
        }
    }

    public static void setVolume(long instanceId, float volume) {
        Integer streamId = streamMap.get(instanceId);
        if (streamId != null) {
            soundPool.setVolume(streamId, volume, volume);
        }
    }

    public static boolean isPlaying(long instanceId) {
        Integer streamId = streamMap.get(instanceId);
        if (streamId != null) {
            // SoundPool doesn't have a direct isPlaying method
            return true;
        }
        return false;
    }

    public static void unload(long soundId) {
        Integer loadedId = soundMap.get(soundId);
        if (loadedId != null && loadedId != -1) {
            soundPool.unload(loadedId);
            soundMap.remove(soundId);
        }
    }
}
