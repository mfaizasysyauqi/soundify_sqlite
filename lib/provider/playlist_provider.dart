import 'package:flutter/material.dart';
import 'package:soundify/database/database_helper.dart';
import 'package:soundify/models/playlist.dart';

class PlaylistProvider with ChangeNotifier {
  String _playlistId = '';
  String _creatorId = '';
  String _playlistName = '';
  String _playlistDescription = '';
  String _playlistImageUrl = '';
  DateTime _timestamp = DateTime.now();
  int _playlistUserIndex = 0;
  List<String> _songListIds = [];
  List<String> _playlistLikeIds = [];
  Duration _totalDuration = Duration.zero;

  String _creatorName = '';

  bool _isFetching = false;
  bool _isFetched = false;

  // Getters
  String get playlistId => _playlistId;
  String get creatorId => _creatorId;
  String get playlistName => _playlistName;
  String get playlistDescription => _playlistDescription;
  String get playlistImageUrl => _playlistImageUrl;
  DateTime get timestamp => _timestamp;
  int get playlistUserIndex => _playlistUserIndex;
  List<String> get songListIds => _songListIds;
  List<String> get playlistLikeIds => _playlistLikeIds;
  Duration? get totalDuration => _totalDuration;

  String get creatorName => _creatorName;

  bool get isFetching => _isFetching;
  bool get isFetched => _isFetched;

  // Function to update playlist data
  void updatePlaylistProvider(
    String newPlaylistProviderId,
    String newCreatorId,
    String newName,
    String? newDescription,
    String? newImageUrl,
    DateTime newTimestamp,
    int newPlaylistProviderUserIndex,
    List<String>? newSongListIds,
    List<String>? newPlaylistProviderLikeIds,
    Duration? newTotalDuration,
  ) {
    _playlistId = newPlaylistProviderId;
    _creatorId = newCreatorId;
    _playlistName = newName;
    _playlistDescription = newDescription ?? '';
    _playlistImageUrl = newImageUrl ?? '';
    _timestamp = newTimestamp;
    _playlistUserIndex = newPlaylistProviderUserIndex;
    _songListIds = newSongListIds ?? [];
    _playlistLikeIds = newPlaylistProviderLikeIds ?? [];
    _totalDuration = newTotalDuration ?? Duration.zero;

    _isFetched = true;
    notifyListeners();
  }

  void editPlaylist(
    String newName,
    String? newDescription,
    String? newImageUrl,
  ) {
    _playlistName = newName;
    _playlistDescription = newDescription!;
    _playlistImageUrl = newImageUrl!;
    _isFetched = true;
    notifyListeners();
  }

  Future<void> fetchPlaylistById(String playlistId) async {
    try {
      final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
      final Playlist? playlist =
          await _databaseHelper.getPlaylistById(playlistId);

      if (playlist != null) {
        _playlistId = playlist.playlistId;
        _playlistName = playlist.playlistName;
        _playlistDescription = playlist.playlistDescription ?? '';
        _playlistImageUrl = playlist.playlistImageUrl ?? '';
        _creatorId = playlist.creatorId;
        _timestamp = playlist.timestamp;
        _playlistUserIndex = playlist.playlistUserIndex;
        _songListIds = playlist.songListIds ?? [];
        _playlistLikeIds = playlist.playlistLikeIds ?? [];
        _totalDuration = playlist.totalDuration;

        _isFetched = true;
        notifyListeners();
      } else {
        throw Exception('PlaylistProvider not found');
      }
    } catch (e) {
      print('Error fetching playlist: $e');
      throw Exception('Failed to load playlist');
    }
  }

  void _updatePlaylistData(Playlist playlist) {
    _playlistId = playlist.playlistId;
    _creatorId = playlist.creatorId;
    _playlistName = playlist.playlistName;
    _playlistDescription = playlist.playlistDescription!;
    _playlistImageUrl = playlist.playlistImageUrl!;
    _timestamp = playlist.timestamp;
    _playlistUserIndex = playlist.playlistUserIndex;
    _songListIds = playlist.songListIds!;
    _playlistLikeIds = playlist.playlistLikeIds!;
    _totalDuration = playlist.totalDuration;
    _isFetched = true;
  }

  void setPlaylistProviderId(String newPlaylistProviderId) {
    if (newPlaylistProviderId != _playlistId) {
      _playlistId = newPlaylistProviderId;
      _isFetched = false;
      notifyListeners();
    }
  }

  void resetPlaylist() {
    Playlist emptyPlaylist = Playlist.empty();
    _updatePlaylistData(emptyPlaylist);
    _isFetched = false;
    notifyListeners();
  }

  void resetPlaylistId() {
    _playlistId = '';
    notifyListeners();
  }

  // New method to save playlist to SQLite
  Future<void> savePlaylist() async {
    final playlist = Playlist(
      playlistId: _playlistId,
      creatorId: _creatorId,
      playlistName: _playlistName,
      playlistDescription: _playlistDescription,
      playlistImageUrl: _playlistImageUrl,
      timestamp: _timestamp,
      playlistUserIndex: _playlistUserIndex,
      songListIds: _songListIds,
      playlistLikeIds: _playlistLikeIds,
      totalDuration: _totalDuration,
    );

    await DatabaseHelper.instance.insertPlaylist(playlist);
    notifyListeners();
  }

  // New method to update playlist in SQLite
  Future<void> updatePlaylistInDatabase() async {
    final playlist = Playlist(
      playlistId: _playlistId,
      creatorId: _creatorId,
      playlistName: _playlistName,
      playlistDescription: _playlistDescription,
      playlistImageUrl: _playlistImageUrl,
      timestamp: _timestamp,
      playlistUserIndex: _playlistUserIndex,
      songListIds: _songListIds,
      playlistLikeIds: _playlistLikeIds,
      totalDuration: _totalDuration,
    );

    await DatabaseHelper.instance.updatePlaylist(playlist);
    notifyListeners();
  }

  // New method to delete playlist from SQLite
  Future<void> deletePlaylist() async {
    await DatabaseHelper.instance.deletePlaylist(_playlistId);
    resetPlaylist();
  }
}
