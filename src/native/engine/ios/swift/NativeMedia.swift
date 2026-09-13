// src/native/engine/ios/swift/NativeMedia.swift
//
// native.cr iOS runtime — media: sound effects, music, recorder, video, camera.
//
// Part of the LibIOS C ABI implementation (see ios_bindings.cr for the
// contract). AVFoundation-backed; every entry point is main-thread safe.

import AVFoundation
import UIKit

// ── Sound effects (AVAudioPlayer instances, overlapping playback) ────────────

final class NativeSound {
    let players: [AVAudioPlayer]
    private var idx = 0

    init?(path: String) {
        let url = Bundle.main.url(forResource: path, withExtension: nil)
            ?? URL(fileURLWithPath: path)
        guard let data = try? Data(contentsOf: url),
              let first = try? AVAudioPlayer(data: data) else { return nil }
        // Pool of players so overlapping plays don't cut each other off.
        var pool = [first]
        for _ in 0..<3 {
            if let p = try? AVAudioPlayer(data: data) { pool.append(p) }
        }
        players = pool
    }

    func play(volume: Float, loop: Bool, pitch: Float, pan: Float) -> AVAudioPlayer? {
        let p = players[idx % players.count]
        idx += 1
        p.volume = volume
        p.numberOfLoops = loop ? -1 : 0
        p.rate = max(0.5, min(2.0, pitch))
        p.pan = max(-1, min(1, pan))
        p.currentTime = 0
        p.prepareToPlay()
        p.play()
        return p
    }
}

var masterVolume: Float = 1.0
var sfxVolume: Float = 1.0
var musicVolumeLevel: Float = 1.0

@_cdecl("sound_load")
public func sound_load(_ path: UnsafePointer<UInt8>?) -> UnsafeMutableRawPointer? {
    guard let s = NativeSound(path: swiftStr(path)) else { return nil }
    return retainHandle(s)
}

@_cdecl("sound_play")
public func sound_play(_ sound: Int64, _ volume: Float, _ loop: Bool,
                       _ pitch: Float, _ pan: Float) -> UnsafeMutableRawPointer? {
    guard let s = resolve(sound, as: NativeSound.self),
          let instance = s.play(volume: volume * sfxVolume * masterVolume, loop: loop, pitch: pitch, pan: pan) else { return nil }
    return retainHandle(instance)
}

@_cdecl("sound_unload")
public func sound_unload(_ sound: Int64) {
    resolve(sound, as: NativeSound.self)?.players.forEach { $0.stop() }
}

@_cdecl("sound_stop_all")
public func sound_stop_all(_ sound: Int64) {
    resolve(sound, as: NativeSound.self)?.players.forEach { $0.stop() }
}

@_cdecl("sound_instance_stop")
public func sound_instance_stop(_ h: Int64) { resolve(h, as: AVAudioPlayer.self)?.stop() }

@_cdecl("sound_instance_pause")
public func sound_instance_pause(_ h: Int64) { resolve(h, as: AVAudioPlayer.self)?.pause() }

@_cdecl("sound_instance_resume")
public func sound_instance_resume(_ h: Int64) { resolve(h, as: AVAudioPlayer.self)?.play() }

@_cdecl("sound_instance_set_volume")
public func sound_instance_set_volume(_ h: Int64, _ v: Float) {
    resolve(h, as: AVAudioPlayer.self)?.volume = v * sfxVolume * masterVolume
}

@_cdecl("sound_instance_is_playing")
public func sound_instance_is_playing(_ h: Int64) -> Bool {
    resolve(h, as: AVAudioPlayer.self)?.isPlaying ?? false
}

@_cdecl("stop_all_sounds") public func stop_all_sounds() { /* per-sound handles own their players */ }
@_cdecl("pause_all_sounds") public func pause_all_sounds() { /* ditto */ }
@_cdecl("resume_all_sounds") public func resume_all_sounds() { /* ditto */ }

@_cdecl("set_master_volume") public func set_master_volume(_ v: Float) { masterVolume = v }
@_cdecl("set_sfx_volume") public func set_sfx_volume(_ v: Float) { sfxVolume = v }

// ── Music (single AVAudioPlayer) ─────────────────────────────────────────────

@_cdecl("music_load")
public func music_load(_ path: UnsafePointer<UInt8>?) -> UnsafeMutableRawPointer? {
    let p = swiftStr(path)
    let url = Bundle.main.url(forResource: p, withExtension: nil) ?? URL(fileURLWithPath: p)
    guard let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
    player.volume = musicVolumeLevel * masterVolume
    player.prepareToPlay()
    return retainHandle(player)
}

