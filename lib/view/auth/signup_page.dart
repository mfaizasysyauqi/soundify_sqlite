import 'package:flutter/material.dart';
import 'package:soundify/database/database_helper.dart';
import 'package:soundify/database/file_storage_helper.dart';
import 'package:soundify/models/user.dart';
import 'package:soundify/view/auth/login_page.dart';
import 'package:soundify/view/style/style.dart';
import 'package:uuid/uuid.dart'; // Add this import

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final fullNameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final dbHelper = DatabaseHelper.instance;

  bool _isHoveredEmail = false;
  bool _isHoveredPassword = false;
  bool _isHoveredFullName = false;
  bool _isHoveredUsername = false;
  bool _isHoveredSignUpButton = false;

  Future<void> signUp() async {
    if (!validateFields()) {
      return;
    }

    bool isUsernameUsed = await DatabaseHelper.instance
        .isUsernameUsed(usernameController.text.trim());
    if (isUsernameUsed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username sudah digunakan sebelumnya!'),
        ),
      );
      return;
    }

    bool isEmailUsed =
        await DatabaseHelper.instance.isEmailUsed(emailController.text.trim());
    if (isEmailUsed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email sudah digunakan sebelumnya!'),
        ),
      );
      return;
    }

    try {
      final uuid = const Uuid();
      final userId = uuid.v4();

      final newUser = User(
        userId: userId,
        fullName: fullNameController.text.trim(),
        username: usernameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        profileImageUrl: '',
        bioImageUrl: '',
        bio: '',
        role: 'user',
        followers: [],
        following: [],
        userLikedSongs: [],
        userLikedAlbums: [],
        userLikedPlaylists: [],
        lastListenedSongId: '',
        lastVolumeLevel: 0.5,
      );

      // Save to SQLite
      await DatabaseHelper.instance.insertUser(newUser.toMap());

      // Save to JSON file
      // await FileStorageHelper.instance.addUser(newUser.toMap());

      // Update JSON with latest user
      await FileStorageHelper.instance.updateJsonWithLatestUser();

      print('User signed up successfully: ${newUser.username}');
      print('User details: ${newUser.toMap()}');

      // Set current user
      // await DatabaseHelper.instance.setCurrentUserId(userId);

      // Verify user was added
      final users = await DatabaseHelper.instance.getUsers();
      print('All users after signup: $users');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      print('Error during sign up: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terjadi kesalahan saat mendaftar!'),
        ),
      );
    }
  }

  bool validateFields() {
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        fullNameController.text.isEmpty ||
        usernameController.text.isEmpty) {
      showErrorMessage('Harap lengkapi semua field!');
      return false;
    }

    if (!isValidEmail(emailController.text)) {
      showErrorMessage('Format email tidak valid!');
      return false;
    }

    if (!isValidPassword(passwordController.text)) {
      showErrorMessage(
          'Password harus minimal 6 karakter dan mengandung huruf dan angka!');
      return false;
    }

    return true;
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email) &&
        (email.endsWith('.com') || email.endsWith('.co.id'));
  }

  bool isValidPassword(String password) {
    final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{6,}$');
    return passwordRegex.hasMatch(password);
  }

  void showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Spacer(),
            const Column(
              children: [
                Center(
                  child: Center(
                    child: Text(
                      'Soundify',
                      style: TextStyle(
                        fontSize: 64,
                        color: secondaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: MouseRegion(
                onEnter: (event) => setState(() {
                  _isHoveredEmail = true;
                }),
                onExit: (event) => setState(() {
                  _isHoveredEmail = false;
                }),
                child: TextFormField(
                  style: const TextStyle(color: primaryTextColor),
                  controller: emailController,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(8),
                    hintText: 'Enter your email',
                    hintStyle: const TextStyle(color: primaryTextColor),
                    border: const OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: primaryTextColor,
                      ),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                        color: secondaryColor,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _isHoveredEmail ? secondaryColor : senaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: MouseRegion(
                onEnter: (event) => setState(() {
                  _isHoveredPassword = true;
                }),
                onExit: (event) => setState(() {
                  _isHoveredPassword = false;
                }),
                child: TextFormField(
                  style: const TextStyle(color: primaryTextColor),
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(8),
                    hintText: 'Enter your password',
                    hintStyle: const TextStyle(color: primaryTextColor),
                    border: const OutlineInputBorder(
                      borderSide: BorderSide(
                        color: primaryTextColor,
                      ),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                        color: secondaryColor,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color:
                            _isHoveredPassword ? secondaryColor : senaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: MouseRegion(
                onEnter: (event) => setState(() {
                  _isHoveredFullName = true;
                }),
                onExit: (event) => setState(() {
                  _isHoveredFullName = false;
                }),
                child: TextFormField(
                  style: const TextStyle(color: primaryTextColor),
                  controller: fullNameController,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(8),
                    hintText: 'Enter your full name',
                    hintStyle: const TextStyle(color: primaryTextColor),
                    border: const OutlineInputBorder(
                      borderSide: BorderSide(
                        color: primaryTextColor,
                      ),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                        color: secondaryColor,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color:
                            _isHoveredFullName ? secondaryColor : senaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: MouseRegion(
                onEnter: (event) => setState(() {
                  _isHoveredUsername = true;
                }),
                onExit: (event) => setState(() {
                  _isHoveredUsername = false;
                }),
                child: TextFormField(
                  style: const TextStyle(color: primaryTextColor),
                  controller: usernameController,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(8),
                    hintText: 'Enter your username',
                    hintStyle: const TextStyle(color: primaryTextColor),
                    border: const OutlineInputBorder(
                      borderSide: BorderSide(
                        color: primaryTextColor,
                      ),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                        color: secondaryColor,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color:
                            _isHoveredUsername ? secondaryColor : senaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: MouseRegion(
                onEnter: (event) => setState(() {
                  _isHoveredSignUpButton = true;
                }),
                onExit: (event) => setState(() {
                  _isHoveredSignUpButton = false;
                }),
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isHoveredSignUpButton
                          ? secondaryColor
                          : tertiaryColor,
                    ),
                    child: Text(
                      "Sign up",
                      style: TextStyle(
                        color: _isHoveredSignUpButton
                            ? tertiaryColor
                            : secondaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Sudah punya akun?",
                  style: TextStyle(color: primaryTextColor),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()));
                  },
                  child: const Text(
                    "Login",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: secondaryColor,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
