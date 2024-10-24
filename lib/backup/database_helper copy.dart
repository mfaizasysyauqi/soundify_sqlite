import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:soundify/models/album.dart';
import 'package:soundify/models/playlist.dart';
import 'package:soundify/models/song.dart';
import 'package:soundify/models/user.dart';
import '../database/file_storage_helper.dart';

class DatabaseHelper {
  //====================================================================
  // INITIALIZATION & SINGLETON SETUP
  //====================================================================

  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static FileStorageHelper fileStorageHelper = FileStorageHelper.instance;

  // Stream controllers for real-time updates
  final _songsController = BehaviorSubject<List<Song>>();
  final _playlistsController = BehaviorSubject<List<Playlist>>();
  final _albumsController = BehaviorSubject<List<Album>>();
  final _usersController = BehaviorSubject<List<User>>();
  final _currentUserController = BehaviorSubject<User?>();

  // Stream getters for real-time data access
  Stream<List<Song>> get songsStream => _songsController.stream;
  Stream<List<Playlist>> get playlistsStream => _playlistsController.stream;
  Stream<List<Album>> get albumsStream => _albumsController.stream;
  Stream<List<User>> get usersStream => _usersController.stream;
  Stream<User?> get currentUserStream => _currentUserController.stream;

  DatabaseHelper._init();

