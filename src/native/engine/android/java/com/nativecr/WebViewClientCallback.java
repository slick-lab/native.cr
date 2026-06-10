// src/native/engine/android/java/com/nativecr/WebViewClientCallback.java

package com.nativecr;

import android.webkit.WebResourceRequest;
import android.webkit.WebResourceError;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.net.http.SslError;
import android.webkit.SslErrorHandler;

public class WebViewClientCallback extends WebViewClient {
    private long nativePtr;

    public WebViewClientCallback(long ptr) {
        this.nativePtr = ptr;
    }

    @Override
    public void onPageStarted(WebView view, String url, android.graphics.Bitmap favicon) {
        nativeOnPageStarted(nativePtr, url);
    }

    @Override
    public void onPageFinished(WebView view, String url) {
        nativeOnPageFinished(nativePtr, url);
    }

    @Override
    public void onReceivedError(WebView view, WebResourceRequest request, WebResourceError error) {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            nativeOnError(nativePtr, error.getDescription().toString());
        } else {
            nativeOnError(nativePtr, "Unknown error");
        }
    }

    @Override
    public void onReceivedSslError(WebView view, SslErrorHandler handler, SslError error) {
        nativeOnError(nativePtr, "SSL error: " + error.getPrimaryError());
        handler.cancel();
    }

    @Override
    public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
        String url = request.getUrl().toString();
        if (url.startsWith("http://") || url.startsWith("https://")) {
            return false;
        }
        return true;
    }

    private static native void nativeOnPageStarted(long ptr, String url);
    private static native void nativeOnPageFinished(long ptr, String url);
    private static native void nativeOnError(long ptr, String error);
}
