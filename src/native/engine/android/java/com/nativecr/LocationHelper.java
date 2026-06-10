// src/native/engine/android/java/com/nativecr/LocationHelper.java

package com.nativecr;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import org.json.JSONObject;

import java.util.HashMap;
import java.util.Map;

public class LocationHelper implements LocationListener {
    private static LocationHelper instance;
    private static Context appContext;
    private static Activity currentActivity;
    private static LocationCallback callback;
    private static LocationManager locationManager;
    private static Location lastLocation;
    private static boolean isListening = false;
    private static Handler mainHandler = new Handler(Looper.getMainLooper());

    public interface LocationCallback {
        void onLocationUpdate(String json);
        void onError(String error);
    }

    public static void init(Activity activity) {
        currentActivity = activity;
        appContext = activity.getApplicationContext();
        if (instance == null) {
            instance = new LocationHelper();
        }
        locationManager = (LocationManager) appContext.getSystemService(Context.LOCATION_SERVICE);
    }

    public static void setCallback(LocationCallback cb) {
        callback = cb;
    }

    public static void startUpdates(int accuracy, int priority, float minDistance, long minTime) {
        if (!hasLocationPermission()) {
            if (callback != null) {
                callback.onError("Location permission not granted");
            }
            return;
        }

        if (isListening) return;

        String provider = LocationManager.GPS_PROVIDER;
        if (!locationManager.isProviderEnabled(provider)) {
            provider = LocationManager.NETWORK_PROVIDER;
        }

        try {
            locationManager.requestLocationUpdates(provider, minTime, minDistance, instance, Looper.getMainLooper());
            isListening = true;
        } catch (SecurityException e) {
            if (callback != null) {
                callback.onError("Security exception: " + e.getMessage());
            }
        }
    }

    public static void stopUpdates() {
        if (locationManager != null && instance != null) {
            locationManager.removeUpdates(instance);
            isListening = false;
        }
    }

    public static String getLastLocation() {
        if (!hasLocationPermission()) {
            return null;
        }

        Location location = null;
        try {
            if (locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
                location = locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER);
            }
            if (location == null && locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
                location = locationManager.getLastKnownLocation(LocationManager.NETWORK_PROVIDER);
            }
        } catch (SecurityException e) {
            return null;
        }

        if (location != null) {
            return locationToJson(location);
        }
        return null;
    }

    private static boolean hasLocationPermission() {
        return ContextCompat.checkSelfPermission(appContext, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
                ContextCompat.checkSelfPermission(appContext, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED;
    }

    private static String locationToJson(Location location) {
        try {
            JSONObject obj = new JSONObject();
            obj.put("latitude", location.getLatitude());
            obj.put("longitude", location.getLongitude());
            obj.put("altitude", location.getAltitude());
            obj.put("accuracy", location.getAccuracy());
            obj.put("bearing", location.getBearing());
            obj.put("speed", location.getSpeed());
            obj.put("timestamp", location.getTime());
            obj.put("provider", location.getProvider());
            return obj.toString();
        } catch (Exception e) {
            return null;
        }
    }

    @Override
    public void onLocationChanged(Location location) {
        lastLocation = location;
        if (callback != null) {
            String json = locationToJson(location);
            if (json != null) {
                mainHandler.post(() -> callback.onLocationUpdate(json));
            }
        }
    }

    @Override
    public void onStatusChanged(String provider, int status, Bundle extras) {}

    @Override
    public void onProviderEnabled(String provider) {}

    @Override
    public void onProviderDisabled(String provider) {
        if (callback != null) {
            mainHandler.post(() -> callback.onError("Location provider disabled"));
        }
    }
}
