// src/native/engine/android/java/com/nativecr/AnimatorCallback.java

package com.nativecr;

import android.animation.Animator;
import android.animation.ValueAnimator;

public class AnimatorCallback implements Animator.AnimatorListener, ValueAnimator.AnimatorUpdateListener {
    private long nativePtr;

    public AnimatorCallback(long ptr) {
        this.nativePtr = ptr;
    }

    @Override
    public void onAnimationStart(Animator animation) {
        nativeOnStart(nativePtr);
    }

    @Override
    public void onAnimationEnd(Animator animation) {
        nativeOnEnd(nativePtr);
    }

    @Override
    public void onAnimationCancel(Animator animation) {
        nativeOnCancel(nativePtr);
    }

    @Override
    public void onAnimationRepeat(Animator animation) {
        nativeOnRepeat(nativePtr);
    }

    @Override
    public void onAnimationUpdate(ValueAnimator animation) {
        float value = (float) animation.getAnimatedValue();
        nativeOnUpdate(nativePtr, value);
    }

    private static native void nativeOnStart(long ptr);
    private static native void nativeOnEnd(long ptr);
    private static native void nativeOnCancel(long ptr);
    private static native void nativeOnRepeat(long ptr);
    private static native void nativeOnUpdate(long ptr, float value);
}
