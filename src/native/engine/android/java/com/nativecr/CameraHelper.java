// src/native/engine/android/java/com/nativecr/CameraHelper.java

package com.nativecr;

import android.app.Activity;
import android.hardware.Camera;
import android.view.SurfaceView;
import android.view.SurfaceHolder;

import java.io.File;
import java.io.FileOutputStream;

public class CameraHelper implements SurfaceHolder.Callback {
    private Camera camera;
    private SurfaceView surfaceView;
    private SurfaceHolder surfaceHolder;
    private boolean isPreviewRunning = false;
    private int facing = 0;

    public void setFacing(int facing) {
        this.facing = facing;
    }

    public void startPreview(SurfaceView view) {
        this.surfaceView = view;
        this.surfaceHolder = view.getHolder();
        surfaceHolder.addCallback(this);
    }

    public void stopPreview() {
        if (camera != null) {
            camera.stopPreview();
            camera.release();
            camera = null;
            isPreviewRunning = false;
        }
    }

    public void takePhoto() {
        if (camera != null) {
            camera.takePicture(null, null, new Camera.PictureCallback() {
                @Override
                public void onPictureTaken(byte[] data, Camera camera) {
                    // Photo captured, callback would send to Crystal
                }
            });
        }
    }

    @Override
    public void surfaceCreated(SurfaceHolder holder) {
        try {
            camera = Camera.open(facing);
            camera.setPreviewDisplay(holder);
        } catch (Exception e) {
            camera = null;
        }
    }

    @Override
    public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
        if (camera != null) {
            Camera.Parameters params = camera.getParameters();
            camera.setParameters(params);
            camera.startPreview();
            isPreviewRunning = true;
        }
    }

    @Override
    public void surfaceDestroyed(SurfaceHolder holder) {
        stopPreview();
    }
}
