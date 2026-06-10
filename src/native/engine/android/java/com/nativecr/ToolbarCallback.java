// src/native/engine/android/java/com/nativecr/ToolbarCallback.java

package com.nativecr;

import android.view.View;
import android.view.MenuItem;

import androidx.appcompat.widget.Toolbar;

public class ToolbarCallback implements Toolbar.OnMenuItemClickListener, View.OnClickListener {
    private long nativePtr;

    public ToolbarCallback(long ptr) {
        this.nativePtr = ptr;
    }

    @Override
    public boolean onMenuItemClick(MenuItem item) {
        nativeOnMenuItemClick(nativePtr, item.getItemId());
        return true;
    }

    @Override
    public void onClick(View v) {
        nativeOnNavigationClick(nativePtr);
    }

    private static native void nativeOnMenuItemClick(long ptr, int itemId);
    private static native void nativeOnNavigationClick(long ptr);
}
