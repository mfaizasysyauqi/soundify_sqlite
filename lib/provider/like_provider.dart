import 'package:flutter/material.dart';
import 'package:soundify/database/database_helper.dart';
import 'package:soundify/models/song.dart';
// LikeProvider
class LikeProvider extends ChangeNotifier {
  final Map<String, bool> _likedSongsMap = {};
  List<Song> _likedSongs = [];

  bool isLiked(String songId) => _likedSongsMap[songId] ?? false;
  List<Song> get likedSongs => _likedSongs;

  Future<void> fetchLikedSongs() async {
    final currentUser = await DatabaseHelper.instance.getCurrentUser();
    if (currentUser != null) {
      _likedSongs =
          await DatabaseHelper.instance.getLikedSongs(currentUser.userId);

      // Update the liked songs map
      _likedSongsMap.clear();
      for (var song in _likedSongs) {
        _likedSongsMap[song.songId] = true;
      }

      notifyListeners();
    }
  }

  // Update local state after like/unlike
  void updateLikeState(String songId, bool isLiked) {
    _likedSongsMap[songId] = isLiked;
    if (!isLiked) {
      _likedSongs.removeWhere((song) => song.songId == songId);
    }
    notifyListeners();
  }

  Future<void> checkIfLiked(String songId) async {
    final currentUser = await DatabaseHelper.instance.getCurrentUser();
    if (currentUser == null) return;

    final song = await DatabaseHelper.instance.getSongById(songId);
    _likedSongsMap[songId] =
        song?.likeIds?.contains(currentUser.userId) ?? false;
    notifyListeners();
  }
}