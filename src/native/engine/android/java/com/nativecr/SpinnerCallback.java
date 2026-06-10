// src/native/engine/android/java/com/nativecr/SpinnerCallback.java

package com.nativecr;

import android.view.View;
import android.widget.AdapterView;

public class SpinnerCallback implements AdapterView.OnItemSelectedListener {
    private long nativePtr;

    public SpinnerCallback(long ptr) {
        this.nativePtr = ptr;
    }

    @Override
    public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
        nativeOnItemSelected(nativePtr, position);
    }

    @Override
    public void onNothingSelected(AdapterView<?> parent) {
        nativeOnNothingSelected(nativePtr);
    }

    private static native void nativeOnItemSelected(long ptr, int position);
    private static native void nativeOnNothingSelected(long ptr);
}
