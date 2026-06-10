// src/native/engine/android/java/com/nativecr/CompoundButtonCallback.java

package com.nativecr;

import android.widget.CompoundButton;

public class CompoundButtonCallback implements CompoundButton.OnCheckedChangeListener {
    private long nativePtr;

    public CompoundButtonCallback(long ptr) {
        this.nativePtr = ptr;
    }

    @Override
    public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
        nativeOnCheckedChanged(nativePtr, isChecked);
    }

    private static native void nativeOnCheckedChanged(long ptr, boolean isChecked);
}
