import 'package:flutter/material.dart';
import 'package:soundify/database/database_helper.dart';
import 'package:soundify/models/album.dart';

class AlbumProvider with ChangeNotifier {
  String _albumId = '';
  String _creatorId = '';
  String _albumName = '';
  String _albumDescription = '';
  String _albumImageUrl = '';
  DateTime _timestamp = DateTime.now();
  int _albumUserIndex = 0;
  List<String> _songListIds = [];
  List<String> _albumLikeIds = [];
  Duration _totalDuration = Duration.zero;

  String _creatorName = '';

  bool _isFetching = false;
  bool _isFetched = false;

  // Getters
  String get albumId => _albumId;
  String get creatorId => _creatorId;
  String get albumName => _albumName;
  String get albumDescription => _albumDescription;
  String get albumImageUrl => _albumImageUrl;
  DateTime get timestamp => _timestamp;
  int get albumUserIndex => _albumUserIndex;
  List<String> get songListIds => _songListIds;
  List<String> get albumLikeIds => _albumLikeIds;
  Duration? get totalDuration => _totalDuration;

  String get creatorName => _creatorName;

  bool get isFetching => _isFetching;
  bool get isFetched => _isFetched;

  // Function to update album data
  void updateAlbum(
    String newAlbumId,
    String newCreatorId,
    String newName,
    String? newDescription,
    String? newImageUrl,
    DateTime newTimestamp,
    int newAlbumUserIndex,
    List<String>? newSongListIds,
    List<String>? newAlbumLikeIds,
    Duration? newTotalDuration,
  ) {
    _albumId = newAlbumId;
    _creatorId = newCreatorId;
    _albumName = newName;
    _albumDescription = newDescription!;
    _albumImageUrl = newImageUrl!;
    _timestamp = newTimestamp;
    _albumUserIndex = newAlbumUserIndex;
    _songListIds = newSongListIds!;
    _albumLikeIds = newAlbumLikeIds!;
    _totalDuration = newTotalDuration!;

    _isFetched = true;
    notifyListeners();
  }

  void editAlbum(
    String newName,
    String? newDescription,
    String? newImageUrl,
  ) {
    _albumName = newName;
    _albumDescription = newDescription!;
    _albumImageUrl = newImageUrl!;
    _isFetched = true;
    notifyListeners();
  }
  
  Future<void> fetchAlbumById(String albumId) async {
    try {
      final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
      final Album? album = await _databaseHelper.getAlbumById(albumId);

      if (album != null) {
        _albumId = album.albumId;
        _albumName = album.albumName;
        _albumDescription = album.albumDescription;
        _albumImageUrl = album.albumImageUrl;
        _creatorId = album.creatorId;
        _timestamp = album.timestamp;
        _albumUserIndex = album.albumUserIndex;
        _songListIds = album.songListIds!;
        _albumLikeIds = album.albumLikeIds!;
        _totalDuration = album.totalDuration;

        notifyListeners();
      } else {
        throw Exception('Album not found');
      }
    } catch (e) {
      print('Error fetching album: $e');
      // You might want to handle the error differently
      throw Exception('Failed to load album');
    }
  }

  void _updateAlbumData(Album album) {
    _albumId = album.albumId;
    _creatorId = album.creatorId;
    _albumName = album.albumName;
    _albumDescription = album.albumDescription;
    _albumImageUrl = album.albumImageUrl;
    _timestamp = album.timestamp;
    _albumUserIndex = album.albumUserIndex;
    _songListIds = album.songListIds!;
    _albumLikeIds = album.albumLikeIds!;
    _totalDuration = album.totalDuration;
    _isFetched = true;
  }

  void setAlbumId(String newAlbumId) {
    if (newAlbumId != _albumId) {
      _albumId = newAlbumId;
      _isFetched = false;
      notifyListeners();
    }
  }

  void resetAlbum() {
    Album emptyAlbum = Album.empty();
    _updateAlbumData(emptyAlbum);
    _isFetched = false;
    notifyListeners();
  }

  void resetAlbumId() {
    _albumId = '';
    notifyListeners();
  }

  // New method to save album to SQLite
  Future<void> saveAlbum() async {
    final album = Album(
      albumId: _albumId,
      creatorId: _creatorId,
      albumName: _albumName,
      albumDescription: _albumDescription,
      albumImageUrl: _albumImageUrl,
      timestamp: _timestamp,
      albumUserIndex: _albumUserIndex,
      songListIds: _songListIds,
      albumLikeIds: _albumLikeIds,
      totalDuration: _totalDuration,
    );

    await DatabaseHelper.instance.insertAlbum(album);
    notifyListeners();
  }

  // New method to update album in SQLite
  Future<void> updateAlbumInDatabase() async {
    final album = Album(
      albumId: _albumId,
      creatorId: _creatorId,
      albumName: _albumName,
      albumDescription: _albumDescription,
      albumImageUrl: _albumImageUrl,
      timestamp: _timestamp,
      albumUserIndex: _albumUserIndex,
      songListIds: _songListIds,
      albumLikeIds: _albumLikeIds,
      totalDuration: _totalDuration,
    );

    await DatabaseHelper.instance.updateAlbum(album);
    notifyListeners();
  }

  // New method to delete album from SQLite
  Future<void> deleteAlbum() async {
    await DatabaseHelper.instance.deleteAlbum(_albumId);
    resetAlbum();
  }
}
