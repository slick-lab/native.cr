// src/native/engine/android/java/com/nativecr/TextWatcherCallback.java

package com.nativecr;

import android.text.Editable;
import android.text.TextWatcher;

public class TextWatcherCallback implements TextWatcher {
    private long nativePtr;

    public TextWatcherCallback(long ptr) {
        this.nativePtr = ptr;
    }

    @Override
    public void beforeTextChanged(CharSequence s, int start, int count, int after) {}

    @Override
    public void onTextChanged(CharSequence s, int start, int before, int count) {}

    @Override
    public void afterTextChanged(Editable s) {
        nativeOnTextChanged(nativePtr, s.toString());
    }

    private static native void nativeOnTextChanged(long ptr, String text);
}
