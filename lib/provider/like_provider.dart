import 'package:flutter/material.dart';
import 'package:soundify/database/database_helper.dart';
import 'package:soundify/models/song.dart';
class LikeProvider extends ChangeNotifier {
  final Map<String, bool> _likedSongsMap = {};
  List<Song> _likedSongs = [];

  bool isLiked(String songId) => _likedSongsMap[songId] ?? false;
  List<Song> get likedSongs => _likedSongs;

  Future<void> toggleLike(String songId) async {
    final currentUser = await DatabaseHelper.instance.getCurrentUser();
    if (currentUser == null) {
      print('No user logged in');
      return;
    }

    try {
      bool isNowLiked = await DatabaseHelper.instance.toggleSongLike(
        songId,
        currentUser.userId,
      );
      
      _likedSongsMap[songId] = isNowLiked;
      
      // Refresh liked songs list after toggling
      await fetchLikedSongs();

      notifyListeners();
    } catch (e) {
      print('Error updating likes: $e');
    }
  }

  Future<void> fetchLikedSongs() async {
    final currentUser = await DatabaseHelper.instance.getCurrentUser();
    if (currentUser != null) {
      _likedSongs = await DatabaseHelper.instance.getLikedSongs(currentUser.userId);
      
      // Update the liked songs map
      for (var song in _likedSongs) {
        _likedSongsMap[song.songId] = true;
      }
      
      notifyListeners();
    }
  }

  Future<void> checkIfLiked(String songId) async {
    final currentUser = await DatabaseHelper.instance.getCurrentUser();
    if (currentUser == null) return;

    final song = await DatabaseHelper.instance.getSongById(songId);
    _likedSongsMap[songId] = song?.likeIds?.contains(currentUser.userId) ?? false;
    notifyListeners();
  }
}