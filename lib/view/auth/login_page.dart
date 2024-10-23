import 'package:flutter/material.dart';
import 'package:soundify/database/database_helper.dart';
import 'package:soundify/models/user.dart';
import 'package:soundify/provider/auth_provider.dart';
import 'package:soundify/view/auth/signup_page.dart';
import 'package:soundify/view/splash_screen.dart';
import 'package:soundify/view/style/style.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final dbHelper = DatabaseHelper.instance;

  bool _isHoveredEmail = false;
  bool _isHoveredPassword = false;
  bool _isHoveredLoginButton = false;

  void clearTextFields() {
    emailController.clear();
    passwordController.clear();
  }

 Future<void> login() async {
  if (!validateFields()) {
    return;
  }

  try {
    print('Attempting to log in with email: ${emailController.text.trim()}');

    // Retrieve user by email and password
    User? user = await dbHelper.getUserByEmailAndPassword(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    if (user != null) {
      print('Login successful for user: ${user.username}');

      // Verifikasi user di database
      User? verifiedUser = await dbHelper.getUserById(user.userId);
      if (verifiedUser == null) {
        print('Error: User not found in database after successful login');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User data inconsistency')),
        );
        return;
      }

      // Simpan userId ke secure storage atau session
      await dbHelper.setCurrentUserId(user.userId);

      // Kirim data user ke AuthProvider
      Provider.of<AuthProvider>(context, listen: false).setCurrentUser(user);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const SplashScreen(),
        ),
      );
      clearTextFields();
    } else {
      print('Login failed: User not found');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email or password incorrect!')),
      );
    }
  } catch (e) {
    print('Login error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('An error occurred during login!')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Padding(
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
                    _isHoveredLoginButton = true;
                  }),
                  onExit: (event) => setState(() {
                    _isHoveredLoginButton = false;
                  }),
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isHoveredLoginButton
                            ? secondaryColor
                            : tertiaryColor,
                      ),
                      child: Text(
                        "Login",
                        style: TextStyle(
                          color: _isHoveredLoginButton
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
                    "Belum punya akun?",
                    style: TextStyle(color: primaryTextColor),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignUpPage()));
                    },
                    child: const Text(
                      "Sign up",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: secondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool validateFields() {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap lengkapi semua field!'),
        ),
      );
      return false;
    }
    return true;
  }
}
