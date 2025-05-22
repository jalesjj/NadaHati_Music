import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/spotify_models.dart';

class SpotifyService {
  static const String clientId = 'client_id';
  static const String clientSecret = 'secret_client_id';
  static const String redirectUri = 'myapp://callback';
  static const String baseUrl = 'https://api.spotify.com/v1';
  static const String authUrl = 'https://accounts.spotify.com/authorize';
  static const String tokenUrl = 'https://accounts.spotify.com/api/token';
  
  final Dio _dio = Dio();
  String? _accessToken;
  
  // Singleton pattern
  static final SpotifyService _instance = SpotifyService._internal();
  factory SpotifyService() => _instance;
  SpotifyService._internal();

  // OAuth Flow
  Future<void> authenticate() async {
    final String scopes = [
      'user-read-private',
      'user-read-email',
      'playlist-read-private',
      'playlist-modify-public',
      'playlist-modify-private',
      'user-top-read',
      'user-read-recently-played',
      'user-library-read'
    ].join(' ');
    
    final String authEndpoint = '$authUrl?'
        'client_id=$clientId&'
        'response_type=code&'
        'redirect_uri=${Uri.encodeComponent(redirectUri)}&'
        'scope=${Uri.encodeComponent(scopes)}&'
        'show_dialog=true';
    
    if (await canLaunchUrl(Uri.parse(authEndpoint))) {
      await launchUrl(Uri.parse(authEndpoint));
    }
  }
  