@_cdecl("music_play")
public func music_play(_ h: Int64, _ loop: Bool) {
    guard let m = resolve(h, as: AVAudioPlayer.self) else { return }
    m.numberOfLoops = loop ? -1 : 0
    m.play()
}

@_cdecl("music_pause") public func music_pause(_ h: Int64) { resolve(h, as: AVAudioPlayer.self)?.pause() }
@_cdecl("music_resume") public func music_resume(_ h: Int64) { resolve(h, as: AVAudioPlayer.self)?.play() }
@_cdecl("music_stop") public func music_stop(_ h: Int64) {
    guard let m = resolve(h, as: AVAudioPlayer.self) else { return }
    m.stop(); m.currentTime = 0
}
@_cdecl("music_unload") public func music_unload(_ h: Int64) { resolve(h, as: AVAudioPlayer.self)?.stop() }
@_cdecl("music_seek") public func music_seek(_ h: Int64, _ position: Double) { resolve(h, as: AVAudioPlayer.self)?.currentTime = position }
@_cdecl("music_get_position") public func music_get_position(_ h: Int64) -> Double { resolve(h, as: AVAudioPlayer.self)?.currentTime ?? 0 }
@_cdecl("music_get_duration") public func music_get_duration(_ h: Int64) -> Double { resolve(h, as: AVAudioPlayer.self)?.duration ?? 0 }
@_cdecl("music_set_volume") public func music_set_volume(_ h: Int64, _ v: Float) { resolve(h, as: AVAudioPlayer.self)?.volume = v * masterVolume }
@_cdecl("stop_music") public func stop_music() { }
@_cdecl("pause_music") public func pause_music() { }
@_cdecl("resume_music") public func resume_music() { }
@_cdecl("set_music_volume") public func set_music_volume(_ v: Float) { musicVolumeLevel = v }

// ── Recorder (AVAudioRecorder → WAV data) ────────────────────────────────────

final class NativeRecorder: AVAudioRecorderDelegate {
    var recorder: AVAudioRecorder?
    var lastData: Data?

    func start() -> Bool {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord)
        try? session.setActive(true)
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("nativecr_rec_\(Int(Date().timeIntervalSince1970)).m4a")
        guard let r = try? AVAudioRecorder(url: url, settings: [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]) else { return false }
        r.delegate = self
        r.record()
        recorder = r
        return true
    }

    func stop() -> (UnsafeMutablePointer<UInt8>?, UnsafeMutablePointer<Int32>?) {
        recorder?.stop()
        recorder = nil
        let data = lastData ?? Data()
        let buf = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
        data.copyBytes(to: buf, count: data.count)
        let sizePtr = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        sizePtr.pointee = Int32(data.count)
        return (buf, sizePtr)
    }
}

@_cdecl("recorder_start")
public func recorder_start() -> UnsafeMutableRawPointer? {
    let r = NativeRecorder()
    return r.start() ? retainHandle(r) : nil
}

@_cdecl("recorder_stop")
public func recorder_stop(_ h: Int64, _ sizePtr: UnsafeMutablePointer<Int32>?) -> UnsafeMutablePointer<UInt8>? {
    guard let r = resolve(h, as: NativeRecorder.self) else { return nil }
    let (buf, size) = r.stop()
    sizePtr?.pointee = size?.pointee ?? 0
    return buf
}

// ── Video (AVPlayer inside a UIView) ─────────────────────────────────────────

final class NativeVideoView: UIView {
    let player = AVPlayer()
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    override class var layerClass: AnyClass { AVPlayerLayer.self }
}

@_cdecl("create_video_player")
public func create_video_player() -> UnsafeMutableRawPointer? { onMain { retainHandle(NativeVideoView()) } }

