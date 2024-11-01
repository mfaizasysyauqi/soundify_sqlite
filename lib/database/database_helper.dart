import 'dart:convert';
import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:soundify/models/album.dart';
import 'package:soundify/models/playlist.dart';
import 'package:soundify/models/song.dart';
import 'package:soundify/models/user.dart';
import 'file_storage_helper.dart'; // Import FileStorageHelper

// database_helper.dart
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static FileStorageHelper fileStorageHelper = FileStorageHelper.instance;
  DatabaseHelper._init();

  // Initialize the database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('soundify.db');
    return _database!;
  }

  // Create the database in the soundify_database folder
  Future<Database> _initDB(String fileName) async {
    final dbPath =
        await _getDatabaseDirectory(); // Custom function to get the path
    final path =
        join(dbPath, fileName); // Join the folder and database file name

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB, // Only use the onCreate callback
    );
  }

// Function to get or create the soundify_database folder in the Documents directory
  Future<String> _getDatabaseDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path,
        'soundify_database'); // Create soundify_database folder path

    final dir = Directory(path);
    if (!(await dir.exists())) {
      await dir.create(
          recursive: true); // Create the directory if it doesn't exist
    }

    return path; // Return the full path to the soundify_database folder
  }

  Future<List<Map<String, dynamic>>> query(String table) async {
    Database db = await instance.database;
    return await db.query(table);
  }

  Future _createDB(Database db, int version) async {
    // Create songs table
    await db.execute('''
    CREATE TABLE songs (
      songId TEXT PRIMARY KEY,
      senderId TEXT,
      artistId TEXT,
      albumId TEXT,
      songTitle TEXT,
      songImageUrl TEXT,
      songUrl TEXT,
      songDuration INTEGER,
      timestamp TEXT,
      artistSongIndex INTEGER,
      likeIds TEXT,
      playlistIds TEXT,
      albumIds TEXT,
      playedIds TEXT
    )
  ''');

    // Create playlists table
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

    // Create albums table
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

    // Create users table with corrected SQL syntax
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

    // Create current user table
    await db.execute('''
    CREATE TABLE current_user (
      userId TEXT PRIMARY KEY
    )
  ''');
  }

  // Method to get user by email and password
  Future<User?> getUserByEmailAndPassword(String email, String password) async {
    final users = await getUsers();
    // print('Retrieved users: $users');
    if (users.isNotEmpty) {
      try {
        final userMap = users.firstWhere(
          (u) => u['email'] == email && u['password'] == password,
          orElse: () => <String, dynamic>{},
        );
        // print('Found user: $userMap');
        if (userMap.isNotEmpty) {
          return User.fromMap(userMap);
        }
      } catch (e) {
        print('Error finding user: $e');
      }
    }
    return null;
  }

  // Helper method to handle both web and non-web platforms
  Future<int> update(String table, Map<String, dynamic> data, String where,
      List<dynamic> whereArgs) async {
    final db = await database;

    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  // Helper method to handle both web and non-web platforms
  Future<int> delete(
      String table, String where, List<dynamic> whereArgs) async {
    final db = await database;

    return await db.delete(table, where: where, whereArgs: whereArgs);
  }
// Add these methods to your DatabaseHelper class

  Future<bool> followUser(String followerId, String followedId) async {
    try {
      final db = await database;

      // Get both users
      final follower = await getUserById(followerId);
      final followed = await getUserById(followedId);

      if (follower == null || followed == null) return false;

      return await db.transaction((txn) async {
        // Update follower's following list
        List<String> following = List<String>.from(follower.following);
        if (!following.contains(followedId)) {
          following.add(followedId);
        }

        await txn.update(
          'users',
          {'following': following.join(',')},
          where: 'userId = ?',
          whereArgs: [followerId],
        );

        // Update followed user's followers list
        List<String> followers = List<String>.from(followed.followers);
        if (!followers.contains(followerId)) {
          followers.add(followerId);
        }

        await txn.update(
          'users',
          {'followers': followers.join(',')},
          where: 'userId = ?',
          whereArgs: [followedId],
        );

        return true;
      });
    } catch (e) {
      print('Error following user: $e');
      return false;
    }
  }

  Future<bool> unfollowUser(String followerId, String followedId) async {
    try {
      final db = await database;

      // Get both users
      final follower = await getUserById(followerId);
      final followed = await getUserById(followedId);

      if (follower == null || followed == null) return false;

      return await db.transaction((txn) async {
        // Update follower's following list
        List<String> following = List<String>.from(follower.following);
        following.remove(followedId);

        await txn.update(
          'users',
          {'following': following.join(',')},
          where: 'userId = ?',
          whereArgs: [followerId],
        );

        // Update followed user's followers list
        List<String> followers = List<String>.from(followed.followers);
        followers.remove(followerId);

        await txn.update(
          'users',
          {'followers': followers.join(',')},
          where: 'userId = ?',
          whereArgs: [followedId],
        );

        return true;
      });
    } catch (e) {
      print('Error unfollowing user: $e');
      return false;
    }
  }

  Future<bool> isFollowing(String followerId, String followedId) async {
    try {
      final follower = await getUserById(followerId);
      if (follower == null) return false;

      return follower.following.contains(followedId);
    } catch (e) {
      print('Error checking follow status: $e');
      return false;
    }
  }

  // **************************** CRUD Operations for Songs ****************************

  // Insert Song
  Future<int> insertSong(Song song) async {
    Database db = await instance.database;
    return await db.insert('songs', song.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<User?> getUserByArtistId(String artistId) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'userId = ?',
      whereArgs: [artistId],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

// Get all songs
  Future<List<Song>> getSongs() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('songs');

    List<Song> songs = [];
    for (var map in maps) {
      Song song = Song.fromMap(map);

      // Get artist details
      User? artist = await getUserByArtistId(song.artistId);
      if (artist != null) {
        song.artistName = artist.fullName;
        song.profileImageUrl = artist.profileImageUrl;
        song.bioImageUrl = artist.bioImageUrl;
      }

      // Get album details using albumId instead of artistId
      Album? album = await getAlbumById(song.albumId); // Updated here
      if (album != null) {
        song.albumName = album.albumName;
      }

      songs.add(song);
    }

    return songs;
  }

// Define method to get album by albumId
// Update the getAlbumById method to include all album details
  Future<Album?> getAlbumById(String? albumId) async {
    if (albumId == null) return null;

    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'albums',
      where: 'albumId = ?',
      whereArgs: [albumId],
    );

    if (maps.isNotEmpty) {
      Album album = Album.fromMap(maps.first);

      // Get creator (artist) details if needed
      User? creator = await getUserById(album.creatorId);
      if (creator != null) {
        // You can add additional creator details to the album if needed
        album.creatorName = creator.fullName;
      }

      return album;
    }
    return null;
  }

  // In DatabaseHelper class
  Future<List<Album>> getAlbumsByCreatorId(String creatorId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'albums',
      where: 'creatorId = ?',
      whereArgs: [creatorId],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return Album.fromMap(maps[i]);
    });
  }

  Future<bool> toggleAlbumLike(String albumId, String userId) async {
    final db = await database;

    try {
      return await db.transaction((txn) async {
        // Get album and user
        final album = await getAlbumById(albumId);
        final user = await getUserById(userId);

        if (album == null || user == null) return false;

        // Get current like lists
        List<String> albumLikeIds = album.albumLikeIds ?? [];
        List<String> userLikedAlbums = user.userLikedAlbums;

        // Check current like status
        bool isCurrentlyLiked = albumLikeIds.contains(userId);

        // Update lists based on current status
        if (isCurrentlyLiked) {
          albumLikeIds.remove(userId);
          userLikedAlbums.remove(albumId);
        } else {
          albumLikeIds.add(userId);
          userLikedAlbums.add(albumId);
        }

        // Update album
        await txn.update(
          'albums',
          {'albumLikeIds': albumLikeIds.join(',')},
          where: 'albumId = ?',
          whereArgs: [albumId],
        );

        // Update user
        await txn.update(
          'users',
          {'userLikedAlbums': userLikedAlbums.join(',')},
          where: 'userId = ?',
          whereArgs: [userId],
        );

        return !isCurrentlyLiked;
      });
    } catch (e) {
      print('Error toggling album like: $e');
      return false;
    }
  }

  Future<void> updateAlbum(Album album) async {
    final db = await database;
    await db.update(
      'albums',
      album.toMap(),
      where: 'albumId = ?',
      whereArgs: [album.albumId],
    );
  }

  // Get song by ID
  Future<Song?> getSongById(String id) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps =
        await db.query('songs', where: 'songId = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      Song song = Song.fromMap(maps.first);

      // Get artist details
      User? artist = await getUserByArtistId(song.artistId);
      if (artist != null) {
        song.artistName = artist.fullName;
        song.profileImageUrl = artist.profileImageUrl;
        song.bioImageUrl = artist.bioImageUrl;
      }

      // Get album details
      Album? album = await getAlbumByCreatorId(song.artistId);
      if (album != null) {
        song.albumName = album.albumName;
      }

      return song;
    }
    return null;
  }

  // Update Song
  Future<int> updateSong(Song song) async {
    Database db = await instance.database;
    return await db.update('songs', song.toMap(),
        where: 'songId = ?', whereArgs: [song.songId]);
  }

  // Delete Song
  Future<int> deleteSong(String id) async {
    Database db = await instance.database;
    return await db.delete('songs', where: 'songId = ?', whereArgs: [id]);
  }

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

  // **************************** CRUD Operations for Playlists ****************************

  // Insert Album
  Future<int> insertPlaylist(Playlist playlist) async {
    Database db = await instance.database;
    return await db.insert('playlists', playlist.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Mendapatkan semua playlists dari SQLite
  Future<List<Playlist>> getPlaylists() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('playlists');
    return List.generate(maps.length, (i) {
      return Playlist.fromMap(maps[i]);
    });
  }

  // Mendapatkan playlist berdasarkan ID dari SQLite
  Future<Playlist?> getPlaylistById(String id) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'playlists',
      where: 'playlistId = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      Playlist playlist = Playlist.fromMap(maps.first);

      // Get creator (artist) details if needed
      User? creator = await getUserById(playlist.creatorId);
      if (creator != null) {
        // You can add additional creator details to the playlist if needed
        playlist.creatorName = creator.fullName;
      }

      return playlist;
    }
    return null;
  }

