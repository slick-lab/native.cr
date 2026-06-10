// src/native/engine/android/java/com/nativecr/ConnectivityHelper.java

package com.nativecr;

import android.content.Context;
import android.net.ConnectivityManager;
import android.net.Network;
import android.net.NetworkCapabilities;
import android.net.NetworkRequest;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.os.Build;
import android.util.Log;

import org.json.JSONObject;

public class ConnectivityHelper {
    private static Context appContext;
    private static ConnectivityManager connectivityManager;
    private static ConnectivityCallback callback;
    private static ConnectivityNetworkCallback networkCallback;

    public interface ConnectivityCallback {
        void onNetworkChanged(String json);
    }

    public static void init(Context context) {
        appContext = context.getApplicationContext();
        connectivityManager = (ConnectivityManager) appContext.getSystemService(Context.CONNECTIVITY_SERVICE);
    }

    public static void setCallback(ConnectivityCallback cb) {
        callback = cb;
    }

    public static void startMonitoring() {
        if (networkCallback != null) return;

        NetworkRequest networkRequest = new NetworkRequest.Builder()
                .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
                .build();

        networkCallback = new ConnectivityNetworkCallback();
        connectivityManager.registerNetworkCallback(networkRequest, networkCallback);
    }

    public static void stopMonitoring() {
        if (networkCallback != null) {
            connectivityManager.unregisterNetworkCallback(networkCallback);
            networkCallback = null;
        }
    }

    public static String getNetworkInfo() {
        try {
            JSONObject obj = new JSONObject();
            boolean isConnected = isConnected();
            obj.put("connected", isConnected);
            obj.put("type", getNetworkTypeInt());
            obj.put("metered", isMetered());
            obj.put("roaming", isRoaming());
            obj.put("ssid", getWifiSSID());
            obj.put("ip", getIPAddress());
            obj.put("signal", getSignalStrength());
            return obj.toString();
        } catch (Exception e) {
            return "{\"connected\":false}";
        }
    }

    private static boolean isConnected() {
        if (connectivityManager == null) return false;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Network network = connectivityManager.getActiveNetwork();
            if (network == null) return false;
            NetworkCapabilities capabilities = connectivityManager.getNetworkCapabilities(network);
            return capabilities != null && capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET);
        } else {
            android.net.NetworkInfo activeNetwork = connectivityManager.getActiveNetworkInfo();
            return activeNetwork != null && activeNetwork.isConnectedOrConnecting();
        }
    }

    private static int getNetworkTypeInt() {
        if (connectivityManager == null) return 0;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Network network = connectivityManager.getActiveNetwork();
            if (network == null) return 0;
            NetworkCapabilities capabilities = connectivityManager.getNetworkCapabilities(network);
            if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) return 1;
            if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)) return 2;
            if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET)) return 3;
            if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_BLUETOOTH)) return 4;
            return 5;
        } else {
            android.net.NetworkInfo activeNetwork = connectivityManager.getActiveNetworkInfo();
            if (activeNetwork == null) return 0;
            int type = activeNetwork.getType();
            if (type == ConnectivityManager.TYPE_WIFI) return 1;
            if (type == ConnectivityManager.TYPE_MOBILE) return 2;
            if (type == ConnectivityManager.TYPE_ETHERNET) return 3;
            if (type == ConnectivityManager.TYPE_BLUETOOTH) return 4;
            return 5;
        }
    }

    private static boolean isMetered() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Network network = connectivityManager.getActiveNetwork();
            if (network == null) return false;
            NetworkCapabilities capabilities = connectivityManager.getNetworkCapabilities(network);
            return !capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED);
        }
        return false;
    }

    private static boolean isRoaming() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Network network = connectivityManager.getActiveNetwork();
            if (network == null) return false;
            NetworkCapabilities capabilities = connectivityManager.getNetworkCapabilities(network);
            return capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_ROAMING);
        }
        return false;
    }

    private static String getWifiSSID() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Requires location permission
            return "";
        }
        try {
            WifiManager wifiManager = (WifiManager) appContext.getSystemService(Context.WIFI_SERVICE);
            WifiInfo wifiInfo = wifiManager.getConnectionInfo();
            String ssid = wifiInfo.getSSID();
            if (ssid != null && ssid.startsWith("\"") && ssid.endsWith("\"")) {
                ssid = ssid.substring(1, ssid.length() - 1);
            }
            return ssid != null ? ssid : "";
        } catch (Exception e) {
            return "";
        }
    }

    private static String getIPAddress() {
        try {
            WifiManager wifiManager = (WifiManager) appContext.getSystemService(Context.WIFI_SERVICE);
            WifiInfo wifiInfo = wifiManager.getConnectionInfo();
            int ip = wifiInfo.getIpAddress();
            return String.format("%d.%d.%d.%d", (ip & 0xff), (ip >> 8 & 0xff), (ip >> 16 & 0xff), (ip >> 24 & 0xff));
        } catch (Exception e) {
            return "";
        }
    }

    private static int getSignalStrength() {
        // Requires telephony manager for cellular signal
        return 0;
    }

    private static class ConnectivityNetworkCallback extends ConnectivityManager.NetworkCallback {
        @Override
        public void onAvailable(Network network) {
            if (callback != null) {
                callback.onNetworkChanged(getNetworkInfo());
            }
        }

        @Override
        public void onLost(Network network) {
            if (callback != null) {
                callback.onNetworkChanged(getNetworkInfo());
            }
        }

        @Override
        public void onCapabilitiesChanged(Network network, NetworkCapabilities networkCapabilities) {
            if (callback != null) {
                callback.onNetworkChanged(getNetworkInfo());
            }
        }
    }
}
