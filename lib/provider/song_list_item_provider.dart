import 'package:flutter/material.dart';
import 'package:soundify/models/song.dart';

// song_list_item_provider.dart
// Create a new provider class for managing song list state
class SongListItemProvider with ChangeNotifier {
  String? _lastListenedSongId;
  int _clickedIndex = -1;
  List<Song> _songs = [];
  List<Song> _filteredSongs = [];
  bool _isSearch = false;

  // Getters
  String? get lastListenedSongId => _lastListenedSongId;
  int get clickedIndex => _clickedIndex;
  List<Song> get songs => _songs;
  List<Song> get filteredSongs => _filteredSongs;
  bool get isSearch => _isSearch;

  // Setters with notification
  void setLastListenedSongId(String? id) {
    _lastListenedSongId = id;
    notifyListeners();
  }

  void setClickedIndex(int index) {
    _clickedIndex = index;
    notifyListeners();
  }

  void setSongs(List<Song> songs) {
    _songs = songs;
    _filteredSongs = songs;
    notifyListeners();
  }

  void setIsSearch(bool value) {
    _isSearch = value;
    notifyListeners();
  }

  void filterSongs(String query) {
    if (query.isEmpty) {
      _filteredSongs = _songs;
    } else {
      query = query.toLowerCase();
      _filteredSongs = _songs.where((song) {
        String songTitle = song.songTitle.toLowerCase();
        String artistName = song.artistName?.toLowerCase() ?? '';
        String albumName = song.albumName?.toLowerCase() ?? '';

        return songTitle.contains(query) ||
            artistName.contains(query) ||
            albumName.contains(query);
      }).toList();
    }
    notifyListeners();
  }

  void clearSongs() {
    _songs.clear();
    _filteredSongs.clear();
    notifyListeners();
  }

  void removeSong(String songId) {
    // Remove from filteredSongs
    filteredSongs.removeWhere((song) => song.songId == songId);
    // Remove from allSongs if it exists
    _songs.removeWhere((song) => song.songId == songId);
    notifyListeners();
  }
}
