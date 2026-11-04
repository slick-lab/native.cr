// src/native/engine/android/java/com/nativecr/NativeHelper.java
//
// Static helpers that must run on the Android UI thread.
// Crystal JNI calls these from its background thread; they
// dispatch the work to the main thread via runOnUiThread.

package com.nativecr;

import android.app.Activity;
import android.view.View;

public class NativeHelper {

    /**
     * Attach a Crystal-built view tree as the Activity's content view.
     * Must be called from any thread — dispatches to the UI thread internally.
     */
    public static void setContentView(final Activity activity, final View view) {
        if (activity == null || view == null) return;
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                activity.setContentView(view);
            }
        });
    }

    /**
     * Replace the current content view with a new one.
     * Used by Navigator when switching between screens.
     */
    public static void replaceContentView(final Activity activity, final View view) {
        if (activity == null || view == null) return;
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                activity.setContentView(view);
            }
        });
    }

    /**
     * Set text on a TextView from ANY thread.
     *
     * Crystal callbacks (button taps, network responses) run on the
     * Crystal thread; mutating an attached view from there throws
     * CalledFromWrongThreadException. This hop keeps the documented
     * `label.text = "..."` pattern safe from callbacks.
     *
     * NOTE: when no activity is attached yet the call runs inline —
     * unattached views are safe from any thread.
     */
    public static void setTextOnUiThread(final Activity activity, final View view, final String text) {
        if (view == null) return;
        if (activity == null) {
            if (view instanceof android.widget.TextView) {
                ((android.widget.TextView) view).setText(text);
            }
            return;
        }
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (view instanceof android.widget.TextView) {
                    ((android.widget.TextView) view).setText(text);
                }
            }
        });
    }

    /**
     * Fire a haptic pulse (duration in ms) via the Vibrator service.
     * Runs inline: Vibrator is safe to call from any thread.
     */
    @SuppressWarnings({"deprecation", "UnspecifiedRegister"})
    public static void haptic(final Activity activity, int durationMs) {
        try {
            if (activity == null) return;
            Object service = activity.getSystemService(android.content.Context.VIBRATOR_SERVICE);
            if (service instanceof android.os.Vibrator) {
                ((android.os.Vibrator) service).vibrate(durationMs);
            }
        } catch (Throwable t) {
            // Haptics are best-effort; never crash an app over a buzz.
        }
    }
}
