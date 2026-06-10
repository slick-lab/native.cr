// src/native/engine/android/java/com/nativecr/BiometricCallback.java

package com.nativecr;

import androidx.biometric.BiometricPrompt;
import androidx.fragment.app.FragmentActivity;

import java.util.concurrent.Executor;
import java.util.concurrent.Executors;

public class BiometricCallback extends BiometricPrompt.AuthenticationCallback {
    private long nativePtr;

    public BiometricCallback(long ptr) {
        this.nativePtr = ptr;
    }

    @Override
    public void onAuthenticationSucceeded(BiometricPrompt.AuthenticationResult result) {
        nativeOnAuthenticationSucceeded(nativePtr);
    }

    @Override
    public void onAuthenticationFailed() {
        nativeOnAuthenticationFailed(nativePtr);
    }

    @Override
    public void onAuthenticationError(int errorCode, CharSequence errString) {
        nativeOnAuthenticationError(nativePtr, errorCode, errString.toString());
    }

    private static native void nativeOnAuthenticationSucceeded(long ptr);
    private static native void nativeOnAuthenticationFailed(long ptr);
    private static native void nativeOnAuthenticationError(long ptr, int errorCode, String errString);
}
