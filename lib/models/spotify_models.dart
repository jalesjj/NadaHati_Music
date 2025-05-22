// Mood enum
enum Mood {
  happy('Happy', '😊', 'Uplifting and joyful vibes'),
  sad('Sad', '😢', 'Melancholic and emotional tunes'),
  energetic('Energetic', '⚡', 'High-energy and motivating beats'),
  chill('Chill', '😌', 'Relaxed and laid-back sounds'),
  romantic('Romantic', '❤️', 'Love songs and romantic melodies'),
  angry('Angry', '😠', 'Intense and aggressive music'),
  focus('Focus', '🎯', 'Concentration and productivity music'),
  party('Party', '🎉', 'Dance and celebration hits');

  const Mood(this.label, this.emoji, this.description);
  final String label;
  final String emoji;
  final String description;
}

// Spotify User model
class SpotifyUser {
  final String id;
  final String displayName;
  final String email;
  final String? imageUrl;
  final int followers;

  SpotifyUser({
    required this.id,
    required this.displayName,
    required this.email,
    this.imageUrl,
    required this.followers,
  });

  factory SpotifyUser.fromJson(Map<String, dynamic> json) {
    return SpotifyUser(
      id: json['id'] ?? '',
      displayName: json['display_name'] ?? '',
      email: json['email'] ?? '',
      imageUrl: json['images'] != null && (json['images'] as List).isNotEmpty
          ? json['images'][0]['url']
          : null,
      followers: json['followers']?['total'] ?? 0,
    );
  }
}

// Spotify Artist model
class SpotifyArtist {
  final String id;
  final String name;
  final String? imageUrl;
  final List<String> genres;

  SpotifyArtist({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.genres,
  });

  factory SpotifyArtist.fromJson(Map<String, dynamic> json) {
    return SpotifyArtist(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['images'] != null && (json['images'] as List).isNotEmpty
          ? json['images'][0]['url']
          : null,
      genres: List<String>.from(json['genres'] ?? []),
    );
  }
}

// Spotify Album model
class SpotifyAlbum {
  final String id;
  final String name;
  final String? imageUrl;
  final String releaseDate;
  final List<SpotifyArtist> artists;

  SpotifyAlbum({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.releaseDate,
    required this.artists,
  });

  factory SpotifyAlbum.fromJson(Map<String, dynamic> json) {
    return SpotifyAlbum(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['images'] != null && (json['images'] as List).isNotEmpty
          ? json['images'][0]['url']
          : null,
      releaseDate: json['release_date'] ?? '',
      artists: (json['artists'] as List? ?? [])
          .map((artist) => SpotifyArtist.fromJson(artist))
          .toList(),
    );
  }
}

// Spotify Track model
class SpotifyTrack {
  final String id;
  final String name;
  final List<SpotifyArtist> artists;
  final SpotifyAlbum album;
  final int durationMs;
  final String? previewUrl;
  final bool explicit;
  final int popularity;
  final String uri;

  SpotifyTrack({
    required this.id,
    required this.name,
    required this.artists,
    required this.album,
    required this.durationMs,
    this.previewUrl,
    required this.explicit,
    required this.popularity,
    required this.uri,
  });

  factory SpotifyTrack.fromJson(Map<String, dynamic> json) {
    return SpotifyTrack(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      artists: (json['artists'] as List? ?? [])
          .map((artist) => SpotifyArtist.fromJson(artist))
          .toList(),
      album: SpotifyAlbum.fromJson(json['album'] ?? {}),
      durationMs: json['duration_ms'] ?? 0,
      previewUrl: json['preview_url'],
      explicit: json['explicit'] ?? false,
      popularity: json['popularity'] ?? 0,
      uri: json['uri'] ?? '',
    );
  }

  String get artistNames => artists.map((a) => a.name).join(', ');
  
  String get formattedDuration {
    final minutes = durationMs ~/ 60000;
    final seconds = (durationMs % 60000) ~/ 1000;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

// Spotify Playlist model
class SpotifyPlaylist {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final int trackCount;
  final bool public;
  final String uri;

  SpotifyPlaylist({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.trackCount,
    required this.public,
    required this.uri,
  });

  factory SpotifyPlaylist.fromJson(Map<String, dynamic> json) {
    return SpotifyPlaylist(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['images'] != null && (json['images'] as List).isNotEmpty
          ? json['images'][0]['url']
          : null,
      trackCount: json['tracks']?['total'] ?? 0,
      public: json['public'] ?? false,
      uri: json['uri'] ?? '',
    );
  }
}

// Mood History model for local storage
class MoodHistory {
  final String id;
  final Mood mood;
  final DateTime timestamp;
  final List<String> trackIds;
  final String? playlistId;

  MoodHistory({
    required this.id,
    required this.mood,
    required this.timestamp,
    required this.trackIds,
    this.playlistId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mood': mood.name,
      'timestamp': timestamp.toIso8601String(),
      'trackIds': trackIds,
      'playlistId': playlistId,
    };
  }

  factory MoodHistory.fromJson(Map<String, dynamic> json) {
    return MoodHistory(
      id: json['id'],
      mood: Mood.values.firstWhere((m) => m.name == json['mood']),
      timestamp: DateTime.parse(json['timestamp']),
      trackIds: List<String>.from(json['trackIds']),
      playlistId: json['playlistId'],
    );
  }
}

// Audio Features model
class AudioFeatures {
  final String id;
  final double acousticness;
  final double danceability;
  final double energy;
  final double instrumentalness;
  final double liveness;
  final double loudness;
  final double speechiness;
  final double tempo;
  final double valence;

  AudioFeatures({
    required this.id,
    required this.acousticness,
    required this.danceability,
    required this.energy,
    required this.instrumentalness,
    required this.liveness,
    required this.loudness,
    required this.speechiness,
    required this.tempo,
    required this.valence,
  });

  factory AudioFeatures.fromJson(Map<String, dynamic> json) {
    return AudioFeatures(
      id: json['id'] ?? '',
      acousticness: (json['acousticness'] ?? 0.0).toDouble(),
      danceability: (json['danceability'] ?? 0.0).toDouble(),
      energy: (json['energy'] ?? 0.0).toDouble(),
      instrumentalness: (json['instrumentalness'] ?? 0.0).toDouble(),
      liveness: (json['liveness'] ?? 0.0).toDouble(),
      loudness: (json['loudness'] ?? 0.0).toDouble(),
      speechiness: (json['speechiness'] ?? 0.0).toDouble(),
      tempo: (json['tempo'] ?? 0.0).toDouble(),
      valence: (json['valence'] ?? 0.0).toDouble(),
    );
  }
}