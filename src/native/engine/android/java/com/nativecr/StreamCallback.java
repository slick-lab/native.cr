// src/native/engine/android/java/com/nativecr/StreamCallback.java

package com.nativecr;

/**
 * Bridges Android HTTP stream events back into Crystal.
 *
 * Constructed from Crystal via JNI with a native handle
 * ({@code new StreamCallback(J)} — see network.cr's
 * {@code execute_android_stream}); each event dispatches through a native
 * method to the Crystal handler registered under that handle.
 *
 * This must be a concrete class, not an interface: Crystal's JNI bridge
 * instantiates it with NewObject, which always fails on interfaces.
 *
 * All methods are invoked from HTTPClient's single-thread stream
 * dispatcher — the same thread the Crystal dispatch funs GC-register.
 */
public class StreamCallback {
    private long nativePtr;

    public StreamCallback(long ptr) {
        this.nativePtr = ptr;
    }

    public void onChunk(byte[] data) {
        nativeStreamChunk(nativePtr, data);
    }

    public void onComplete(int status) {
        nativeStreamComplete(nativePtr, status);
    }

    public void onError(byte[] utf8Message) {
        nativeStreamError(nativePtr, utf8Message);
    }

    // Resolved by ART's short-name lookup against the Crystal binary's
    // exported funs of the same name (see the dispatch funs at the
    // bottom of network.cr).
    private static native void nativeStreamChunk(long ptr, byte[] data);
    private static native void nativeStreamComplete(long ptr, int status);
    private static native void nativeStreamError(long ptr, byte[] utf8Message);
}
