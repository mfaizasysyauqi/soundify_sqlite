import 'dart:io';

import 'package:flutter/material.dart';
import 'package:soundify/database/database_helper.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:soundify/provider/song_provider.dart';
import 'package:soundify/provider/widget_size_provider.dart';
import 'package:soundify/provider/widget_state_provider_1.dart';
import 'package:soundify/provider/widget_state_provider_2.dart';
import 'package:soundify/view/auth/login_page.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart'; // Tambahkan ini
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // print("Initializing SharedPreferences...");

  // Initialize FFI (desktop platforms only)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi; // Set the database factory to FFI
  }

  // Check if running on Windows, macOS, or Linux to initialize sqflite_common_ffi
  if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    // print("Initializing sqflite_common_ffi...");
    sqfliteFfiInit(); // Initialize ffi
    databaseFactory =
        databaseFactoryFfi; // Set the databaseFactory for ffi usage
  }

  // Initialize SQLite Database
  final dbHelper = DatabaseHelper.instance;
  try {
    print("Initializing Database...");
    await dbHelper.database; // Ensure database is initialized
    print("Database initialized successfully");
  } catch (e) {
    print('Error initializing database: $e');
  }

  // Initialize the window manager
  await windowManager.ensureInitialized();

  // Set minimum size for the window
  windowManager.setMinimumSize(const Size(600, 550));

  // Prevent window from being resized smaller than the minimum size
  windowManager.setResizable(true);

  // print("Running MyApp...");

  await DatabaseHelper.instance.clearAllData();
  print("Semua data pengguna telah dihapus.");

  // Gunakan MultiProvider di sini dengan provider terpisah
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WidgetSizeProvider()),
        ChangeNotifierProvider(create: (_) => WidgetStateProvider1()),
        ChangeNotifierProvider(create: (_) => WidgetStateProvider2()),
        ChangeNotifierProvider(create: (_) => SongProvider()),
      ],
      child: const MyApp(),
    ),
  );
  // print("MyApp is running");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Soundify',
      home: LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
