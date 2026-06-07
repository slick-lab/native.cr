---
title: Audio
---

# Audio

Sound is essential for immersive mobile experiences. Apps use audio for music, sound effects, voice messages, and alerts. Native.cr provides a complete audio engine that handles playback, recording, volume control, and audio routing.

## Audio Concepts

Mobile devices have different audio contexts. When a user receives a call, plays music, or enables vibration mode, the audio system behaves differently. Native.cr abstracts these details so your audio works correctly in all situations.

Audio files can be stored as app resources or downloaded from the network. Common formats are MP3, WAV, and OGG. All modern phones support these formats natively.

## Playing Sound Effects

Sound effects are short, repeatable sounds triggered by user actions. Playing a sound effect is simple:

```crystal
Native::Audio.play_effect("button_click.mp3")
```

Sound effects play immediately at full volume (unless you've changed the volume). Multiple effects can play simultaneously—they mix automatically.

## Playing Music

Music is longer audio that plays in the background. Unlike effects, only one music track plays at a time. Starting a new music track stops the previous one.

```crystal
Native::Audio.play_music("background_track.mp3")
Native::Audio.stop_music
Native::Audio.pause_music
Native::Audio.resume_music
```

## Volume Control

Apps have separate volume controls for music and effects. This lets users mute effects but keep music, for example.

```crystal
# Get current volume (0.0 to 1.0)
music_vol = Native::Audio.music_volume
effect_vol = Native::Audio.sfx_volume

# Set volume
Native::Audio.music_volume = 0.8
Native::Audio.sfx_volume = 0.5
```

You can also control the master volume which affects both:

```crystal
Native::Audio.master_volume = 0.7
```

## Recording Audio

Record audio for voice messages, notes, or audio memos:

```crystal
Native::Audio.start_recording("memo.mp3")

# Record for a while...
sleep 10.seconds

Native::Audio.stop_recording
```

The recorded file is saved at the path you specify in your app's storage directory.

## Audio Properties

Get information about currently playing audio:

```crystal
duration = Native::Audio.duration("track.mp3")      # In seconds
playing = Native::Audio.is_playing?("track.mp3")
current = Native::Audio.current_position              # Current playback position
```

## Audio Callbacks

Execute code when audio finishes playing:

```crystal
Native::Audio.on_music_finished do
  puts "Music finished"
  # Play next track
  Native::Audio.play_music("next_track.mp3")
end

Native::Audio.on_effect_finished("effect.mp3") do
  puts "Effect finished playing"
end
```

## Audio Routing

Control which speaker audio comes from. On mobile devices, audio can come from the device speaker, earpiece, or headphones.

```crystal
# Force speaker output (ignore earpiece)
Native::Audio.route = Native::Audio::Route::Speaker

# Use the default route
Native::Audio.route = Native::Audio::Route::Default

# Play through ear speaker
Native::Audio.route = Native::Audio::Route::Earpiece
```

The system automatically switches routing if the user plugs in headphones.

## Audio Categories

Tell the system what kind of audio your app plays. This affects how the phone handles volume buttons and silent mode.

```crystal
# For music or entertainment
Native::Audio.category = Native::Audio::Category::Music

# For games
Native::Audio.category = Native::Audio::Category::Game

# For voice chat or calls
Native::Audio.category = Native::Audio::Category::Voice
```

## Audio Ducking

When another app (like a call or navigation) needs to play audio, your app's audio can automatically reduce volume. This is called ducking.

```crystal
# Enable ducking (other apps reduce your volume)
Native::Audio.ducking_enabled = true

# Disable ducking
Native::Audio.ducking_enabled = false
```

## Best Practices

- Use WAV or OGG for sound effects (smaller, faster to load)
- Use MP3 for music (good compression)
- Keep effect files under 1MB for instant playback
- Always provide a mute button to respect user preferences
- Handle audio routes when headphones are plugged in
- Release audio resources when your app pauses to save battery
- Test audio with volume buttons, silent mode, and headphones
