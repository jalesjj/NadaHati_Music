import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/spotify_models.dart';
import '../services/spotify_service.dart';

class AppState extends ChangeNotifier {
  final SpotifyService _spotifyService = SpotifyService();
  
  // User & Authentication
  SpotifyUser? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  
  // Current Session
  Mood? _currentMood;
  List<SpotifyTrack> _currentTracks = [];
  bool _isLoadingTracks = false;
  
  // History & Analytics
  List<MoodHistory> _moodHistory = [];
  
  // Error handling
  String? _errorMessage;
  
  // Getters
  SpotifyUser? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  Mood? get currentMood => _currentMood;
  List<SpotifyTrack> get currentTracks => _currentTracks;
  bool get isLoadingTracks => _isLoadingTracks;
  List<MoodHistory> get moodHistory => _moodHistory;
  String? get errorMessage => _errorMessage;
  
  // Constructor
  AppState() {
    _initializeApp();
  }
  
  // Initialize app
  Future<void> _initializeApp() async {
    _setLoading(true);
    
    // Try to load saved token
    final hasToken = await _spotifyService.loadSavedToken();
    if (hasToken) {
      await _loadUserProfile();
    }
    
    // Load mood history
    await _loadMoodHistory();
    
    _setLoading(false);
  }
  
  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  // Set error message
  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }
  
  // Clear error
  void clearError() {
    _setError(null);
  }
  
  // Authentication
  Future<void> authenticateWithSpotify() async {
    try {
      _setLoading(true);
      _setError(null);
      await _spotifyService.authenticate();
    } catch (e) {
      _setError('Failed to authenticate with Spotify: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Handle OAuth callback
  Future<bool> handleSpotifyCallback(String code) async {
    try {
      _setLoading(true);
      _setError(null);
      
      final success = await _spotifyService.handleCallback(code);
      if (success) {
        await _loadUserProfile();
        return true;
      } else {
        _setError('Failed to complete authentication');
        return false;
      }
    } catch (e) {
      _setError('Authentication failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Load user profile
  Future<void> _loadUserProfile() async {
    try {
      _user = await _spotifyService.getUserProfile();
      _isAuthenticated = _user != null;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load user profile: $e');
      _isAuthenticated = false;
    }
  }
  
  // Logout
  Future<void> logout() async {
    try {
      await _spotifyService.logout();
      _user = null;
      _isAuthenticated = false;
      _currentMood = null;
      _currentTracks.clear();
      notifyListeners();
    } catch (e) {
      _setError('Failed to logout: $e');
    }
  }
  
  // Set mood and get recommendations
  Future<void> setMoodAndGetRecommendations(Mood mood) async {
    try {
      _isLoadingTracks = true;
      _setError(null);
      _currentMood = mood;
      notifyListeners();
      
      final tracks = await _spotifyService.getRecommendationsByMood(mood);
      _currentTracks = tracks;
      
      // Save to history
      await _saveMoodToHistory(mood, tracks);
      
    } catch (e) {
      _setError('Failed to get recommendations: $e');
      _currentTracks.clear();
    } finally {
      _isLoadingTracks = false;
      notifyListeners();
    }
  }
  
  // Create playlist from current mood
  Future<SpotifyPlaylist?> createPlaylistFromCurrentMood() async {
    if (_currentMood == null || _currentTracks.isEmpty) {
      _setError('No mood or tracks selected');
      return null;
    }
    
    try {
      _setLoading(true);
      _setError(null);
      
      final playlistName = '${_currentMood!.emoji} ${_currentMood!.label} Mix - ${DateTime.now().day}/${DateTime.now().month}';
      final description = 'Generated by MoodTunes for ${_currentMood!.label.toLowerCase()} mood';
      final trackUris = _currentTracks.map((track) => track.uri).toList();
      
      final playlist = await _spotifyService.createPlaylist(
        playlistName,
        description,
        trackUris,
      );
      
      if (playlist != null) {
        // Update history with playlist ID
        await _updateHistoryWithPlaylist(playlist.id);
      }
      
      return playlist;
    } catch (e) {
      _setError('Failed to create playlist: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  // Save mood to history
  Future<void> _saveMoodToHistory(Mood mood, List<SpotifyTrack> tracks) async {
    final history = MoodHistory(
      id: const Uuid().v4(),
      mood: mood,
      timestamp: DateTime.now(),
      trackIds: tracks.map((track) => track.id).toList(),
    );
    
    _moodHistory.insert(0, history);
    await _saveMoodHistoryToStorage();
    notifyListeners();
  }
  
  // Update history with playlist ID
  Future<void> _updateHistoryWithPlaylist(String playlistId) async {
    if (_moodHistory.isNotEmpty) {
      final latestHistory = _moodHistory.first;
      final updatedHistory = MoodHistory(
        id: latestHistory.id,
        mood: latestHistory.mood,
        timestamp: latestHistory.timestamp,
        trackIds: latestHistory.trackIds,
        playlistId: playlistId,
      );
      
      _moodHistory[0] = updatedHistory;
      await _saveMoodHistoryToStorage();
      notifyListeners();
    }
  }
  
  // Load mood history from storage
  Future<void> _loadMoodHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('mood_history');
      
      if (historyJson != null) {
        final List<dynamic> historyList = json.decode(historyJson);
        _moodHistory = historyList
            .map((item) => MoodHistory.fromJson(item))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading mood history: $e');
    }
  }
  
  // Save mood history to storage
  Future<void> _saveMoodHistoryToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = json.encode(
        _moodHistory.map((item) => item.toJson()).toList(),
      );
      await prefs.setString('mood_history', historyJson);
    } catch (e) {
      print('Error saving mood history: $e');
    }
  }
  
  // Get mood statistics
  Map<Mood, int> getMoodStats() {
    final stats = <Mood, int>{};
    for (final mood in Mood.values) {
      stats[mood] = 0;
    }
    
    for (final history in _moodHistory) {
      stats[history.mood] = (stats[history.mood] ?? 0) + 1;
    }
    
    return stats;
  }
  
  // Get recent mood history (last 7 days)
  List<MoodHistory> getRecentMoodHistory() {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return _moodHistory
        .where((history) => history.timestamp.isAfter(sevenDaysAgo))
        .toList();
  }
  
  // Get most frequent mood
  Mood? getMostFrequentMood() {
    final stats = getMoodStats();
    if (stats.isEmpty) return null;
    
    return stats.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
  
  // Search tracks
  Future<List<SpotifyTrack>> searchTracks(String query) async {
    try {
      _setError(null);
      return await _spotifyService.searchTracks(query);
    } catch (e) {
      _setError('Failed to search tracks: $e');
      return [];
    }
  }
  
  // Get user playlists
  Future<List<SpotifyPlaylist>> getUserPlaylists() async {
    try {
      _setError(null);
      return await _spotifyService.getUserPlaylists();
    } catch (e) {
      _setError('Failed to load playlists: $e');
      return [];
    }
  }
  
  // Get recently played
  Future<List<SpotifyTrack>> getRecentlyPlayed() async {
    try {
      _setError(null);
      return await _spotifyService.getRecentlyPlayed();
    } catch (e) {
      _setError('Failed to load recently played: $e');
      return [];
    }
  }
  
  // Clear current session
  void clearCurrentSession() {
    _currentMood = null;
    _currentTracks.clear();
    notifyListeners();
  }
  
  // Refresh recommendations for current mood
  Future<void> refreshRecommendations() async {
    if (_currentMood != null) {
      await setMoodAndGetRecommendations(_currentMood!);
    }
  }
}