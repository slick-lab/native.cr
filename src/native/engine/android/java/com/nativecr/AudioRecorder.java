// src/native/engine/android/java/com/nativecr/AudioRecorder.java

package com.nativecr;

import android.media.MediaRecorder;
import android.util.Log;

import java.io.File;
import java.io.IOException;

public class AudioRecorder {
    private MediaRecorder recorder;
    private String outputPath;
    private boolean isRecording = false;

    public AudioRecorder() {
    }

    public boolean start(String outputPath) {
        this.outputPath = outputPath;
        recorder = new MediaRecorder();
        recorder.setAudioSource(MediaRecorder.AudioSource.MIC);
        recorder.setOutputFormat(MediaRecorder.OutputFormat.THREE_GPP);
        recorder.setAudioEncoder(MediaRecorder.AudioEncoder.AMR_NB);
        recorder.setOutputFile(outputPath);

        try {
            recorder.prepare();
            recorder.start();
            isRecording = true;
            return true;
        } catch (IOException e) {
            Log.e("AudioRecorder", "Error starting recording: " + e.getMessage());
            return false;
        }
    }

    public byte[] stop() {
        if (recorder != null && isRecording) {
            try {
                recorder.stop();
                recorder.release();
                isRecording = false;
            } catch (Exception e) {
                Log.e("AudioRecorder", "Error stopping recording: " + e.getMessage());
            }
            recorder = null;

            File file = new File(outputPath);
            if (file.exists()) {
                return java.nio.file.Files.readAllBytes(file.toPath());
            }
        }
        return null;
    }

    public boolean isRecording() {
        return isRecording;
    }
}
