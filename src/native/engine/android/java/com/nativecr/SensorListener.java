// src/native/engine/android/java/com/nativecr/SensorListener.java

package com.nativecr;

import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;

import org.json.JSONArray;
import org.json.JSONObject;

public class SensorListener implements SensorEventListener {
    private long nativePtr;
    private int sensorType;

    public SensorListener(long ptr, int type) {
        this.nativePtr = ptr;
        this.sensorType = type;
    }

    @Override
    public void onSensorChanged(SensorEvent event) {
        float[] values = event.values;
        double[] doubles = new double[values.length];
        for (int i = 0; i < values.length; i++) {
            doubles[i] = values[i];
        }
        nativeOnSensorChanged(nativePtr, sensorType, event.timestamp, doubles, event.accuracy);
    }

    @Override
    public void onAccuracyChanged(Sensor sensor, int accuracy) {
        nativeOnAccuracyChanged(nativePtr, sensorType, accuracy);
    }

    private static native void nativeOnSensorChanged(long ptr, int type, long timestamp, double[] values, int accuracy);
    private static native void nativeOnAccuracyChanged(long ptr, int type, int accuracy);
}
