// src/native/engine/android/java/com/nativecr/SeekBarCallback.java

package com.nativecr;

import android.widget.SeekBar;

public class SeekBarCallback implements SeekBar.OnSeekBarChangeListener {
    private long nativePtr;

    public SeekBarCallback(long ptr) {
        this.nativePtr = ptr;
    }

    @Override
    public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
        nativeOnProgressChanged(nativePtr, progress);
    }

    @Override
    public void onStartTrackingTouch(SeekBar seekBar) {
        nativeOnStartTrackingTouch(nativePtr);
    }

    @Override
    public void onStopTrackingTouch(SeekBar seekBar) {
        nativeOnStopTrackingTouch(nativePtr);
    }

    private static native void nativeOnProgressChanged(long ptr, int progress);
    private static native void nativeOnStartTrackingTouch(long ptr);
    private static native void nativeOnStopTrackingTouch(long ptr);
}
