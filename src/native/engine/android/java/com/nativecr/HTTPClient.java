// src/native/engine/android/java/com/nativecr/HTTPClient.java

package com.nativecr;

import android.os.Handler;
import android.os.Looper;

import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.ByteArrayOutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class HTTPClient {
    private static ExecutorService executor = Executors.newCachedThreadPool();
    private static Handler mainHandler = new Handler(Looper.getMainLooper());

    public interface Callback {
        void onResult(String result);
    }

    public interface StreamCallback {
        void onChunk(byte[] data);
        void onComplete();
        void onError(String error);
    }

    public static void execute(String url, String method, String[] headerKeys, String[] headerValues, String body, double timeout, Callback callback) {
        executor.execute(() -> {
            HttpURLConnection connection = null;
            try {
                URL requestUrl = new URL(url);
                connection = (HttpURLConnection) requestUrl.openConnection();
                connection.setRequestMethod(method);
                connection.setConnectTimeout((int)(timeout * 1000));
                connection.setReadTimeout((int)(timeout * 1000));

                for (int i = 0; i < headerKeys.length && i < headerValues.length; i++) {
                    if (headerKeys[i] != null && headerValues[i] != null) {
                        connection.setRequestProperty(headerKeys[i], headerValues[i]);
                    }
                }

                if (body != null && !body.isEmpty() && (method.equals("POST") || method.equals("PUT") || method.equals("PATCH"))) {
                    connection.setDoOutput(true);
                    DataOutputStream writer = new DataOutputStream(connection.getOutputStream());
                    writer.writeBytes(body);
                    writer.flush();
                    writer.close();
                }

                int responseCode = connection.getResponseCode();
                InputStream inputStream;
                if (responseCode >= 200 && responseCode < 300) {
                    inputStream = connection.getInputStream();
                } else {
                    inputStream = connection.getErrorStream();
                }

                BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream));
                StringBuilder response = new StringBuilder();
                String line;
                while ((line = reader.readLine()) != null) {
                    response.append(line);
                }
                reader.close();

                String result = String.format("{\"status\":%d,\"body\":\"%s\",\"success\":%s}",
                        responseCode,
                        escapeJson(response.toString()),
                        responseCode >= 200 && responseCode < 300);

                final String finalResult = result;
                mainHandler.post(() -> callback.onResult(finalResult));

            } catch (Exception e) {
                String errorResult = String.format("{\"status\":0,\"body\":\"%s\",\"success\":false}", escapeJson(e.getMessage()));
                mainHandler.post(() -> callback.onResult(errorResult));
            } finally {
                if (connection != null) {
                    connection.disconnect();
                }
            }
        });
    }

    public static void executeStream(String url, String method, String[] headerKeys, String[] headerValues, StreamCallback callback, double timeout) {
        executor.execute(() -> {
            HttpURLConnection connection = null;
            try {
                URL requestUrl = new URL(url);
                connection = (HttpURLConnection) requestUrl.openConnection();
                connection.setRequestMethod(method);
                connection.setConnectTimeout((int)(timeout * 1000));
                connection.setReadTimeout((int)(timeout * 1000));

                for (int i = 0; i < headerKeys.length && i < headerValues.length; i++) {
                    if (headerKeys[i] != null && headerValues[i] != null) {
                        connection.setRequestProperty(headerKeys[i], headerValues[i]);
                    }
                }

                int responseCode = connection.getResponseCode();
                if (responseCode >= 200 && responseCode < 300) {
                    InputStream inputStream = connection.getInputStream();
                    byte[] buffer = new byte[8192];
                    int bytesRead;
                    while ((bytesRead = inputStream.read(buffer)) != -1) {
                        byte[] chunk = new byte[bytesRead];
                        System.arraycopy(buffer, 0, chunk, 0, bytesRead);
                        mainHandler.post(() -> callback.onChunk(chunk));
                    }
                    inputStream.close();
                    mainHandler.post(() -> callback.onComplete());
                } else {
                    mainHandler.post(() -> callback.onError("HTTP " + responseCode));
                }

            } catch (Exception e) {
                mainHandler.post(() -> callback.onError(e.getMessage()));
            } finally {
                if (connection != null) {
                    connection.disconnect();
                }
            }
        });
    }

    private static String escapeJson(String s) {
        StringBuilder sb = new StringBuilder();
        for (char c : s.toCharArray()) {
            switch (c) {
                case '"': sb.append("\\\""); break;
                case '\\': sb.append("\\\\"); break;
                case '\n': sb.append("\\n"); break;
                case '\r': sb.append("\\r"); break;
                case '\t': sb.append("\\t"); break;
                default: sb.append(c);
            }
        }
        return sb.toString();
    }
}
