// src/native/engine/android/java/com/nativecr/VideoPlayer.java

package com.nativecr;

import android.net.Uri;
import android.widget.VideoView;
import android.widget.MediaController;
import android.app.Activity;

public class VideoPlayer {
    private VideoView videoView;
    private Activity activity;

    public VideoPlayer(Activity activity) {
        this.activity = activity;
        this.videoView = new VideoView(activity);
    }

    public void load(String path) {
        Uri uri = Uri.parse(path);
        videoView.setVideoURI(uri);
        MediaController mediaController = new MediaController(activity);
        mediaController.setAnchorView(videoView);
        videoView.setMediaController(mediaController);
    }

    public void play() {
        videoView.start();
    }

    public void pause() {
        videoView.pause();
    }

    public void stop() {
        videoView.stopPlayback();
    }

    public void seekTo(int msec) {
        videoView.seekTo(msec);
    }

    public int getCurrentPosition() {
        return videoView.getCurrentPosition();
    }

    public int getDuration() {
        return videoView.getDuration();
    }

    public void setLooping(boolean loop) {
        if (loop) {
            videoView.setOnCompletionListener(mp -> videoView.start());
        }
    }

    public void setVolume(float volume) {
        // VideoView doesn't support volume directly
    }

    public VideoView getView() {
        return videoView;
    }
}
