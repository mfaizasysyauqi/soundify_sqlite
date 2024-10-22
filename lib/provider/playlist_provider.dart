import 'package:flutter/material.dart';
import 'package:soundify/database/database_helper.dart';
import 'package:soundify/models/playlist.dart';

class PlaylistProvider with ChangeNotifier {
  String _playlistName = '';
  String? _playlistImageUrl = '';
  String? _playlistDescription = '';
  String _creatorId = '';
  String _playlistId = '';
  DateTime _timestamp = DateTime.now();
  int _playlistUserIndex = 0;
  List<String>? _songListIds = [];
  Duration? _totalDuration = Duration.zero;

  bool _isFetching = false;
  bool _isFetched = false;

  // Getters
  String get playlistName => _playlistName;
  String? get playlistImageUrl => _playlistImageUrl;
  String? get playlistDescription => _playlistDescription;
  String get creatorId => _creatorId;
  String get playlistId => _playlistId;
  DateTime get timestamp => _timestamp;
  int get playlistUserIndex => _playlistUserIndex;
  List<String>? get songListIds => _songListIds;
  Duration? get totalDuration => _totalDuration;

  bool get isFetching => _isFetching;
  bool get isFetched => _isFetched;

  // Function to update playlist data
  void updatePlaylist(
    String newImageUrl,
    String newName,
    String newDescription,
    String newCreatorId,
    String newPlaylistId,
    DateTime newTimestamp,
    int newPlaylistUserIndex,
    List<String> newSongListIds,
    Duration newTotalDuration,
  ) {
    _playlistImageUrl = newImageUrl;
    _playlistName = newName;
    _playlistDescription = newDescription;
    _creatorId = newCreatorId;
    _playlistId = newPlaylistId;
    _timestamp = newTimestamp;
    _playlistUserIndex = newPlaylistUserIndex;
    _songListIds = newSongListIds;
    _totalDuration = newTotalDuration;

    _isFetched = true;
    notifyListeners();
  }

  Future<void> fetchPlaylistById(String playlistId) async {
    if (_isFetching || (_isFetched && _playlistId == playlistId)) {
      return;
    }

    if (_playlistId != playlistId) {
      resetPlaylist();
    }

    _playlistId = playlistId;
    _isFetching = true;
    notifyListeners();

    try {
      Playlist? playlist = await DatabaseHelper.instance.getPlaylistById(playlistId);

      if (playlist != null) {
        _updatePlaylistData(playlist);
      } else {
        throw Exception('Playlist not found');
      }
    } catch (error) {
      print('Error fetching playlist: $error');
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  void _updatePlaylistData(Playlist playlist) {
    _playlistImageUrl = playlist.playlistImageUrl;
    _playlistName = playlist.playlistName;
    _playlistDescription = playlist.playlistDescription;
    _creatorId = playlist.creatorId;
    _playlistId = playlist.playlistId;
    _timestamp = playlist.timestamp;
    _playlistUserIndex = playlist.playlistUserIndex;
    _songListIds = playlist.songListIds;
    _totalDuration = playlist.totalDuration;
    _isFetched = true;
  }

  void resetPlaylist() {
    _playlistName = '';
    _playlistImageUrl = '';
    _playlistDescription = '';
    _creatorId = '';
    _playlistId = '';
    _timestamp = DateTime.now();
    _playlistUserIndex = 0;
    _songListIds = [];
    _totalDuration = Duration.zero;
    _isFetched = false;
    notifyListeners();
  }

  Future<void> savePlaylist() async {
    Playlist playlist = Playlist(
      playlistId: _playlistId,
      creatorId: _creatorId,
      playlistName: _playlistName,
      playlistDescription: _playlistDescription,
      playlistImageUrl: _playlistImageUrl,
      timestamp: _timestamp,
      playlistUserIndex: _playlistUserIndex,
      songListIds: _songListIds,
      playlistLikeIds: [], // Assuming this is not managed in the provider
      totalDuration: _totalDuration,
    );

    await DatabaseHelper.instance.insertPlaylist(playlist);
    notifyListeners();
  }

  Future<void> deletePlaylist() async {
    if (_playlistId.isNotEmpty) {
      await DatabaseHelper.instance.deletePlaylist(_playlistId);
      resetPlaylist();
    }
  }
}