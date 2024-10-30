import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:soundify/database/database_helper.dart';
import 'package:path/path.dart' as path; // Add this import

// file_storage_helper.dart
class FileStorageHelper {
  static final FileStorageHelper instance = FileStorageHelper._init();
  FileStorageHelper._init();
  // Constants for path segments
  static const String _baseFolderName = 'soundify_database';
  static const String _imagesFolderName = 'images';
  static const String _profilesFolderName = 'profiles';
  static const String _biosFolderName = 'bios';

  Future<void> addUser(Map<String, dynamic> newUser) async {
    try {
      final file = await _getLocalFile('users.json');
      Map<String, dynamic> data;
      if (await file.exists()) {
        String contents = await file.readAsString();
        data = json.decode(contents);
      } else {
        data = {'users': []};
      }

      List<dynamic> users = data['users'];

      // Cek apakah username atau email sudah ada
      bool isDuplicate = users.any((user) =>
          user['username'] == newUser['username'] ||
          user['email'] == newUser['email']);

      if (isDuplicate) {
        print('Username atau email sudah digunakan!');
        return;
      }

      // Tambahkan user jika tidak ada duplikasi
      users.add(newUser);
      await file.writeAsString(json.encode(data));
      print('User added to JSON file: $newUser');
    } catch (e) {
      print('Error adding user to JSON file: $e');
    }
  }

  Future<void> updateJsonWithLatestUser() async {
    try {
      List<Map<String, dynamic>> users =
          await DatabaseHelper.instance.getUsers();
      String jsonString = jsonEncode({'users': users});
      final file = await _getLocalFile('users.json');
      await file.writeAsString(jsonString);
    } catch (e) {
      print("Error updating JSON file: $e");
    }
  }

  Future<Map<String, dynamic>?> readData(String filename) async {
    try {
      final file = await _getLocalFile(filename);
      String contents = await file.readAsString();
      return json.decode(contents);
    } catch (e) {
      return null;
    }
  }

  // Method to save profile image and return the local path
  // In FileStorageHelper
  // Save bio image with separated logic
  Future<String> saveBioImage(String userId, String sourcePath) async {
    return _saveImage(
      userId: userId,
      sourcePath: sourcePath,
      subFolder: _biosFolderName,
      prefix: 'bio',
      deleteOld: true,
    );
  }

  Future<String> saveProfileImage(String userId, String sourcePath) async {
    return _saveImage(
      userId: userId,
      sourcePath: sourcePath,
      subFolder: _profilesFolderName,
      prefix: 'profile',
      deleteOld: true,
    );
  }

  // Generic image saving logic
  Future<String> _saveImage({
    required String userId,
    required String sourcePath,
    required String subFolder,
    required String prefix,
    bool deleteOld = true,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imageDir = Directory(path.join(
        directory.path,
        _baseFolderName,
        _imagesFolderName,
        subFolder,
      ));

      // Ensure directory exists
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }

      // Delete old image if requested
      if (deleteOld) {
        await _deleteOldImage(userId, subFolder, prefix);
      }

      // Generate new filename with timestamp
      final String fileName =
          '${prefix}_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String destinationPath = path.join(imageDir.path, fileName);

      // Copy file to new location
      final File newImage = await File(sourcePath).copy(destinationPath);
      return newImage.path;
    } catch (e) {
      print('Error saving $prefix image: $e');
      rethrow;
    }
  }

  // Generic method to delete old images
  Future<void> _deleteOldImage(
    String userId,
    String subFolder,
    String prefix,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(path.join(
        directory.path,
        _baseFolderName,
        _imagesFolderName,
        subFolder,
      ));

      if (await imagesDir.exists()) {
        final files = await imagesDir.list().toList();
        for (var file in files) {
          if (file is File && file.path.contains('${prefix}_$userId')) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      print('Error deleting old $prefix image: $e');
    }
  }

  // Get images for a specific type (profile or bio)
  Future<List<String>> getUserImages(String userId, String type) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(path.join(
        directory.path,
        _baseFolderName,
        _imagesFolderName,
        type == 'profile' ? _profilesFolderName : _biosFolderName,
      ));

      if (!await imagesDir.exists()) {
        return [];
      }

      final files = await imagesDir.list().toList();
      return files
          .where(
              (file) => file is File && file.path.contains('${type}_$userId'))
          .map((file) => file.path)
          .toList();
    } catch (e) {
      print('Error getting user $type images: $e');
      return [];
    }
  }

  // Update other methods to use path.join as well
  Future<String> _getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final soundifyDir = Directory(
        path.join(directory.path, 'soundify_database', 'soundify_json'));

    if (!(await soundifyDir.exists())) {
      await soundifyDir.create(recursive: true);
    }

    return soundifyDir.path;
  }

  Future<File> _getLocalFile(String filename) async {
    final dirPath = await _getLocalPath();
    return File(path.join(dirPath, filename));
  }

  Future<File> writeData(String filename, Map<String, dynamic> data) async {
    final file = await _getLocalFile(filename);
    return file.writeAsString(json.encode(data));
  }

  Future<void> clearAllImages() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir =
          Directory(path.join(directory.path, 'soundify_database', 'images'));
      if (await imagesDir.exists()) {
        await imagesDir.delete(recursive: true);
      }
    } catch (e) {
      print('Error clearing all images: $e');
    }
  }

  // Method to get image file from path
  Future<File?> getImageFile(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      print('Error getting image file: $e');
      return null;
    }
  }

  // Method to delete image
  Future<void> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  // Method to get all profile images for a user
  Future<List<String>> getUserProfileImages(String userId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(path.join(
        directory.path,
        'soundify_database',
        'images',
        'profiles',
      ));

      if (!await imagesDir.exists()) {
        return [];
      }

      final files = await imagesDir.list().toList();
      return files
          .where(
              (file) => file is File && file.path.contains('profile_$userId'))
          .map((file) => file.path)
          .toList();
    } catch (e) {
      print('Error getting user profile images: $e');
      return [];
    }
  }
}
