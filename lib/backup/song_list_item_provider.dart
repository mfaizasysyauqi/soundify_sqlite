// import 'package:flutter/material.dart';
// import 'package:soundify/models/song.dart';

// // Create a new provider class for managing song list state
// class SongListItemProvider with ChangeNotifier {
//   String? _lastListenedSongId;
//   int _clickedIndex = -1;
//   List<Song> _songs = [];
//   List<Song> _filteredSongs = [];
//   bool _isSearch = false;

//   int _currentIndex = -1;
//   int _originalIndex = -1;

//   // Getters
//   String? get lastListenedSongId => _lastListenedSongId;
//   int get clickedIndex => _clickedIndex;
//   List<Song> get songs => _songs;
//   List<Song> get filteredSongs => _filteredSongs;
//   bool get isSearch => _isSearch;

//   // Add new getters
//   int get currentIndex => _currentIndex;
//   int get originalIndex => _originalIndex;
  
//   // Add new setter
//   void setIndices(int currentIndex, int originalIndex) {
//     _currentIndex = currentIndex;
//     _originalIndex = originalIndex;
//     notifyListeners();
//   }

//   // Setters with notification
//   void setLastListenedSongId(String? id) {
//     _lastListenedSongId = id;
//     notifyListeners();
//   }

//   void setClickedIndex(int index) {
//     _clickedIndex = index;
//     notifyListeners();
//   }

//   void setSongs(List<Song> songs) {
//     _songs = songs;
//     _filteredSongs = songs;
//     notifyListeners();
//   }

//   void setIsSearch(bool value) {
//     _isSearch = value;
//     notifyListeners();
//   }

//   void filterSongs(String query) {
//     if (query.isEmpty) {
//       _filteredSongs = _songs;
//     } else {
//       query = query.toLowerCase();
//       _filteredSongs = _songs.where((song) {
//         String songTitle = song.songTitle.toLowerCase();
//         String artistName = song.artistName?.toLowerCase() ?? '';
//         String albumName = song.albumName?.toLowerCase() ?? '';

//         return songTitle.contains(query) ||
//             artistName.contains(query) ||
//             albumName.contains(query);
//       }).toList();
//     }
//     notifyListeners();
//   }
// }
