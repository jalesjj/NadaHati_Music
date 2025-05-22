# NadaHati_Music 🎵

A Flutter application that recommends music based on your current mood using Spotify API.

## Features ✨

- **Mood-Based Recommendations**: Get personalized playlists based on 8 different moods
- **Spotify Integration**: Full OAuth authentication and API integration
- **Playlist Creation**: Automatically create and save playlists to your Spotify account
- **Music History**: Track your listening patterns and mood history
- **Analytics Dashboard**: View insights about your musical preferences
- **Beautiful UI**: Modern Material Design 3 interface

## Moods Available 😊

- 😊 **Happy** - Uplifting and joyful vibes
- ⚡ **Energetic** - High-energy and motivating beats
- 😌 **Chill** - Relaxed and laid-back sounds
- 🎯 **Focus** - Concentration and productivity music
- 😢 **Sad** - Melancholic and emotional tunes
- ❤️ **Romantic** - Love songs and romantic melodies
- 😠 **Angry** - Intense and aggressive music
- 🎉 **Party** - Dance and celebration hits

## Screenshots

[Add screenshots here when you build the app]

## Setup Instructions 🚀

### Prerequisites

- Flutter SDK (3.0.0 or later)
- Dart SDK
- Android Studio / VS Code
- Spotify Developer Account

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/mood_tunes.git
cd mood_tunes
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Spotify API Setup

1. Go to [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
2. Create a new app
3. Note down your `Client ID` and `Client Secret`
4. Add redirect URI: `myapp://callback`
5. Enable the following scopes:
   - `user-read-private`
   - `user-read-email`
   - `playlist-read-private`
   - `playlist-modify-public`
   - `playlist-modify-private`
   - `user-top-read`
   - `user-read-recently-played`
   - `user-library-read`

### 4. Configure API Credentials

Open `lib/services/spotify_service.dart` and update:

```dart
static const String clientId = 'YOUR_SPOTIFY_CLIENT_ID';
static const String clientSecret = 'YOUR_SPOTIFY_CLIENT_SECRET';
```

### 5. Android Configuration

In `android/app/src/main/AndroidManifest.xml`, add:

```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTop"
    android:theme="@style/LaunchTheme"
    android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
    android:hardwareAccelerated="true"
    android:windowSoftInputMode="adjustResize">
    
    <!-- Standard App Intent -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>
    
    <!-- Spotify OAuth Callback -->
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="myapp" />
    </intent-filter>
</activity>
```

### 6. iOS Configuration

In `ios/Runner/Info.plist`, add:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>myapp.auth</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>myapp</string>
        </array>
    </dict>
</array>
```

### 7. Run the App

```bash
flutter run
```

## Architecture 🏗️

### Project Structure

```
lib/
├── main.dart                   # App entry point
├── models/                     # Data models
│   └── spotify_models.dart    # Spotify API models
├── providers/                  # State management
│   └── app_state.dart         # Main app state
├── services/                   # API services
│   └── spotify_service.dart   # Spotify API integration
├── screens/                    # App screens
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── mood_selection_screen.dart
│   ├── recommendations_screen.dart
│   ├── history_screen.dart
│   └── profile_screen.dart
└── widgets/                    # Reusable widgets
    ├── mood_card.dart
    ├── track_card.dart
    └── loading_widget.dart
```

### State Management

The app uses **Provider** for state management with a single `AppState` class that handles:

- User authentication
- Spotify API calls
- Mood selection and recommendations
- History tracking
- Error handling

### Data Storage

- **SharedPreferences**: For storing authentication tokens and mood history
- **Spotify API**: For all music data and user information
- **Local Storage**: For mood analytics and session tracking

## Key Features Implementation 🔧

### Mood-Based Recommendations

The app maps each mood to specific Spotify audio features:

```dart
Map<String, dynamic> _getMoodAudioFeatures(Mood mood) {
  switch (mood) {
    case Mood.happy:
      return {
        'target_valence': 0.8,      // Positivity
        'target_energy': 0.7,       // Energy level
        'target_danceability': 0.7, // Danceability
        'min_tempo': 120,
        'max_tempo': 140,
      };
    // ... other moods
  }
}
```

### Authentication Flow

1. User taps "Connect with Spotify"
2. App redirects to Spotify OAuth
3. User grants permissions
4. App receives authorization code
5. Code is exchanged for access token
6. Token is stored locally for future use

### Playlist Creation

1. User selects mood
2. App gets recommendations from Spotify
3. User can create playlist
4. App creates playlist on Spotify
5. Tracks are added to playlist
6. Session is saved to history

## Customization 🎨

### Adding New Moods

1. Add new mood to `Mood` enum in `spotify_models.dart`
2. Add audio features mapping in `_getMoodAudioFeatures()`
3. Update UI to display new mood

### Changing Theme

Modify theme in `main.dart`:

```dart
theme: ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF1DB954), // Change this color
    brightness: Brightness.light,
  ),
  // ... other theme properties
),
```

## API Usage & Limits 📊

### Spotify API Endpoints Used

- `/me` - User profile
- `/me/top/artists` - User's top artists (for seed data)
- `/recommendations` - Get recommendations
- `/me/playlists` - User's playlists
- `/users/{user_id}/playlists` - Create playlist
- `/playlists/{playlist_id}/tracks` - Add tracks to playlist
- `/search` - Search tracks
- `/me/player/recently-played` - Recently played tracks

### Rate Limits

- Spotify API has rate limits (usually 100 requests per minute)
- App implements error handling for rate limit responses
- Consider caching recommendations to reduce API calls

## Troubleshooting 🔧

### Common Issues

1. **OAuth Callback Not Working**
   - Check redirect URI in Spotify Dashboard matches `myapp://callback`
   - Verify AndroidManifest.xml / Info.plist configuration

2. **API Calls Failing**
   - Verify Client ID and Client Secret are correct
   - Check internet connection
   - Ensure Spotify account has necessary permissions

3. **Build Errors**
   - Run `flutter clean` and `flutter pub get`
   - Check Flutter and Dart SDK versions
   - Verify all dependencies are compatible

### Debug Mode

Enable debug logging by modifying `spotify_service.dart`:

```dart
// Add logging to see API requests/responses
print('API Request: $url');
print('Response: ${response.data}');
```

## Contributing 🤝

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## License 📄

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments 🙏

- [Spotify Web API](https://developer.spotify.com/documentation/web-api/) for music data
- [Flutter](https://flutter.dev/) for the awesome framework
- [Material Design 3](https://m3.material.io/) for design guidelines
- [Provider](https://pub.dev/packages/provider) for state management

## Roadmap 🗺️

### Upcoming Features

- [ ] Audio preview playback
- [ ] Social sharing of playlists
- [ ] Machine learning for better recommendations
- [ ] Offline mode with cached recommendations
- [ ] Custom mood creation
- [ ] Integration with other music services
- [ ] Voice mood detection
- [ ] Collaborative playlists
- [ ] Music discovery challenges
- [ ] Advanced analytics and insights

### Version History

- **v1.0.0** - Initial release with core mood-based recommendations
- **v1.1.0** - (Planned) Audio preview and enhanced UI
- **v1.2.0** - (Planned) Social features and sharing
- **v2.0.0** - (Planned) ML-powered recommendations

---

Made with ❤️ and Flutter

For support or questions, please open an issue on GitHub.
