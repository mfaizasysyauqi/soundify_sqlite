import 'package:flutter/material.dart';
import 'package:soundify/database/database_helper.dart';
import 'package:soundify/models/playlist.dart';
import 'package:uuid/uuid.dart';

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

  // Tambahkan variable untuk error handling
  String? _error;

  // Tambahkan getters
  String? get error => _error;
  bool get hasError => _error != null;

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
    List<String> newSongListIds, // Change to non-nullable
    List<String> newPlaylistProviderLikeIds, // Change to non-nullable
    Duration newTotalDuration, // Change to non-nullable
  ) {
    _playlistId = newPlaylistProviderId;
    _creatorId = newCreatorId;
    _playlistName = newName;
    _playlistDescription = newDescription ?? '';
    _playlistImageUrl = newImageUrl ?? '';
    _timestamp = newTimestamp;
    _playlistUserIndex = newPlaylistProviderUserIndex;
    _songListIds = newSongListIds;
    _playlistLikeIds = newPlaylistProviderLikeIds;
    _totalDuration = newTotalDuration;

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

  List<Map<String, dynamic>> _displayPlaylists = [];
  List<Map<String, dynamic>> get displayPlaylists => _displayPlaylists;

  // Modifikasi fetchPlaylists untuk menyimpan data ke _displayPlaylists
  Future<void> fetchPlaylists() async {
    try {
      _isFetching = true;
      _error = null;
      notifyListeners();

      final db = await DatabaseHelper.instance.database;
      final user = await DatabaseHelper.instance.getCurrentUser();

      if (user == null) {
        throw Exception("User tidak ditemukan");
      }

      final creatorPlaylists = await db.query(
        'playlists',
        where: 'creatorId = ?',
        whereArgs: [user.userId],
      );

      final likedPlaylists = await db.query(
        'playlists',
        where: 'playlistLikeIds LIKE ?',
        whereArgs: ['%${user.userId}%'],
      );

      final Set<String> playlistIds = {};
      final List<Map<String, dynamic>> combinedPlaylists = [];
      Map<String, String?> userNameCache = {};

      // Function to fetch username and cache it
      Future<String> fetchUserName(String creatorId) async {
        if (userNameCache.containsKey(creatorId)) {
          return userNameCache[creatorId] ?? 'Creator name not found';
        }
        final creator = await DatabaseHelper.instance.getUserById(creatorId);
        final creatorName = creator?.fullName ?? 'Creator name not found';
        userNameCache[creatorId] = creatorName;
        return creatorName;
      }

      // Process creator playlists
      // Process creator playlists with proper null handling
      for (var playlist in creatorPlaylists) {
        final playlistId = playlist['playlistId']?.toString() ?? '';
        if (!playlistIds.contains(playlistId)) {
          playlistIds.add(playlistId);
          final creatorId = playlist['creatorId']?.toString() ?? '';
          final creatorName = await fetchUserName(creatorId);

          final songListIdsString = playlist['songListIds']?.toString() ?? '';
          final songListIds = songListIdsString.isEmpty
              ? <String>[]
              : songListIdsString.split(',');

          final playlistLikeIdsString =
              playlist['playlistLikeIds']?.toString() ?? '';
          final playlistLikeIds = playlistLikeIdsString.isEmpty
              ? <String>[]
              : playlistLikeIdsString.split(',');

          combinedPlaylists.add({
            'creatorId': creatorId,
            'creatorName': creatorName,
            'playlistId': playlistId,
            'playlistName': playlist['playlistName']?.toString() ?? '',
            'playlistDescription':
                playlist['playlistDescription']?.toString() ?? '',
            'playlistImageUrl': playlist['playlistImageUrl']?.toString() ?? '',
            'timestamp': DateTime.parse(playlist['timestamp']?.toString() ??
                DateTime.now().toIso8601String()),
            'playlistUserIndex': playlist['playlistUserIndex'] ?? 0,
            'songListIds': songListIds,
            'playlistLikeIds': playlistLikeIds,
            'totalDuration':
                Duration(seconds: playlist['totalDuration'] as int? ?? 0),
          });
        }
      }

      // Process and combine liked playlists, avoiding duplicates
      for (var playlist in likedPlaylists) {
        final playlistId = (playlist['playlistId'] ?? '').toString();
        if (!playlistIds.contains(playlistId)) {
          playlistIds.add(playlistId);

          final creatorId = (playlist['creatorId'] ?? '').toString();
          final creatorName = await fetchUserName(creatorId);

          combinedPlaylists.add({
            'creatorId': creatorId,
            'creatorName': creatorName,
            'playlistId': playlistId,
            'playlistName': (playlist['playlistName'] ?? '').toString(),
            'playlistDescription':
                (playlist['playlistDescription'] ?? '').toString(),
            'playlistImageUrl': (playlist['playlistImageUrl'] ?? '').toString(),
            'timestamp':
                DateTime.parse((playlist['timestamp'] ?? '').toString()),
            'playlistUserIndex': playlist['playlistUserIndex'] ?? 0,
            'songListIds': playlist['songListIds'] != null
                ? (playlist['songListIds'] as String).split(',')
                : [],
            'totalDuration': playlist['totalDuration'] is int
                ? Duration(seconds: playlist['totalDuration'] as int)
                : (playlist['totalDuration'] as Duration?) ?? Duration.zero,
          });
        }
      }

      // Sort playlists
      combinedPlaylists.sort(
          (a, b) => b['playlistUserIndex'].compareTo(a['playlistUserIndex']));

      _displayPlaylists = combinedPlaylists;
      _isFetching = false;
      notifyListeners();
    } catch (error) {
      print("Error fetching playlists from SQLite: $error");
      _error = error.toString();
      _isFetching = false;
      notifyListeners();
    }
  }

  // Tambahkan method untuk retry
  Future<void> retryFetchPlaylists() async {
    _error = null;
    notifyListeners();
    await fetchPlaylists();
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

  // New method to submit and save a new playlist
  Future<void> submitNewPlaylist(BuildContext context) async {
    try {
      // Get the current user from SQLite
      final user = await DatabaseHelper.instance.getCurrentUser();

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menambahkan playlist: User tidak ditemukan'),
          ),
        );
        return;
      }

      // Get the SQLite instance
      final db = await DatabaseHelper.instance.database;

      // Calculate `playlistUserIndex` based on existing playlists
      final existingPlaylists = await db.query(
        'playlists',
        where: 'creatorId = ?',
        whereArgs: [user.userId],
      );
      int playlistUserIndex = existingPlaylists.length + 1;

      // Generate a new playlist ID
      final playlistId = Uuid().v4();

      // Create a new playlist object
      final newPlaylist = Playlist(
        playlistId: playlistId,
        creatorId: user.userId,
        playlistName: "Playlist #$playlistUserIndex",
        playlistDescription: "",
        playlistImageUrl: "",
        timestamp: DateTime.now(),
        playlistUserIndex: playlistUserIndex,
        songListIds: [],
        playlistLikeIds: [],
        totalDuration: Duration.zero,
      );

      // Insert the playlist into the database
      await DatabaseHelper.instance.insertPlaylist(newPlaylist);

      // Update the provider's display playlists and notify listeners
      await fetchPlaylists();

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Playlist berhasil ditambahkan!')),
      );
    } catch (e) {
      print('Error submitting playlist data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan playlist: $e')),
      );
    }
  }
  
  // Delete a specific playlist by id and update the display list
  Future<void> deletePlaylistById(String playlistId) async {
    try {
      // Delete the playlist from SQLite
      await DatabaseHelper.instance.deletePlaylist(playlistId);

      // Remove the playlist from _displayPlaylists
      _displayPlaylists
          .removeWhere((playlist) => playlist['playlistId'] == playlistId);

      // Notify listeners to update the UI in real-time
      notifyListeners();
    } catch (e) {
      print("Error deleting playlist: $e");
      _error = "Failed to delete playlist";
      notifyListeners();
    }
  }
}