// Di dalam class DatabaseHelper
  Future<List<Playlist>> getPlaylistsByCreatorId(String creatorId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'playlists',
      where: 'creatorId = ?',
      whereArgs: [creatorId],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return Playlist.fromMap(maps[i]);
    });
  }

  Future<bool> togglePlaylistLike(String playlistId, String userId) async {
    final db = await database;

    try {
      return await db.transaction((txn) async {
        // Get playlist and user
        final playlist = await getPlaylistById(playlistId);
        final user = await getUserById(userId);

        if (playlist == null || user == null) return false;

        // Get current like lists
        List<String> playlistLikeIds = playlist.playlistLikeIds ?? [];
        List<String> userLikedPlaylists = user.userLikedPlaylists;

        // Check current like status
        bool isCurrentlyLiked = playlistLikeIds.contains(userId);

        // Update lists based on current status
        if (isCurrentlyLiked) {
          playlistLikeIds.remove(userId);
          userLikedPlaylists.remove(playlistId);
        } else {
          playlistLikeIds.add(userId);
          userLikedPlaylists.add(playlistId);
        }

        // Update playlist
        await txn.update(
          'playlists',
          {'playlistLikeIds': playlistLikeIds.join(',')},
          where: 'playlistId = ?',
          whereArgs: [playlistId],
        );

        // Update user
        await txn.update(
          'users',
          {'userLikedPlaylists': userLikedPlaylists.join(',')},
          where: 'userId = ?',
          whereArgs: [userId],
        );

        return !isCurrentlyLiked;
      });
    } catch (e) {
      print('Error toggling playlist like: $e');
      return false;
    }
  }

  // Update Playlist
  Future<int> updatePlaylist(Playlist playlist) async {
    final db = await database;
    return await db.update(
      'playlists',
      {
        ...playlist.toMap(),
        'songListIds': playlist.songListIds?.join(',') ??
            '', // Pastikan konversi ke string dengan benar
      },
      where: 'playlistId = ?',
      whereArgs: [playlist.playlistId],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Delete Playlist
  Future<void> deletePlaylist(String playlistId) async {
    final db = await instance.database;

    // Start a transaction to ensure all operations complete together
    await db.transaction((txn) async {
      try {
        // First get the playlistUserIndex of the playlist to be deleted
        final List<Map<String, dynamic>> result = await txn.query(
          'playlists',
          columns: ['playlistUserIndex'],
          where: 'playlistId = ?',
          whereArgs: [playlistId],
        );

        if (result.isEmpty) {
          throw Exception('Playlist not found');
        }

        final int deletedIndex = result.first['playlistUserIndex'];

        // Delete the playlist
        await txn.delete(
          'playlists',
          where: 'playlistId = ?',
          whereArgs: [playlistId],
        );

        // Update playlistUserIndex for all playlists with higher index
        await txn.rawUpdate('''
        UPDATE playlists 
        SET playlistUserIndex = playlistUserIndex - 1 
        WHERE playlistUserIndex > ?
      ''', [deletedIndex]);
      } catch (e) {
        print('Error in deletePlaylist transaction: $e');
        rethrow;
      }
    });
  }

  // **************************** CRUD Operations for Albums ****************************

  // Insert Album
  Future<int> insertAlbum(Album album) async {
    Database db = await instance.database;
    return await db.insert('albums', album.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Get all albums
  Future<List<Album>> getAlbums() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('albums');

    return List.generate(maps.length, (i) {
      return Album.fromMap(maps[i]);
    });
  }

  // Get album by ID
  Future<Album?> getAlbumByCreatorId(String creatorId) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'albums',
      where: 'creatorId = ?',
      whereArgs: [creatorId],
    );

    if (maps.isNotEmpty) {
      return Album.fromMap(maps.first);
    }
    return null;
  }

  // Delete Album
  Future<void> deleteAlbum(String albumId) async {
    final db = await instance.database;

    // Start a transaction to ensure all operations complete together
    await db.transaction((txn) async {
      try {
        // First get the albumUserIndex of the album to be deleted
        final List<Map<String, dynamic>> result = await txn.query(
          'albums',
          columns: ['albumUserIndex'],
          where: 'albumId = ?',
          whereArgs: [albumId],
        );

        if (result.isEmpty) {
          throw Exception('Album not found');
        }

        final int deletedIndex = result.first['albumUserIndex'];

        // Delete the album
        await txn.delete(
          'albums',
          where: 'albumId = ?',
          whereArgs: [albumId],
        );

        // Update albumUserIndex for all albums with higher index
        await txn.rawUpdate('''
        UPDATE albums 
        SET albumUserIndex = albumUserIndex - 1 
        WHERE albumUserIndex > ?
      ''', [deletedIndex]);
      } catch (e) {
        print('Error in deleteAlbum transaction: $e');
        rethrow;
      }
    });
  }
  // **************************** CRUD Operations for Users ****************************

  // Update insertUser method
  Future<void> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    await db.insert(
      'users',
      user,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // Also save to JSON file
    await FileStorageHelper.instance.addUser(user);
  }

  Future<void> insertCurrentUser(String userId) async {
    final db = await instance.database;
    await db.insert(
      'current_user',
      {'userId': userId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Membaca data user dari file lokal
  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return await db.query('users');
  }

  // Check if email (username) is already used
  Future<bool> isUsernameUsed(String username) async {
    // Periksa di SQLite
    List<Map<String, dynamic>> existingUsers = await getUsersFromSQLite();
    for (var user in existingUsers) {
      if (user['username'] == username) {
        return true;
      }
    }

    // Periksa di file JSON
    List<Map<String, dynamic>> jsonUsers = await getUsersFromJson();
    for (var user in jsonUsers) {
      if (user['username'] == username) {
        return true;
      }
    }

    return false; // Username tidak digunakan
  }

  Future<bool> isEmailUsed(String email) async {
    // Periksa di SQLite
    List<Map<String, dynamic>> existingUsers = await getUsersFromSQLite();
    for (var user in existingUsers) {
      if (user['email'] == email) {
        return true;
      }
    }

    // Periksa di file JSON
    List<Map<String, dynamic>> jsonUsers = await getUsersFromJson();
    for (var user in jsonUsers) {
      if (user['email'] == email) {
        return true;
      }
    }

    return false; // Username tidak digunakan
  }

  // Method to store the current logged-in user ID
  Future<void> setCurrentUserId(String userId) async {
    final db = await instance.database;
    await db.insert('current_user', {'userId': userId},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Method to retrieve the current logged-in user
  Future<User?> getCurrentUser() async {
    final db = await instance.database;
    final currentUserResult = await db.query('current_user');
    // print("Current user query result: $currentUserResult");

    if (currentUserResult.isNotEmpty) {
      String currentUserId = currentUserResult.first['userId'] as String;
      // print("Current user ID: $currentUserId");

      // Query the users table with the currentUserId
      final userResult = await db.query(
        'users',
        where: 'userId = ?',
        whereArgs: [currentUserId],
      );
      // print("User query result: $userResult");

      if (userResult.isNotEmpty) {
        return User.fromMap(userResult.first);
      } else {
        print("No user found with ID: $currentUserId");
      }
    } else {
      print("No current user set in the database");
    }
    return null;
  }

  // This method can be kept as a utility, but it's not necessary for getting the current user
  Future<User?> getUserById(String userId) async {
    final db = await instance.database;
    // print("Fetching user with ID: $userId");
    final result = await db.query(
      'users',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    // print("Query result: $result");

    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    } else {
      print("No user found with ID: $userId");
      return null;
    }
  }

  Future<void> saveSession(String userId) async {
    Database db = await instance.database;
    await db.insert('current_user', {'userId': userId});
  }

  Future<void> clearSession() async {
    final db = await instance.database;
    try {
      await db.delete('current_user');
    } catch (e) {
      print('Error clearing current_user: $e');
    }
  }

  Future<String?> getCurrentUserId() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.query('current_user');

    if (result.isNotEmpty) {
      return result.first['userId'] as String;
    }
    return null;
  }

  // Update the getUsersFromSQLite method to actually fetch users from SQLite
  Future<List<Map<String, dynamic>>> getUsersFromSQLite() async {
    Database db = await instance.database;
    return await db.query('users');
  }

  Future<List<Map<String, dynamic>>> getUsersFromJson() async {
    Map<String, dynamic>? data =
        await FileStorageHelper.instance.readData('users.json');
    if (data != null) {
      return List<Map<String, dynamic>>.from(data['users']);
    }
    final db = await database;
    return await db.query('users');
  }

  // Get songs by artist
// Get songs by artist
  Future<List<Song>> getSongsByArtist(String artistId) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'songs',
      where: 'artistId = ?',
      whereArgs: [artistId],
    );

    List<Song> artistSongs = [];
    for (var map in maps) {
      Song song = Song.fromMap(map);

      // Get artist details
      User? artist = await getUserByArtistId(song.artistId);
      if (artist != null) {
        song.artistName = artist.fullName;
        song.profileImageUrl = artist.profileImageUrl;
        song.bioImageUrl = artist.bioImageUrl;
      }

      // Get album details using albumId
      Album? album = await getAlbumById(song.albumId);
      if (album != null) {
        song.albumName = album.albumName;
      }

      artistSongs.add(song);
    }

    return artistSongs;
  }

  // Get songs by album
  Future<List<Song>> getSongsByAlbum(String albumId) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'songs',
      where: 'albumId = ?',
      whereArgs: [albumId],
    );
    List<Song> albumIds = [];
    for (var map in maps) {
      Song song = Song.fromMap(map);

      // Get artist details
      User? artist = await getUserByArtistId(song.artistId);
      if (artist != null) {
        song.artistName = artist.fullName;
        song.profileImageUrl = artist.profileImageUrl;
        song.bioImageUrl = artist.bioImageUrl;
      }

      // Get album details using albumId instead of artistId
      Album? album = await getAlbumById(song.albumId); // Updated here
      if (album != null) {
        song.albumName = album.albumName;
      }

      albumIds.add(song);
    }

    return albumIds;
  }

