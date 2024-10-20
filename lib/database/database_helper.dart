import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:soundify/models/album.dart';
import 'package:soundify/models/playlist.dart';
import 'package:soundify/models/song.dart';
import 'package:soundify/models/user.dart';
import 'file_storage_helper.dart'; // Import FileStorageHelper

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

  Future _createDB(Database db, int version) async {
    // Create songs table
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

  // **************************** CRUD Operations for Songs ****************************

  // Insert Song
  Future<int> insertSong(Song song) async {
    Database db = await instance.database;
    return await db.insert('songs', song.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Get all songs
  Future<List<Song>> getSongs() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('songs');

    return List.generate(maps.length, (i) {
      return Song.fromMap(maps[i]);
    });
  }

  // Get song by ID
  Future<Song?> getSongById(String id) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps =
        await db.query('songs', where: 'songId = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Song.fromMap(maps.first);
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

  // **************************** CRUD Operations for Playlists ****************************

  // Insert Album
  Future<int> insertPlaylist(Playlist playlist) async {
    Database db = await instance.database;
    return await db.insert('playlists', playlist.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Get all playlists
  Future<List<Playlist>> getPlaylists() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('playlists');

    return List.generate(maps.length, (i) {
      return Playlist.fromMap(maps[i]);
    });
  }

  // Get playlist by ID
  Future<Playlist?> getPlaylistById(String id) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps =
        await db.query('playlists', where: 'playlistId = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Playlist.fromMap(maps.first);
    }
    return null;
  }

  // Update Playlist
  Future<int> updatePlaylist(Playlist playlist) async {
    Database db = await instance.database;
    return await db.update('playlists', playlist.toMap(),
        where: 'playlistId = ?', whereArgs: [playlist.playlistId]);
  }

  // Delete Playlist
  Future<int> deletePlaylist(String id) async {
    Database db = await instance.database;
    return await db
        .delete('playlists', where: 'playlistId = ?', whereArgs: [id]);
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
  Future<Album?> getAlbumById(String id) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps =
        await db.query('albums', where: 'albumId = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Album.fromMap(maps.first);
    }
    return null;
  }

  // Update Album
  Future<int> updateAlbum(Album album) async {
    Database db = await instance.database;
    return await db.update('albums', album.toMap(),
        where: 'albumId = ?', whereArgs: [album.albumId]);
  }

  // Delete Album
  Future<int> deleteAlbum(String id) async {
    Database db = await instance.database;
    return await db.delete('albums', where: 'albumId = ?', whereArgs: [id]);
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
    print("Current user query result: $currentUserResult");

    if (currentUserResult.isNotEmpty) {
      String currentUserId = currentUserResult.first['userId'] as String;
      print("Current user ID: $currentUserId");

      // Query the users table with the currentUserId
      final userResult = await db.query(
        'users',
        where: 'userId = ?',
        whereArgs: [currentUserId],
      );
      print("User query result: $userResult");

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
    print("Fetching user with ID: $userId");
    final result = await db.query(
      'users',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    print("Query result: $result");

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

  // Update User
  // DatabaseHelper.dart
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
}
