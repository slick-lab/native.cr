// src/native/engine/android/java/com/nativecr/DialogCallback.java

package com.nativecr;

import android.content.DialogInterface;

public class DialogCallback implements DialogInterface.OnClickListener {
    private long nativePtr;
    private int which;

    public DialogCallback(long ptr, int buttonWhich) {
        this.nativePtr = ptr;
        this.which = buttonWhich;
    }

    @Override
    public void onClick(DialogInterface dialog, int whichButton) {
        nativeOnClick(nativePtr, which);
        dialog.dismiss();
    }

    private static native void nativeOnClick(long ptr, int which);
}