  //====================================================================
  // DATABASE INITIALIZATION
  //====================================================================

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('soundify.db');
    await _initializeStreams();
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await _getDatabaseDirectory();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
    );
  }

  Future<String> _getDatabaseDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'soundify_database');

    final dir = Directory(path);
    if (!(await dir.exists())) {
      await dir.create(recursive: true);
    }

    return path;
  }

  Future<void> _initializeStreams() async {
    _songsController.add(await getSongs());
    _playlistsController.add(await getPlaylists());
    _albumsController.add(await getAlbums());
    _usersController
        .add((await getUsers()).map((e) => User.fromMap(e)).toList());
    _currentUserController.add(await getCurrentUser());
  }

  //====================================================================
  // DATABASE SCHEMA CREATION
  //====================================================================

  Future _createDB(Database db, int version) async {
    // Songs table
    await db.execute('''
    CREATE TABLE songs (
      songId TEXT PRIMARY KEY,
      senderId TEXT,
      artistId TEXT,
      songTitle TEXT,
      songImageUrl TEXT,
      songUrl TEXT,
      songDuration INTEGER,
      timestamp TEXT,
      albumId TEXT,
      artistSongIndex INTEGER,
      likeIds TEXT,
      playlistIds TEXT,
      albumIds TEXT,
      playedIds TEXT
    )
    ''');

    // Playlists table
    await db.execute('''
    CREATE TABLE playlists (
      playlistId TEXT PRIMARY KEY,
      creatorId TEXT,
      playlistName TEXT,
      playlistDescription TEXT,
      playlistImageUrl TEXT,
      timestamp TEXT,
      playlistUserIndex INTEGER,
      songListIds TEXT,
      playlistLikeIds TEXT,
      totalDuration INTEGER
    )
    ''');

    // Albums table
    await db.execute('''
    CREATE TABLE albums (
      albumId TEXT PRIMARY KEY,
      creatorId TEXT,
      albumName TEXT,
      albumDescription TEXT,
      albumImageUrl TEXT,
      timestamp TEXT,
      albumUserIndex INTEGER,
      songListIds TEXT,
      albumLikeIds TEXT,
      totalDuration INTEGER
    )
    ''');

    // Users table
    await db.execute('''
    CREATE TABLE users (
      userId TEXT PRIMARY KEY,
      fullName TEXT,
      username TEXT,
      email TEXT,
      password TEXT,
      profileImageUrl TEXT,
      bioImageUrl TEXT,
      bio TEXT,
      role TEXT,
      followers TEXT,
      following TEXT,
      userLikedSongs TEXT,
      userLikedAlbums TEXT,
      userLikedPlaylists TEXT,
      lastListenedSongId TEXT,
      lastVolumeLevel REAL
    )
    ''');

    // Current user table
    await db.execute('''
    CREATE TABLE current_user (
      userId TEXT PRIMARY KEY
    )
    ''');
  }

  //====================================================================
  // SONGS OPERATIONS
  //====================================================================

  Future<int> insertSong(Song song) async {
    final db = await database;
    final result = await db.insert('songs', song.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);

    if (result > 0) {
      final songs = await getSongs();
      _songsController.add(songs);
    }
    return result;
  }

  Future<List<Song>> getSongs() async {
    final db = await database;
    final maps = await db.query('songs');

    List<Song> songs = [];
    for (var map in maps) {
      Song song = Song.fromMap(map);

      User? artist = await getUserByArtistId(song.artistId);
      if (artist != null) {
        song.artistName = artist.fullName;
        song.profileImageUrl = artist.profileImageUrl;
        song.bioImageUrl = artist.bioImageUrl;
      }

      Album? album = await getAlbumById(song.albumId);
      if (album != null) {
        song.albumName = album.albumName;
      }

      songs.add(song);
    }

    return songs;
  }

  Future<Song?> getSongById(String id) async {
    final db = await database;
    final maps = await db.query('songs', where: 'songId = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      Song song = Song.fromMap(maps.first);

      User? artist = await getUserByArtistId(song.artistId);
      if (artist != null) {
        song.artistName = artist.fullName;
        song.profileImageUrl = artist.profileImageUrl;
        song.bioImageUrl = artist.bioImageUrl;
      }

      Album? album = await getAlbumById(song.albumId);
      if (album != null) {
        song.albumName = album.albumName;
      }

      return song;
    }
    return null;
  }

  Future<int> updateSong(Song song) async {
    final db = await database;
    final result = await db.update('songs', song.toMap(),
        where: 'songId = ?', whereArgs: [song.songId]);

    if (result > 0) {
      final songs = await getSongs();
      _songsController.add(songs);
    }
    return result;
  }

  Future<int> deleteSong(String id) async {
    final db = await database;
    final result =
        await db.delete('songs', where: 'songId = ?', whereArgs: [id]);

    if (result > 0) {
      final songs = await getSongs();
      _songsController.add(songs);
    }
    return result;
  }

  // Future<bool> toggleSongLike(String songId, String userId) async {
  //   try {
  //     // Get the song
  //     final Song? song = await getSongById(songId);
  //     if (song == null) {
  //       throw Exception('Song not found');
  //     }

  //     // Initialize likeIds as a list and handle both cases where it's stored as a String or List<String>
  //     List<String> likeIds = [];
  //     if (song.likeIds != null) {
  //       if (song.likeIds is String) {
  //         likeIds = (song.likeIds as String)
  //             .split(',')
  //             .where((id) => id.isNotEmpty)
  //             .toList();
  //       } else if (song.likeIds is List<String>) {
  //         likeIds = List<String>.from(
  //             song.likeIds!); // Ensure it's cast as a List<String>
  //       }
  //     }

  //     // Get the user
  //     final User? user = await getUserById(userId);
  //     if (user == null) {
  //       throw Exception('User not found');
  //     }

  //     // Initialize userLikedSongs as a list and handle both cases where it's stored as a String or List<String>
  //     List<String> userLikedSongs = [];
  //     if (user.userLikedSongs != null) {
  //       if (user.userLikedSongs is String) {
  //         userLikedSongs = (user.userLikedSongs as String)
  //             .split(',')
  //             .where((id) => id.isNotEmpty)
  //             .toList();
  //       } else if (user.userLikedSongs is List<String>) {
  //         userLikedSongs = List<String>.from(
  //             user.userLikedSongs!); // Ensure it's cast as a List<String>
  //       }
  //     }

  //     // Check if the user already liked the song
  //     bool isLiked = likeIds.contains(userId);

  //     if (isLiked) {
  //       // Unlike: Remove userId from song's likeIds
  //       likeIds.remove(userId);
  //       // Remove songId from user's likedSongs
  //       userLikedSongs.remove(songId);
  //     } else {
  //       // Like: Add userId to song's likeIds
  //       likeIds.add(userId);
  //       // Add songId to user's likedSongs
  //       userLikedSongs.add(songId);
  //     }

  //     // Update song's likeIds back to a string
  //     song.likeIds = likeIds.join(','); // Converting list back to string
  //     await updateSong(song);

  //     // Update user's userLikedSongs back to a string
  //     user.userLikedSongs =
  //         userLikedSongs.join(','); // Converting list back to string
  //     await updateUser(user);

  //     // Return new like status
  //     return !isLiked;
  //   } catch (e) {
  //     print('Error in toggleSongLike: $e');
  //     rethrow;
  //   }
  // }
  Future<bool> toggleSongLike(String songId, String userId) async {
    Database db = await instance.database;

    // Get current song
    Song? song = await getSongById(songId);
    // Get current user
    User? user = await getUserById(userId);

    if (song == null || user == null) {
      return false;
    }

    // Handle the case when likeIds or userLikedSongs is null
    List<String> songLikeIds = song.likeIds ?? [];
    List<String> userLikedSongs = user.userLikedSongs;

    bool isCurrentlyLiked = songLikeIds.contains(userId);

    try {
      await db.transaction((txn) async {
        // Update song's likeIds
        List<String> updatedLikeIds = List<String>.from(songLikeIds);
        if (isCurrentlyLiked) {
          updatedLikeIds.remove(userId);
        } else {
          updatedLikeIds.add(userId);
        }

        // Update song record
        await txn.update(
          'songs',
          {'likeIds': updatedLikeIds.join(',')},
          where: 'songId = ?',
          whereArgs: [songId],
        );

        // Update user's liked songs
        List<String> updatedUserLikedSongs = List<String>.from(userLikedSongs);
        if (isCurrentlyLiked) {
          updatedUserLikedSongs.remove(songId);
        } else {
          updatedUserLikedSongs.add(songId);
        }

        // Update user record
        await txn.update(
          'users',
          {'userLikedSongs': updatedUserLikedSongs.join(',')},
          where: 'userId = ?',
          whereArgs: [userId],
        );
      });

      return !isCurrentlyLiked; // Return new like status
    } catch (e) {
      print('Error toggling like status: $e');
      return isCurrentlyLiked; // Return original status if error occurs
    }
  }
  //====================================================================
  // PLAYLIST OPERATIONS
  //====================================================================

  Future<int> insertPlaylist(Playlist playlist) async {
    final db = await database;
    final result = await db.insert('playlists', playlist.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);

    if (result > 0) {
      final playlists = await getPlaylists();
      _playlistsController.add(playlists);
    }
    return result;
  }

  Future<List<Playlist>> getPlaylists() async {
    final db = await database;
    final maps = await db.query('playlists');
    return List.generate(maps.length, (i) => Playlist.fromMap(maps[i]));
  }

  Future<Playlist?> getPlaylistById(String id) async {
    final db = await database;
    final maps =
        await db.query('playlists', where: 'playlistId = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Playlist.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updatePlaylist(Playlist playlist) async {
    final db = await database;
    final result = await db.update('playlists', playlist.toMap(),
        where: 'playlistId = ?', whereArgs: [playlist.playlistId]);

    if (result > 0) {
      final playlists = await getPlaylists();
      _playlistsController.add(playlists);
    }
    return result;
  }

  Future<int> deletePlaylist(String id) async {
    final db = await database;
    final result =
        await db.delete('playlists', where: 'playlistId = ?', whereArgs: [id]);

    if (result > 0) {
      final playlists = await getPlaylists();
      _playlistsController.add(playlists);
    }
    return result;
  }

  //====================================================================
  // ALBUM OPERATIONS
  //====================================================================

  Future<int> insertAlbum(Album album) async {
    final db = await database;
    final result = await db.insert('albums', album.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);

    if (result > 0) {
      final albums = await getAlbums();
      _albumsController.add(albums);
    }
    return result;
  }

  Future<List<Album>> getAlbums() async {
    final db = await database;
    final maps = await db.query('albums');
    return List.generate(maps.length, (i) => Album.fromMap(maps[i]));
  }

  Future<Album?> getAlbumById(String? albumId) async {
    if (albumId == null) return null;

    final db = await database;
    final maps =
        await db.query('albums', where: 'albumId = ?', whereArgs: [albumId]);

    if (maps.isNotEmpty) {
      return Album.fromMap(maps.first);
    }
    return null;
  }

// Add this to DatabaseHelper class
  Future<Album?> getAlbumByCreatorId(String creatorId) async {
    final db = await database;
    final maps = await db
        .query('albums', where: 'creatorId = ?', whereArgs: [creatorId]);

    if (maps.isNotEmpty) {
      return Album.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateAlbum(Album album) async {
    final db = await database;
    final result = await db.update('albums', album.toMap(),
        where: 'albumId = ?', whereArgs: [album.albumId]);

    if (result > 0) {
      final albums = await getAlbums();
      _albumsController.add(albums);
    }
    return result;
  }

  Future<int> deleteAlbum(String id) async {
    final db = await database;
    final result =
        await db.delete('albums', where: 'albumId = ?', whereArgs: [id]);

    if (result > 0) {
      final albums = await getAlbums();
      _albumsController.add(albums);
    }
    return result;
  }

  //====================================================================
  // USER OPERATIONS
  //====================================================================

  Future<void> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    await db.insert('users', user,
        conflictAlgorithm: ConflictAlgorithm.replace);

    final users = await getUsers();
    _usersController.add(users.map((e) => User.fromMap(e)).toList());

    final currentUser = await getCurrentUser();
    _currentUserController.add(currentUser);

    await FileStorageHelper.instance.addUser(user);
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return await db.query('users');
  }

  Future<User?> getUserById(String userId) async {
    final db = await database;
    final result =
        await db.query('users', where: 'userId = ?', whereArgs: [userId]);

    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  Future<User?> getUserByArtistId(String artistId) async {
    return await getUserById(artistId);
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    final result = await db.update('users', user.toMap(),
        where: 'userId = ?', whereArgs: [user.userId]);

    if (result > 0) {
      final users = await getUsers();
      _usersController.add(users.map((e) => User.fromMap(e)).toList());

      final currentUser = await getCurrentUser();
      if (currentUser?.userId == user.userId) {
        _currentUserController.add(user);
      }

      await FileStorageHelper.instance.updateJsonWithLatestUser();
    }
    return result;
  }

  Future<User?> getUserByEmailAndPassword(String email, String password) async {
    final db = await database;
    try {
      final result = await db.query(
        'users',
        where: 'email = ? AND password = ?',
        whereArgs: [email, password],
      );

      if (result.isNotEmpty) {
        return User.fromMap(result.first);
      }
      return null;
    } catch (e) {
      print('Error in getUserByEmailAndPassword: $e');
      return null;
    }
  }

  Future<bool> isUsernameUsed(String username) async {
    final db = await database;
    try {
      final result = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
      );
      return result.isNotEmpty;
    } catch (e) {
      print('Error checking username: $e');
      return false;
    }
  }

  Future<bool> isEmailUsed(String email) async {
    final db = await database;
    try {
      final result = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );
      return result.isNotEmpty;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }

  Future<String?> getCurrentUserId() async {
    try {
      final db = await database;
      final currentUserResult = await db.query('current_user');

      if (currentUserResult.isNotEmpty) {
        return currentUserResult.first['userId'] as String;
      }
      return null;
    } catch (e) {
      print('Error getting current user ID: $e');
      return null;
    }
  }
  //====================================================================
  // SESSION MANAGEMENT
  //====================================================================

  Future<void> setCurrentUserId(String userId) async {
    final db = await database;
    await db.insert('current_user', {'userId': userId},
        conflictAlgorithm: ConflictAlgorithm.replace);

    final currentUser = await getCurrentUser();
    _currentUserController.add(currentUser);
  }

  Future<User?> getCurrentUser() async {
    final db = await database;
    final currentUserResult = await db.query('current_user');

    if (currentUserResult.isNotEmpty) {
      String currentUserId = currentUserResult.first['userId'] as String;
      return await getUserById(currentUserId);
    }
    return null;
  }

  Future<void> clearSession() async {
    final db = await database;
    await db.delete('current_user');
    _currentUserController.add(null);
  }

  //====================================================================
  // DATA MANAGEMENT & CLEANUP
  //====================================================================

  // Method to clear all data from both SQLite and JSON file
  Future<void> clearAllData() async {
    // Clear all SQLite tables
    final db = await instance.database;
    await db.execute('DELETE FROM songs');
    await db.execute('DELETE FROM playlists');
    await db.execute('DELETE FROM albums');
    await db.execute('DELETE FROM users');

    // Clear JSON data by writing empty lists
    await fileStorageHelper.writeData('users.json', {'users': []});
    await fileStorageHelper.writeData('songs.json', {'songs': []});
    await fileStorageHelper.writeData('playlists.json', {'playlists': []});
    await fileStorageHelper.writeData('albums.json', {'albums': []});
  }

//====================================================================
// FILTERED SONG QUERIES
//====================================================================

  // Fetch songs and add to stream
  Future<void> _fetchSongs() async {
    final db = await database; // Assuming you have a `database` getter
    final result =
        await db.query('songs'); // Fetch all songs from the 'songs' table
    List<Song> songs = result.isNotEmpty
        ? result.map((songData) => Song.fromMap(songData)).toList()
        : [];
    _songsController.sink.add(songs);
  }

  // Add these methods inside the DatabaseHelper class
  Future<List<Song>> getSongsByArtist(String artistId) async {
    final db = await database;
    final maps = await db.query(
      'songs',
      where: 'artistId = ?',
      whereArgs: [artistId],
    );

    List<Song> songs = [];
    for (var map in maps) {
      Song song = Song.fromMap(map);

      // Fetch artist details
      User? artist = await getUserByArtistId(song.artistId);
      if (artist != null) {
        song.artistName = artist.fullName;
        song.profileImageUrl = artist.profileImageUrl;
        song.bioImageUrl = artist.bioImageUrl;
      }

      // Fetch album details
      Album? album = await getAlbumById(song.albumId);
      if (album != null) {
        song.albumName = album.albumName;
      }

      songs.add(song);
    }

    return songs;
  }

  Future<List<Song>> getSongsByAlbum(String albumId) async {
    final db = await database;
    final maps = await db.query(
      'songs',
      where: 'albumId = ?',
      whereArgs: [albumId],
    );

    List<Song> songs = [];
    for (var map in maps) {
      Song song = Song.fromMap(map);

      // Fetch artist details
      User? artist = await getUserByArtistId(song.artistId);
      if (artist != null) {
        song.artistName = artist.fullName;
        song.profileImageUrl = artist.profileImageUrl;
        song.bioImageUrl = artist.bioImageUrl;
      }

      // Fetch album details
      Album? album = await getAlbumById(song.albumId);
      if (album != null) {
        song.albumName = album.albumName;
      }

      songs.add(song);
    }

    return songs;
  }

  Future<List<Song>> getSongsByPlaylist(String playlistId) async {
    final db = await database;

    // First get the playlist to access its songListIds
    final Playlist? playlist = await getPlaylistById(playlistId);
    if (playlist == null || playlist.songListIds == null) {
      return [];
    }

    // Since songListIds is already a List<String>, no need to split
    List<String> songIds = playlist.songListIds!;

    List<Song> songs = [];

    // Fetch each song by its ID
    for (String songId in songIds) {
      final maps = await db.query(
        'songs',
        where: 'songId = ?',
        whereArgs: [songId],
      );

      if (maps.isNotEmpty) {
        Song song = Song.fromMap(maps.first);

        // Fetch artist details
        User? artist = await getUserByArtistId(song.artistId);
        if (artist != null) {
          song.artistName = artist.fullName;
          song.profileImageUrl = artist.profileImageUrl;
          song.bioImageUrl = artist.bioImageUrl;
        }

        // Fetch album details
        Album? album = await getAlbumById(song.albumId);
        if (album != null) {
          song.albumName = album.albumName;
        }

        songs.add(song);
      }
    }

    return songs;
  }

  Future<List<Song>> getLikedSongs(String userId) async {
    final db = await database;

    // First get the user to access their liked songs
    final User? user = await getUserById(userId);
    if (user == null) {
      return [];
    }

    // Since userLikedSongs is already a List<String>, no need to split
    List<String> likedSongIds = user.userLikedSongs;

    List<Song> songs = [];

    // Fetch each liked song by its ID
    for (String songId in likedSongIds) {
      final maps = await db.query(
        'songs',
        where: 'songId = ?',
        whereArgs: [songId],
      );

      if (maps.isNotEmpty) {
        Song song = Song.fromMap(maps.first);

        // Fetch artist details
        User? artist = await getUserByArtistId(song.artistId);
        if (artist != null) {
          song.artistName = artist.fullName;
          song.profileImageUrl = artist.profileImageUrl;
          song.bioImageUrl = artist.bioImageUrl;
        }

        // Fetch album details
        Album? album = await getAlbumById(song.albumId);
        if (album != null) {
          song.albumName = album.albumName;
        }

        songs.add(song);
      }
    }

    return songs;
  }

  // Example method to fetch songs by artist in real-time (stream)
  Stream<List<Song>> songsByArtistStream(String artistId) {
    // Fetch songs by artist in real-time
    _fetchSongsByArtist(artistId);
    return _songsController.stream;
  }

  Future<void> _fetchSongsByArtist(String artistId) async {
    final db = await database; // Assuming you have an `database` getter
    final result = await db.query(
      'songs',
      where: 'artistId = ?',
      whereArgs: [artistId],
    );
    List<Song> songs = result.isNotEmpty
        ? result.map((songData) => Song.fromMap(songData)).toList()
        : [];

    _songsController.sink.add(songs);
  }

  // Define the other methods similarly
  Stream<List<Song>> songsByAlbumStream(String albumId) {
    _fetchSongsByAlbum(albumId);
    return _songsController.stream;
  }

  Future<void> _fetchSongsByAlbum(String albumId) async {
    final db = await database;
    final result = await db.query(
      'songs',
      where: 'albumId = ?',
      whereArgs: [albumId],
    );
    List<Song> songs = result.isNotEmpty
        ? result.map((songData) => Song.fromMap(songData)).toList()
        : [];
    _songsController.sink.add(songs);
  }

  Stream<List<Song>> songsByPlaylistStream(String playlistId) {
    _fetchSongsByPlaylist(playlistId);
    return _songsController.stream;
  }

  Future<void> _fetchSongsByPlaylist(String playlistId) async {
    final db = await database;
    final result = await db.query(
      'songs',
      where: 'playlistId = ?',
      whereArgs: [playlistId],
    );
    List<Song> songs = result.isNotEmpty
        ? result.map((songData) => Song.fromMap(songData)).toList()
        : [];
    _songsController.sink.add(songs);
  }

  Stream<List<Song>> likedSongsStream(String userId) {
    _fetchLikedSongs(userId);
    return _songsController.stream;
  }

  Future<void> _fetchLikedSongs(String userId) async {
    final db = await database;
    final result = await db.query(
      'songs',
      where: 'likeIds LIKE ?',
      whereArgs: ['%$userId%'], // Assuming likeIds is a list stored as a string
    );
    List<Song> songs = result.isNotEmpty
        ? result.map((songData) => Song.fromMap(songData)).toList()
        : [];
    _songsController.sink.add(songs);
  }

  // Don't forget to close stream controllers
  void dispose() {
    _songsController.close();
    _playlistsController.close();
    _albumsController.close();
    _usersController.close();
    _currentUserController.close();
  }
}
