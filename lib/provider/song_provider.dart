import 'package:flutter/material.dart';
import 'package:soundify/database/database_helper.dart';
import 'package:soundify/database/file_storage_helper.dart';
import 'package:soundify/models/user.dart';

class SongProvider with ChangeNotifier {
  String _songId = '';
  String _senderId = '';
  String _artistId = '';
  String _songTitle = '';
  String _profileImageUrl = '';
  String _songImageUrl = '';
  String _bioImageUrl = '';
  String _artistName = '';
  String _songUrl = '';
  int _duration = 0;
  bool _isPlaying = false;
  bool _shouldPlay = false;

  int index = 0; // Index of the song in a list

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  String userBio = '';

  // Getters
  String get songId => _songId;
  String get senderId => _senderId;
  String get artistId => _artistId;
  String get songTitle => _songTitle;
  String get profileImageUrl => _profileImageUrl;
  String get songImageUrl => _songImageUrl;
  String get bioImageUrl => _bioImageUrl;
  String get artistName => _artistName;
  String get songUrl => _songUrl;
  int get duration => _duration;
  bool get isPlaying => _isPlaying;
  bool get shouldPlay => _shouldPlay;

  // Set song details and play
  void setSong(
    String songId,
    String senderId,
    String artistId,
    String title,
    String profileImageUrl,
    String songImageUrl,
    String bioImageUrl,
    String artist,
    String songUrl,
    int duration,
    int songIndex,
  ) async {
    if (_songId != songId) {
      stop();
      _songId = songId;
      _senderId = senderId;
      _artistId = artistId;
      _songTitle = title;
      _profileImageUrl = profileImageUrl;
      _songImageUrl = songImageUrl;
      _bioImageUrl = bioImageUrl;
      _artistName = artist;
      _songUrl = songUrl;
      _duration = duration;
      _isPlaying = true;
      index = songIndex;

      fetchUserBio(); // Fetch bio in the background
      notifyListeners();
    }
  }

  void setArtistId(String newArtistId) {
    _artistId = newArtistId;
    notifyListeners();
  }

  void resetArtistId() {
    _artistId = '';
    notifyListeners();
  }

  void setShouldPlay(bool value) {
    _shouldPlay = value;
    notifyListeners();
  }

  // Fetch user bio from SQLite
  Future<void> fetchUserBio() async {
    if (userBio.isEmpty) {
      try {
        User? user = await _databaseHelper.getUserById(_artistId);
        if (user != null) {
          userBio = user.bio;
          notifyListeners();
        }
      } catch (e) {
        print("Error fetching user bio: $e");
      }
    }
  }

  void playSong() {
    if (!_isPlaying) {
      _isPlaying = true;
      // Add your audio player logic here
      notifyListeners();
    }
  }

  void stop() {
    if (_isPlaying) {
      stopCurrentSong();
      _isPlaying = false;
      notifyListeners();
    }
  }

  void stopCurrentSong() {
    // Stop the current song (e.g., stop the audio player)
  }

  void pauseOrResume() {
    _isPlaying ? pause() : resume();
  }

  void pause() {
    _isPlaying = false;
    notifyListeners();
  }

  void resume() {
    _isPlaying = true;
    notifyListeners();
  }

  Future<void> saveVolumeToSQLiteAndJson(double volume) async {
    try {
      // Update SQLite
      User? currentUser = await _databaseHelper.getCurrentUser();
      if (currentUser != null) {
        User updatedUser = currentUser.copyWith(lastVolumeLevel: volume);
        // ignore: unused_local_variable
        int result = await _databaseHelper.updateUser(updatedUser);

        // Update JSON file
        await FileStorageHelper.instance.updateJsonWithLatestUser();
      }
    } catch (e) {
      print("Error saving volume to SQLite or JSON: $e");
    }
  }

  // Save last listened song to SQLite
  Future<void> saveLastListenedSongToSQLite() async {
    try {
      User? currentUser = await _databaseHelper.getCurrentUser();
      if (currentUser != null) {
        User updatedUser = currentUser.copyWith(lastListenedSongId: _songId);
        await _databaseHelper.updateUser(updatedUser);
      }
    } catch (e) {
      print("Error saving last listened song to SQLite: $e");
    }
  }

  // Load user preferences from SQLite
  Future<Map<String, dynamic>> loadUserPreferences() async {
    try {
      User? currentUser = await _databaseHelper.getCurrentUser();
      if (currentUser != null) {
        // Ambil lastVolumeLevel dan cetak jenisnya
        var lastVolumeLevel = currentUser.lastVolumeLevel;

        return {
          'lastVolumeLevel': lastVolumeLevel,
          'lastListenedSongId': currentUser.lastListenedSongId,
        };
      }
    } catch (e) {
      print("Error loading user preferences from SQLite: $e");
    }
    return {};
  }
}
