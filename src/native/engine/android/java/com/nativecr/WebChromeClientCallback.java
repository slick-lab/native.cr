// src/native/engine/android/java/com/nativecr/WebChromeClientCallback.java

package com.nativecr;

import android.webkit.WebChromeClient;
import android.webkit.WebView;

public class WebChromeClientCallback extends WebChromeClient {
    private long nativePtr;

    public WebChromeClientCallback(long ptr) {
        this.nativePtr = ptr;
    }

    @Override
    public void onProgressChanged(WebView view, int newProgress) {
        nativeOnProgressChanged(nativePtr, newProgress);
    }

    @Override
    public void onReceivedTitle(WebView view, String title) {
        nativeOnReceivedTitle(nativePtr, title);
    }

    private static native void nativeOnProgressChanged(long ptr, int progress);
    private static native void nativeOnReceivedTitle(long ptr, String title);
}