// Get songs by playlist
  Future<List<Song>> getSongsByPlaylist(String playlistId) async {
    Database db = await instance.database;
    final playlist = await getPlaylistById(playlistId);

    if (playlist != null && playlist.songListIds!.isNotEmpty) {
      final List<Map<String, dynamic>> maps = await db.query(
        'songs',
        where:
            'songId IN (${playlist.songListIds?.map((_) => '?').join(', ')})',
        whereArgs: playlist.songListIds,
      );

      List<Song> songs = [];
      for (var map in maps) {
        Song song = Song.fromMap(map);

        // Get album details using albumId
        Album? album = await getAlbumById(song.albumId);
        if (album != null) {
          song.albumName = album.albumName; // Set album name on the song
        }

        // Get artist details using artistId
        User? artist = await getUserById(song.artistId);
        if (artist != null) {
          song.artistName = artist.fullName; // Set artist name on the song
        }

        songs.add(song);
      }

      return songs;
    }
    return [];
  }

// database_helper.dart
  Future<bool> removeSongFromPlaylist(String songId, String playlistId) async {
    try {
      final db = await database;

      // Get the playlist
      final playlist = await getPlaylistById(playlistId);
      if (playlist == null) return false;

      // Remove songId from playlist's songListIds
      final updatedSongListIds = List<String>.from(playlist.songListIds ?? [])
        ..remove(songId);

      // Update playlist
      await db.update(
        'playlists',
        {'songListIds': jsonEncode(updatedSongListIds)},
        where: 'playlistId = ?',
        whereArgs: [playlistId],
      );

      // Get the song
      final song = await getSongById(songId);
      if (song == null) return false;

      // Remove playlistId from song's playlistIds
      final updatedPlaylistIds = List<String>.from(song.playlistIds ?? [])
        ..remove(playlistId);

      // Update song
      await db.update(
        'songs',
        {'playlistIds': jsonEncode(updatedPlaylistIds)},
        where: 'songId = ?',
        whereArgs: [songId],
      );

      return true;
    } catch (e) {
      print('Error removing song from playlist: $e');
      return false;
    }
  }

  // Get liked songs
  Future<List<Song>> getLikedSongs(String userId) async {
    Database db = await instance.database;
    final user = await getUserById(userId);

    if (user != null && user.userLikedSongs.isNotEmpty) {
      final List<Map<String, dynamic>> maps = await db.query(
        'songs',
        where: 'songId IN (${user.userLikedSongs.map((_) => '?').join(', ')})',
        whereArgs: user.userLikedSongs,
      );

      List<Song> likedSongs = [];
      for (var map in maps) {
        Song song = Song.fromMap(map);

        // Get artist details
        User? artist = await getUserByArtistId(song.artistId);
        if (artist != null) {
          song.artistName = artist.fullName;
          song.profileImageUrl = artist.profileImageUrl;
          song.bioImageUrl = artist.bioImageUrl;
        }

        // Get album details using albumId instead of artistId
        Album? album = await getAlbumById(song.albumId); // Updated here
        if (album != null) {
          song.albumName = album.albumName;
        }

        likedSongs.add(song);
      }

      return likedSongs;
    }
    return [];
  }

  // Update User
  Future<int> updateUser(User user) async {
    final db = await database;
    int result = await db.update(
      'users',
      user.toMap(),
      where: 'userId = ?',
      whereArgs: [user.userId],
    );

    // Update JSON file after successful SQLite update
    if (result > 0) {
      await FileStorageHelper.instance.updateJsonWithLatestUser();
    }

    return result;
  }

  // Delete User
  Future<int> deleteUser(String id) async {
    Database db = await instance.database;
    return await db.delete('users', where: 'userId = ?', whereArgs: [id]);
  }

  // Menambahkan user baru ke database (file JSON)
  Future<void> addUser(Map<String, dynamic> user) async {
    List<Map<String, dynamic>> users = await getUsers();
    users.add(user);
    await fileStorageHelper.writeData('users.json', {'users': users});
    // print('User added to local file: $user');
    // print(
    //     'All users in local file: ${await fileStorageHelper.readData('users.json')}');
  }

  // Menghapus semua data dari file JSON
  Future<void> clearAllUsers() async {
    // Tulis data kosong ke file
    await FileStorageHelper.instance.writeData('users.json', {'users': []});
  }

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

  /// Initializes and retrieves all necessary data from the database
  Future<Map<String, dynamic>> initializeAllData() async {
    try {
      // Get current user first
      final currentUser = await getCurrentUser();

      if (currentUser == null) {
        return {
          'currentUser': null,
          'users': [],
          'songs': [],
          'playlists': [],
          'albums': [],
          'userLikedSongs': [],
          'userSongs': [],
          'albumSongs': []
        };
      }

      // Get all basic data
      final List<Map<String, dynamic>> users = await getUsers();
      final List<Song> allSongs = await getSongs();
      final List<Playlist> playlists = await getPlaylists();
      final List<Album> albums = await getAlbums();

      // Get user-specific data
      final List<Song> likedSongs = await getLikedSongs(currentUser.userId);
      final List<Song> userSongs = await getSongsByArtist(currentUser.userId);

      // Get songs for each album
      Map<String, List<Song>> albumSongs = {};
      for (var album in albums) {
        albumSongs[album.albumId] = await getSongsByAlbum(album.albumId);
      }

      // Get songs for each playlist
      Map<String, List<Song>> playlistSongs = {};
      for (var playlist in playlists) {
        playlistSongs[playlist.playlistId] =
            await getSongsByPlaylist(playlist.playlistId);
      }

      // Return all data in a structured map
      return {
        'currentUser': currentUser,
        'users': users,
        'songs': allSongs,
        'playlists': playlists,
        'albums': albums,
        'userLikedSongs': likedSongs,
        'userSongs': userSongs,
        'albumSongs': albumSongs,
        'playlistSongs': playlistSongs
      };
    } catch (e) {
      print('Error initializing data: $e');
      throw Exception('Failed to initialize data: $e');
    }
  }
}
