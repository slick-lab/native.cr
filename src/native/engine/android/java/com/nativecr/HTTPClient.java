// src/native/engine/android/java/com/nativecr/HTTPClient.java

package com.nativecr;

import java.io.DataOutputStream;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class HTTPClient {
    private static ExecutorService executor = Executors.newCachedThreadPool();

    public interface Callback {
        void onResult(String result);
    }

    // ── Synchronous request ──────────────────────────────────────────────────
    // Called via JNI from the Crystal thread (a dedicated background pthread
    // started in native.c, never the Android main thread), so blocking here
    // is legal: no NetworkOnMainThreadException, no ANR.
    //
    // Signature must stay exactly (String, String, String[], String[],
    // String, double) -> String — network.cr's GetStaticMethodID looks up
    // precisely "(Ljava/lang/String;Ljava/lang/String;[Ljava/lang/String;
    // [Ljava/lang/String;Ljava/lang/String;D)Ljava/lang/String;".
    //
    // Returns a JSON envelope {status, headers, body, success, error?}.
    public static String execute(String url, String method, String[] headerKeys,
                                 String[] headerValues, String body, double timeout) {
        HttpURLConnection connection = null;
        try {
            connection = open(url, method, headerKeys, headerValues, timeout);
            if (body != null && !body.isEmpty()
                    && (method.equals("POST") || method.equals("PUT") || method.equals("PATCH"))) {
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

            String responseBody = inputStream == null ? "" : readAll(inputStream);

            return "{\"status\":" + responseCode
                    + ",\"headers\":" + headersJson(connection.getHeaderFields())
                    + ",\"body\":\"" + escapeJson(responseBody)
                    + "\",\"success\":" + (responseCode >= 200 && responseCode < 300)
                    + "}";
        } catch (Exception e) {
            return failure(e.getMessage());
        } finally {
            if (connection != null) connection.disconnect();
        }
    }

    // ── Asynchronous variants ────────────────────────────────────────────────
    public static void executeAsync(String url, String method, String[] headerKeys,
                                    String[] headerValues, String body, double timeout,
                                    Callback callback) {
        executor.execute(() -> {
            String result = execute(url, method, headerKeys, headerValues, body, timeout);
            callback.onResult(result);
        });
    }

    // ── Streaming ─────────────────────────────────────────────────────────────
    // Chunks/complete/error are delivered from a DEDICATED SINGLE-THREAD
    // executor (not the general pool, not the Android main thread):
    //
    //  1. Streaming off the UI thread avoids jank.
    //  2. All stream events reach the Crystal dispatch funs
    //     (Java_com_nativecr_StreamCallback_* in network.cr) on one
    //     known thread, which those funs register with the Boehm GC on
    //     first call. Swapping this for a multi-thread executor would
    //     break that registration invariant.
    public static void executeStream(String url, String method, String[] headerKeys,
                                     String[] headerValues, StreamCallback callback,
                                     double timeout) {
        streamDispatcher.execute(() -> {
            HttpURLConnection connection = null;
            try {
                connection = open(url, method, headerKeys, headerValues, timeout);
                int responseCode = connection.getResponseCode();
                if (responseCode >= 200 && responseCode < 300) {
                    InputStream inputStream = connection.getInputStream();
                    byte[] buffer = new byte[8192];
                    int bytesRead;
                    while ((bytesRead = inputStream.read(buffer)) != -1) {
                        byte[] chunk = new byte[bytesRead];
                        System.arraycopy(buffer, 0, chunk, 0, bytesRead);
                        callback.onChunk(chunk);
                    }
                    inputStream.close();
                    callback.onComplete(responseCode);
                } else {
                    callback.onError(utf8("HTTP " + responseCode));
                }
            } catch (Exception e) {
                String message = e.getMessage();
                callback.onError(utf8(message == null ? "request failed" : message));
            } finally {
                if (connection != null) connection.disconnect();
            }
        });
    }

    private static final ExecutorService streamDispatcher = Executors.newSingleThreadExecutor();

    // ── Helpers ───────────────────────────────────────────────────────────────

    private static HttpURLConnection open(String url, String method, String[] headerKeys,
                                          String[] headerValues, double timeout) throws Exception {
        HttpURLConnection connection = (HttpURLConnection) new URL(url).openConnection();
        connection.setRequestMethod(method);
        connection.setConnectTimeout((int) (timeout * 1000));
        connection.setReadTimeout((int) (timeout * 1000));
        for (int i = 0; i < headerKeys.length && i < headerValues.length; i++) {
            if (headerKeys[i] != null && headerValues[i] != null) {
                connection.setRequestProperty(headerKeys[i], headerValues[i]);
            }
        }
        return connection;
    }

    private static String readAll(InputStream inputStream) throws Exception {
        java.io.ByteArrayOutputStream out = new java.io.ByteArrayOutputStream();
        byte[] buffer = new byte[8192];
        int bytesRead;
        while ((bytesRead = inputStream.read(buffer)) != -1) {
            out.write(buffer, 0, bytesRead);
        }
        return new String(out.toByteArray(), "UTF-8");
    }

    private static String headersJson(Map<String, List<String>> fields) {
        StringBuilder sb = new StringBuilder("{");
        boolean first = true;
        if (fields != null) {
            for (Map.Entry<String, List<String>> entry : fields.entrySet()) {
                String key = entry.getKey();
                if (key == null || entry.getValue().isEmpty()) continue;
                if (!first) sb.append(",");
                first = false;
                sb.append("\"").append(escapeJson(key)).append("\":\"")
                  .append(escapeJson(entry.getValue().get(0))).append("\"");
            }
        }
        sb.append("}");
        return sb.toString();
    }

    private static byte[] utf8(String s) {
        try {
            return s.getBytes("UTF-8");
        } catch (Exception e) {
            return new byte[0];
        }
    }

    private static String failure(String message) {
        return "{\"status\":0,\"headers\":{},\"body\":\"\",\"success\":false,\"error\":\""
                + escapeJson(message == null ? "request failed" : message) + "\"}";
    }

    private static String escapeJson(String s) {
        if (s == null) return "";
        StringBuilder sb = new StringBuilder();
        for (char c : s.toCharArray()) {
            switch (c) {
                case '"': sb.append("\\\""); break;
                case '\\': sb.append("\\\\"); break;
                case '\n': sb.append("\\n"); break;
                case '\r': sb.append("\\r"); break;
                case '\t': sb.append("\\t"); break;
                case '\b': sb.append("\\b"); break;
                case '\f': sb.append("\\f"); break;
                default:
                    if (c < 0x20) {
                        sb.append(String.format("\\u%04x", (int) c));
                    } else {
                        sb.append(c);
                    }
            }
        }
        return sb.toString();
    }
}
