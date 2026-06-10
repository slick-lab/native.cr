// src/native/engine/android/java/com/nativecr/OnClickCallback.java

package com.nativecr;

import android.view.View;

public class OnClickCallback implements View.OnClickListener, View.OnLongClickListener {
    private long nativePtr;

    public OnClickCallback(long ptr) {
        this.nativePtr = ptr;
    }

    @Override
    public void onClick(View v) {
        nativeOnClick(nativePtr);
    }

    @Override
    public boolean onLongClick(View v) {
        nativeOnLongClick(nativePtr);
        return true;
    }

    private static native void nativeOnClick(long ptr);
    private static native void nativeOnLongClick(long ptr);
}
