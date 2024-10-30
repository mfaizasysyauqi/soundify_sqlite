// import 'dart:io';
// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:path_provider/path_provider.dart';
// import 'package:soundify/database/database_helper.dart';

// // file_storage_helper.dart
// class FileStorageHelper {
//   static final FileStorageHelper instance = FileStorageHelper._init();
//   FileStorageHelper._init();

//   // Menggunakan named constructor instance

//   Future<String> _getLocalPath() async {
//     final directory = await getApplicationDocumentsDirectory();

//     // Membuat sub-direktori di dalam direktori dokumen
//     final soundifyDir =
//         Directory('${directory.path}/soundify_database/soundify_json');

//     if (!(await soundifyDir.exists())) {
//       // Membuat direktori secara rekursif jika belum ada
//       await soundifyDir.create(recursive: true);
//     }

//     return soundifyDir.path;
//   }

//   Future<File> _getLocalFile(String filename) async {
//     final path = await _getLocalPath();
//     return File('$path/$filename');
//   }

//   Future<File> writeData(String filename, Map<String, dynamic> data) async {
//     final file = await _getLocalFile(filename);
//     return file.writeAsString(json.encode(data));
//   }

//   Future<void> addUser(Map<String, dynamic> newUser) async {
//     try {
//       final file = await _getLocalFile('users.json');
//       Map<String, dynamic> data;
//       if (await file.exists()) {
//         String contents = await file.readAsString();
//         data = json.decode(contents);
//       } else {
//         data = {'users': []};
//       }

//       List<dynamic> users = data['users'];

//       // Cek apakah username atau email sudah ada
//       bool isDuplicate = users.any((user) =>
//           user['username'] == newUser['username'] ||
//           user['email'] == newUser['email']);

//       if (isDuplicate) {
//         print('Username atau email sudah digunakan!');
//         return;
//       }

//       // Tambahkan user jika tidak ada duplikasi
//       users.add(newUser);
//       await file.writeAsString(json.encode(data));
//       print('User added to JSON file: $newUser');
//     } catch (e) {
//       print('Error adding user to JSON file: $e');
//     }
//   }

//   Future<void> updateJsonWithLatestUser() async {
//     try {
//       List<Map<String, dynamic>> users =
//           await DatabaseHelper.instance.getUsers();
//       String jsonString = jsonEncode({'users': users});
//       final file = await _getLocalFile('users.json');
//       await file.writeAsString(jsonString);
//     } catch (e) {
//       print("Error updating JSON file: $e");
//     }
//   }

//   Future<Map<String, dynamic>?> readData(String filename) async {
//     try {
//       final file = await _getLocalFile(filename);
//       String contents = await file.readAsString();
//       return json.decode(contents);
//     } catch (e) {
//       return null;
//     }
//   }

//   // Method to save profile image and return the local path
//   Future<String> saveProfileImage(String userId, Uint8List imageData) async {
//     try {
//       // Create images directory if it doesn't exist
//       final directory = await getApplicationDocumentsDirectory();
//       final imagesDir =
//           Directory('${directory.path}/soundify_database/images/profiles');
//       if (!await imagesDir.exists()) {
//         await imagesDir.create(recursive: true);
//       }

//       // Generate unique filename using userId
//       final timestamp = DateTime.now().millisecondsSinceEpoch;
//       final filename = 'profile_${userId}_$timestamp.png';
//       final imagePath = '${imagesDir.path}/$filename';

//       // Save image file
//       final file = File(imagePath);
//       await file.writeAsBytes(imageData);

//       // Delete old profile image if exists
//       await _deleteOldProfileImage(userId);

//       return imagePath; // Return the local path to the saved image
//     } catch (e) {
//       print('Error saving profile image: $e');
//       rethrow;
//     }
//   }

//   // Helper method to delete old profile image
//   Future<void> _deleteOldProfileImage(String userId) async {
//     try {
//       final directory = await getApplicationDocumentsDirectory();
//       final imagesDir =
//           Directory('${directory.path}/soundify_database/images/profiles');
//       if (await imagesDir.exists()) {
//         final files = await imagesDir.list().toList();
//         for (var file in files) {
//           if (file is File && file.path.contains('profile_$userId')) {
//             await file.delete();
//           }
//         }
//       }
//     } catch (e) {
//       print('Error deleting old profile image: $e');
//     }
//   }

//   // Method to get image file from path
//   Future<File?> getImageFile(String imagePath) async {
//     try {
//       final file = File(imagePath);
//       if (await file.exists()) {
//         return file;
//       }
//       return null;
//     } catch (e) {
//       print('Error getting image file: $e');
//       return null;
//     }
//   }

//   // Method to delete image
//   Future<void> deleteImage(String imagePath) async {
//     try {
//       final file = File(imagePath);
//       if (await file.exists()) {
//         await file.delete();
//       }
//     } catch (e) {
//       print('Error deleting image: $e');
//     }
//   }

//   // Method to get all profile images for a user
//   Future<List<String>> getUserProfileImages(String userId) async {
//     try {
//       final directory = await getApplicationDocumentsDirectory();
//       final imagesDir =
//           Directory('${directory.path}/soundify_database/images/profiles');
//       if (!await imagesDir.exists()) {
//         return [];
//       }

//       final files = await imagesDir.list().toList();
//       return files
//           .where(
//               (file) => file is File && file.path.contains('profile_$userId'))
//           .map((file) => file.path)
//           .toList();
//     } catch (e) {
//       print('Error getting user profile images: $e');
//       return [];
//     }
//   }

//   // Method to clear all images
//   Future<void> clearAllImages() async {
//     try {
//       final directory = await getApplicationDocumentsDirectory();
//       final imagesDir = Directory('${directory.path}/soundify_database/images');
//       if (await imagesDir.exists()) {
//         await imagesDir.delete(recursive: true);
//       }
//     } catch (e) {
//       print('Error clearing all images: $e');
//     }
//   }
// }
