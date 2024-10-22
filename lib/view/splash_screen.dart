import 'package:flutter/material.dart';
import 'package:soundify/view/auth/login_page.dart';
import 'package:soundify/view/container/primary/home_container.dart';
import 'package:soundify/view/container/secondary/show_detail_song.dart';
import 'package:soundify/view/main_page.dart';
import 'package:soundify/view/style/style.dart';
import 'package:soundify/database/database_helper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserLoginStatus();
  }

  void _checkUserLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    final dbHelper = DatabaseHelper.instance;
    final user = await dbHelper.getCurrentUser();
    print('User: $user'); // Cek apakah user berhasil diambil

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MainPage(
            activeWidget1: HomeContainer(),
            activeWidget2: ShowDetailSong(),
          ),
        ),
      );
    } else {
      print('Navigating to LoginPage');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: const Center(
        child: CircularProgressIndicator(
          color: primaryTextColor,
        ),
      ),
    );
  }
}
