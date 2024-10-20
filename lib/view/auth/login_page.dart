import 'package:flutter/material.dart';
import 'package:soundify/database/database_helper.dart';
import 'package:soundify/models/user.dart';
import 'package:soundify/view/auth/signup_page.dart';
import 'package:soundify/view/main_page.dart';
import 'package:soundify/view/style/style.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final dbHelper = DatabaseHelper.instance;
  bool _isHovered1 = false;
  bool _isHovered2 = false;
  bool _isHovered3 = false;

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

        // Double-check if the user exists in the database
        User? verifiedUser = await dbHelper.getUserById(user.userId);
        if (verifiedUser == null) {
          print('Error: User not found in database after successful login');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: User data inconsistency')),
          );
          return;
        }

        // Store the userId in secure storage (or a session variable)
        await dbHelper.setCurrentUserId(user.userId);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainPage()),
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
                    _isHovered1 = true;
                  }),
                  onExit: (event) => setState(() {
                    _isHovered1 = false;
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
                          color: _isHovered1 ? secondaryColor : senaryColor,
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
                    _isHovered2 = true;
                  }),
                  onExit: (event) => setState(() {
                    _isHovered2 = false;
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
                          color: _isHovered2 ? secondaryColor : senaryColor,
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
                    _isHovered3 = true;
                  }),
                  onExit: (event) => setState(() {
                    _isHovered3 = false;
                  }),
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isHovered3 ? secondaryColor : tertiaryColor,
                      ),
                      child: Text(
                        "Login",
                        style: TextStyle(
                          color: _isHovered3 ? tertiaryColor : secondaryColor,
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