  // Handle OAuth callback and exchange code for token
  Future<bool> handleCallback(String code) async {
    try {
      final response = await _dio.post(
        tokenUrl,
        data: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': redirectUri,
          'client_id': clientId,
          'client_secret': clientSecret,
        },
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );
      
      _accessToken = response.data['access_token'];
      await _saveToken(_accessToken!);
      _setupDioInterceptors();
      return true;
    } catch (e) {
      print('Error getting token: $e');
      return false;
    }
  }
  
  // Save token to local storage
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('spotify_token', token);
  }
  
  // Load saved token
  Future<bool> loadSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('spotify_token');
    if (_accessToken != null) {
      _setupDioInterceptors();
      return true;
    }
    return false;
  }
  
  // Setup Dio interceptors for authentication
  void _setupDioInterceptors() {
    _dio.interceptors.clear();
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            // Token expired, need to re-authenticate
            _accessToken = null;
          }
          handler.next(error);
        },
      ),
    );
  }
  
  bool get isAuthenticated => _accessToken != null;
  
  // Get user profile
  Future<SpotifyUser?> getUserProfile() async {
    try {
      final response = await _dio.get('$baseUrl/me');
      return SpotifyUser.fromJson(response.data);
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }
  
  // Get recommendations based on mood
  Future<List<SpotifyTrack>> getRecommendationsByMood(Mood mood) async {
    try {
      final moodFeatures = _getMoodAudioFeatures(mood);
      
      // Get user's top artists for seed
      final topArtistsResponse = await _dio.get(
        '$baseUrl/me/top/artists',
        queryParameters: {'limit': 5, 'time_range': 'medium_term'},
      );
      
      final seedArtists = (topArtistsResponse.data['items'] as List)
          .map((item) => item['id'] as String)
          .take(2)
          .join(',');
      
      // Get recommendations
      final response = await _dio.get(
        '$baseUrl/recommendations',
        queryParameters: {
          'seed_artists': seedArtists,
          'limit': 20,
          ...moodFeatures,
        },
      );
      
      return (response.data['tracks'] as List)
          .map((track) => SpotifyTrack.fromJson(track))
          .toList();
    } catch (e) {
      print('Error getting recommendations: $e');
      return [];
    }
  }
  
  // Convert mood to audio features
  Map<String, dynamic> _getMoodAudioFeatures(Mood mood) {
    switch (mood) {
      case Mood.happy:
        return {
          'target_valence': 0.8,
          'target_energy': 0.7,
          'target_danceability': 0.7,
          'min_tempo': 120,
          'max_tempo': 140,
        };
      case Mood.sad:
        return {
          'target_valence': 0.2,
          'target_energy': 0.3,
          'target_acousticness': 0.7,
          'min_tempo': 60,
          'max_tempo': 100,
        };
      case Mood.energetic:
        return {
          'target_valence': 0.7,
          'target_energy': 0.9,
          'target_danceability': 0.8,
          'min_tempo': 130,
          'max_tempo': 180,
        };
      case Mood.chill:
        return {
          'target_valence': 0.5,
          'target_energy': 0.4,
          'target_acousticness': 0.6,
          'min_tempo': 80,
          'max_tempo': 110,
        };
      case Mood.romantic:
        return {
          'target_valence': 0.6,
          'target_energy': 0.4,
          'target_acousticness': 0.5,
          'target_instrumentalness': 0.3,
          'min_tempo': 70,
          'max_tempo': 120,
        };
      case Mood.angry:
        return {
          'target_valence': 0.3,
          'target_energy': 0.8,
          'target_loudness': -5,
          'min_tempo': 140,
          'max_tempo': 200,
        };
      case Mood.focus:
        return {
          'target_valence': 0.5,
          'target_energy': 0.5,
          'target_instrumentalness': 0.7,
          'target_acousticness': 0.4,
          'min_tempo': 90,
          'max_tempo': 130,
        };
      case Mood.party:
        return {
          'target_valence': 0.8,
          'target_energy': 0.9,
          'target_danceability': 0.9,
          'min_tempo': 120,
          'max_tempo': 140,
        };
    }
  }
  
  // Create playlist
  Future<SpotifyPlaylist?> createPlaylist(String name, String description, List<String> trackUris) async {
    try {
      final user = await getUserProfile();
      if (user == null) return null;
      
      // Create playlist
      final createResponse = await _dio.post(
        '$baseUrl/users/${user.id}/playlists',
        data: {
          'name': name,
          'description': description,
          'public': false,
        },
      );
      
      final playlist = SpotifyPlaylist.fromJson(createResponse.data);
      
      // Add tracks to playlist
      if (trackUris.isNotEmpty) {
        await _dio.post(
          '$baseUrl/playlists/${playlist.id}/tracks',
          data: {'uris': trackUris},
        );
      }
      
      return playlist;
    } catch (e) {
      print('Error creating playlist: $e');
      return null;
    }
  }
  
  // Get user's playlists
  Future<List<SpotifyPlaylist>> getUserPlaylists() async {
    try {
      final response = await _dio.get(
        '$baseUrl/me/playlists',
        queryParameters: {'limit': 50},
      );
      
      return (response.data['items'] as List)
          .map((playlist) => SpotifyPlaylist.fromJson(playlist))
          .toList();
    } catch (e) {
      print('Error getting playlists: $e');
      return [];
    }
  }
  
  // Search tracks
  Future<List<SpotifyTrack>> searchTracks(String query) async {
    try {
      final response = await _dio.get(
        '$baseUrl/search',
        queryParameters: {
          'q': query,
          'type': 'track',
          'limit': 20,
        },
      );
      
      return (response.data['tracks']['items'] as List)
          .map((track) => SpotifyTrack.fromJson(track))
          .toList();
    } catch (e) {
      print('Error searching tracks: $e');
      return [];
    }
  }
  
  // Get recently played
  Future<List<SpotifyTrack>> getRecentlyPlayed() async {
    try {
      final response = await _dio.get(
        '$baseUrl/me/player/recently-played',
        queryParameters: {'limit': 20},
      );
      
      return (response.data['items'] as List)
          .map((item) => SpotifyTrack.fromJson(item['track']))
          .toList();
    } catch (e) {
      print('Error getting recently played: $e');
      return [];
    }
  }
  
  // Logout
  Future<void> logout() async {
    _accessToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('spotify_token');
    _dio.interceptors.clear();
  }
}