@_cdecl("video_player_load")
public func video_player_load(_ h: Int64, _ path: UnsafePointer<UInt8>?) {
    let p = swiftStr(path)
    onMain {
        guard let v = resolve(h, as: NativeVideoView.self) else { return }
        let url = URL(string: p) ?? URL(fileURLWithPath: p)
        v.player = AVPlayer(url: url)
    }
}
@_cdecl("video_player_play") public func video_player_play(_ h: Int64) { resolve(h, as: NativeVideoView.self)?.player?.play() }
@_cdecl("video_player_pause") public func video_player_pause(_ h: Int64) { resolve(h, as: NativeVideoView.self)?.player?.pause() }
@_cdecl("video_player_stop") public func video_player_stop(_ h: Int64) {
    guard let v = resolve(h, as: NativeVideoView.self) else { return }
    v.player?.pause(); v.player?.seek(to: .zero)
}
@_cdecl("video_player_seek_to") public func video_player_seek_to(_ h: Int64, _ seconds: Int32) {
    resolve(h, as: NativeVideoView.self)?.player?.seek(to: CMTime(seconds: Double(seconds), preferredTimescale: 600))
}
@_cdecl("video_player_set_looping") public func video_player_set_looping(_ h: Int64, _ loop: Bool) {
    guard let v = resolve(h, as: NativeVideoView.self), let p = v.player else { return }
    if loop {
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: p.currentItem, queue: .main) { _ in
            p.seek(to: .zero); p.play()
        }
    }
}
@_cdecl("video_player_set_volume") public func video_player_set_volume(_ h: Int64, _ vol: Float) { resolve(h, as: NativeVideoView.self)?.player?.volume = vol }
@_cdecl("video_player_set_scale_type") public func video_player_set_scale_type(_ h: Int64, _ t: Int32) {
    onMain {
        guard let v = resolve(h, as: NativeVideoView.self) else { return }
        v.playerLayer.videoGravity = t == 1 ? .resizeAspect : (t == 2 ? .resizeAspectFill : .resize)
    }
}
@_cdecl("video_player_current_position") public func video_player_current_position(_ h: Int64) -> Int32 {
    guard let v = resolve(h, as: NativeVideoView.self) else { return 0 }
    return Int32(v.player?.currentTime().seconds ?? 0)
}
@_cdecl("video_player_duration") public func video_player_duration(_ h: Int64) -> Int32 {
    guard let v = resolve(h, as: NativeVideoView.self),
          let d = v.player?.currentItem?.duration.seconds, d.isFinite else { return 0 }
    return Int32(d)
}

// ── Camera (AVCaptureSession preview) ────────────────────────────────────────

final class NativeCameraView: UIView {
    let session = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer?
    var frontFacing = false
    var flashMode: Int32 = 0
}

@_cdecl("create_camera_controller")
public func create_camera_controller() -> UnsafeMutableRawPointer? {
    onMain {
        let v = NativeCameraView()
        AVCaptureDevice.requestAccess(for: .video) { granted in
            guard granted else { return }
            onMain { v.startPreview() }
        }
        return retainHandle(v)
    }
}

extension NativeCameraView {
    func startPreview() {
        guard previewLayer == nil else { return }
        session.beginConfiguration()
        session.sessionPreset = .high
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: frontFacing ? .front : .back),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
        }
        session.commitConfiguration()
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.frame = bounds
        layer.videoGravity = .resizeAspectFill
        self.layer.addSublayer(layer)
        previewLayer = layer
        DispatchQueue.global(qos: .userInitiated).async { self.session.startRunning() }
    }

    func switchCamera() {
        frontFacing.toggle()
        session.beginConfiguration()
        session.inputs.forEach { session.removeInput($0) }
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: frontFacing ? .front : .back),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
        }
        session.commitConfiguration()
    }
}

@_cdecl("camera_start_preview") public func camera_start_preview(_ h: Int64) { onMain { (resolve(h, as: NativeCameraView.self))?.startPreview() } }
@_cdecl("camera_stop_preview") public func camera_stop_preview(_ h: Int64) {
    onMain {
        guard let c = resolve(h, as: NativeCameraView.self) else { return }
        DispatchQueue.global(qos: .userInitiated).async { c.session.stopRunning() }
    }
}
@_cdecl("camera_set_facing") public func camera_set_facing(_ h: Int64, _ facing: Int32) {
    onMain {
        guard let c = resolve(h, as: NativeCameraView.self) else { return }
        let wantFront = facing == 1
        if wantFront != c.frontFacing { c.switchCamera() }
    }
}
@_cdecl("camera_set_flash_mode") public func camera_set_flash_mode(_ h: Int64, _ mode: Int32) {
    (resolve(h, as: NativeCameraView.self))?.flashMode = mode
}
@_cdecl("camera_start_recording") public func camera_start_recording(_ h: Int64) {
    // Video recording lands with the capture pipeline (needs movie output wiring).
}
@_cdecl("camera_stop_recording") public func camera_stop_recording(_ h: Int64) { }
@_cdecl("camera_take_photo") public func camera_take_photo(_ h: Int64) {
    // Still capture lands with the capture pipeline (needs photo output wiring);
    // requires a callback channel to deliver the image to Crystal.
}
