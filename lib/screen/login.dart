import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/screen/unknown-screen.dart';
import 'package:get/get.dart';
import 'package:sensors_plus/sensors_plus.dart'; // For gyroscope effect
import '../admin/home.dart';
import '../user/showroom.dart';
import '../screen/signup_page.dart';
import '../services/auth_services.dart';
import '../vendor/vendor_home.dart';
import 'forgot_password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordHidden = true;

  // Variables for parallax effect
  double _xOffset = 0.0;
  double _yOffset = 0.0;
  late StreamSubscription<GyroscopeEvent> _gyroscopeSubscription;

  @override
  void initState() {
    super.initState();
    _startGyroscope();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _gyroscopeSubscription.cancel(); // Cancel the gyroscope subscription
    super.dispose();
  }

  void _startGyroscope() {
    _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      if (mounted) {
        // Check if the widget is still mounted
        setState(() {
          _xOffset = event.x * 5; // Reduced multiplier for lighter effect
          _yOffset = event.y * 5; // Reduced multiplier for lighter effect
        });
      }
    });
  }

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showErrorDialog("Error", "Email and password cannot be empty.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? role = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (role != null) {
        debugPrint("✅ User role retrieved: $role");
        _navigateToHomeScreen(role);
      } else {
        _showErrorDialog('Login Failed', 'Invalid email or password.');
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      String errorMessage;

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found for that email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is badly formatted.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your connection.';
          break;
        default:
          errorMessage = 'An unexpected error occurred. Please try again.';
      }

      _showErrorDialog('Login Error', errorMessage);
    } catch (error) {
      setState(() => _isLoading = false);
      _showErrorDialog('Error', 'Something went wrong. Please try again.');
    }
  }

  void _navigateToHomeScreen(String role) {
    debugPrint("🔍 Navigating to home with role: $role");

    Widget homeScreen;
    switch (role.toLowerCase()) {
      case 'admin':
        homeScreen = const AdminHome();
        break;
      case 'vendor':
        homeScreen = const SellerHome();
        break;
      case 'user':
        homeScreen = const Showroom();
        break;
      default:
        homeScreen = const UnknownScreen();
    }

    Get.off(() => homeScreen);
  }

  void _showErrorDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(message, style: const TextStyle(fontSize: 14)),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevent resize when keyboard appears
      body: Stack(
        fit: StackFit.expand, // Make stack fill the entire screen
        children: [
          // Background Image with Light Parallax Effect
          Positioned.fill(
            child: OverflowBox(
              maxWidth: MediaQuery.of(context).size.width * 1.2,
              maxHeight: MediaQuery.of(context).size.height * 1.2,
              alignment: Alignment.center,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                transform: Matrix4.translationValues(_xOffset, _yOffset, 0),
                child: Container(
                  width: MediaQuery.of(context).size.width * 1.2,
                  height: MediaQuery.of(context).size.height * 1.2,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/images/d.jpg"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Dark Overlay
          Container(
            color: Colors.black.withOpacity(0.5),
          ),

          // Login Form
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20.0,
                  right: 20.0,
                  top: 20.0,
                  bottom: MediaQuery.of(context).viewInsets.bottom +
                      20.0, // Adjust padding when keyboard appears
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Image.asset(
                      "assets/images/SubaruLogo.png",
                      height: 100,
                    ),
                    const SizedBox(height: 40),

                    // Email Input Field
                    TextField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        hintText: "Email",
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.7)),
                        prefixIcon: Icon(Icons.email, color: Colors.white),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8), // More boxy
                          borderSide:
                              BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8), // More boxy
                          borderSide:
                              BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8), // More boxy
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Password Input Field
                    TextField(
                      controller: _passwordController,
                      style: const TextStyle(color: Colors.white),
                      obscureText: _isPasswordHidden,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        hintText: "Password",
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.7)),
                        prefixIcon: Icon(Icons.lock, color: Colors.white),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordHidden
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white,
                          ),
                          onPressed: () => setState(
                              () => _isPasswordHidden = !_isPasswordHidden),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8), // More boxy
                          borderSide:
                              BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8), // More boxy
                          borderSide:
                              BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8), // More boxy
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Forgot Password Link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            Get.to(() => const ForgotPasswordPage()),
                        child: Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Login Button
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : SizedBox(
                            width: double.infinity, // Make button full width
                            child: ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                              ),
                              child: const Text(
                                "Login",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                    const SizedBox(height: 20),

                    // Signup Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Get.off(() => const SignupScreen()),
                          child: const Text(
                            "Signup here",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
