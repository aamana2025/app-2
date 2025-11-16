# YouTube Player Integration

This document explains how YouTube videos are integrated into the Mansa Flutter app.

## Overview

The app now uses the `youtube_player_flutter` plugin to provide an in-app video viewing experience instead of opening videos in external browsers.

## Features

### 1. In-App Video Player
- Videos play directly within the app using the `YoutubePlayerWidget`
- No need to leave the app to watch videos
- Customizable player controls and appearance

### 2. Fullscreen Support
- Tap the fullscreen button to watch videos in fullscreen mode
- Fullscreen player includes video title and close button
- Maintains video quality and controls

### 3. Error Handling
- Graceful handling of invalid or missing video IDs
- User-friendly error messages in Arabic
- Fallback UI when videos are unavailable

## Implementation

### Files Added/Modified

1. **`lib/widgets/youtube_player_widget.dart`** - New YouTube player widget
2. **`lib/screens/classroom_screen.dart`** - Updated to use in-app player
3. **`pubspec.yaml`** - Added `youtube_player_flutter: ^8.1.2` dependency

### Widget Usage

```dart
// Basic usage
YoutubePlayerWidget(
  videoId: 'dQw4w9WgXcQ', // YouTube video ID
  title: 'Video Title',
  autoPlay: false,
  showControls: true,
  aspectRatio: 16 / 9,
)

// Fullscreen player
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => YoutubePlayerFullscreen(
      videoId: 'dQw4w9WgXcQ',
      title: 'Video Title',
    ),
  ),
)
```

### API Integration

The app expects video data from the API with the following structure:

```json
{
  "videos": [
    {
      "videoId": "dQw4w9WgXcQ",
      "title": "Video Title",
      "description": "Video Description",
      "uploadedAt": "2024-01-01T00:00:00Z"
    }
  ]
}
```

The API service automatically extracts YouTube video IDs from various URL formats:
- `https://www.youtube.com/watch?v=VIDEO_ID`
- `https://youtu.be/VIDEO_ID`
- Direct video ID in the `videoId` field

## Configuration

### Player Settings

The YouTube player is configured with the following settings:

- **Auto-play**: Disabled by default
- **Mute**: Disabled
- **HD Quality**: Enabled
- **Captions**: Enabled
- **Controls**: Visible
- **Related Videos**: Disabled (rel=0)
- **YouTube Branding**: Minimal (modestbranding=1)

### Customization

You can customize the player by modifying the `YoutubePlayerFlags` in the widget:

```dart
YoutubePlayerFlags(
  autoPlay: true,           // Auto-play videos
  mute: true,              // Start muted
  isLive: false,           // Not a live stream
  forceHD: true,           // Force HD quality
  enableCaption: true,     // Enable captions
  hideControls: false,     // Show controls
  controlsVisibleAtStart: true, // Show controls initially
  useHybridComposition: true,   // Better performance on Android
)
```

## Troubleshooting

### Common Issues

1. **Video not loading**: Check if the video ID is valid and the video is publicly available
2. **Black screen**: Ensure the video ID is correct and not empty
3. **Performance issues**: The `useHybridComposition` flag is enabled for better Android performance

### Error Messages

- **"فيديو غير متوفر"** - Video not available (shown when videoId is empty)
- **"فيديو غير متوفر"** - Video not available (shown in fullscreen when videoId is empty)

## Dependencies

- `youtube_player_flutter: ^8.1.2` - Main YouTube player plugin
- `flutter` - Flutter framework
- `provider` - State management (for auth tokens)

## Future Enhancements

Potential improvements for the YouTube integration:

1. **Playlist Support**: Add support for YouTube playlists
2. **Video Quality Selection**: Allow users to choose video quality
3. **Offline Support**: Cache video thumbnails and metadata
4. **Analytics**: Track video viewing statistics
5. **Comments Integration**: Show YouTube comments (if needed)
6. **Subtitle Support**: Better subtitle/caption handling
