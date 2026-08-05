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
}
