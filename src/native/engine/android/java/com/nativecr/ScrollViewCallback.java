// src/native/engine/android/java/com/nativecr/ScrollViewCallback.java

package com.nativecr;

import android.view.View;

public class ScrollViewCallback implements View.OnScrollChangeListener {
    private long nativePtr;

    public ScrollViewCallback(long ptr) {
        this.nativePtr = ptr;
    }

    @Override
    public void onScrollChange(View v, int scrollX, int scrollY, int oldScrollX, int oldScrollY) {
        nativeOnScrollChanged(nativePtr, scrollX, scrollY);
    }

    private static native void nativeOnScrollChanged(long ptr, int scrollX, int scrollY);
}
