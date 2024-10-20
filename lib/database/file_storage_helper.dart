import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:soundify/database/database_helper.dart';

class FileStorageHelper {
  static final FileStorageHelper instance = FileStorageHelper._init();
  FileStorageHelper._init();

  // Menggunakan named constructor instance

  Future<String> _getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();

    // Membuat sub-direktori di dalam direktori dokumen
    final soundifyDir =
        Directory('${directory.path}/soundify_database/soundify_json');

    if (!(await soundifyDir.exists())) {
      // Membuat direktori secara rekursif jika belum ada
      await soundifyDir.create(recursive: true);
    }

    return soundifyDir.path;
  }

  Future<File> _getLocalFile(String filename) async {
    final path = await _getLocalPath();
    return File('$path/$filename');
  }

  Future<File> writeData(String filename, Map<String, dynamic> data) async {
    final file = await _getLocalFile(filename);
    return file.writeAsString(json.encode(data));
  }

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
}
