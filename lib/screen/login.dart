import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/screen/signup_page.dart';
import 'package:flutter_app/seller/seller_home.dart';
import 'package:flutter_app/user/showroom.dart';
import 'package:get/get.dart'; // Import GetX package
import '../admin/home.dart';
import '../services/auth_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showSnackBar("Error", "Email and password cannot be empty.");
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
        final user = FirebaseAuth.instance.currentUser;
        final String uid = user?.uid ?? '';
        await _cacheUserRole(role, uid);
        _navigateToHomeScreen(role);
      } else {
        _showSnackBar('Error', 'Invalid email or password. Please try again.');
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      if (e.code == 'user-not-found') {
        _showSnackBar('Error', 'No user found with this email.');
      } else if (e.code == 'wrong-password') {
        _showSnackBar('Error', 'Incorrect password. Please try again.');
      } else if (e.code == 'invalid-email') {
        _showSnackBar('Error', 'Invalid email format.');
      } else {
        _showSnackBar('Error', 'Login failed: ${e.message}');
      }
    } catch (error) {
      setState(() => _isLoading = false);
      _showSnackBar('Error', 'An unexpected error occurred. Please try again.');
    }
  }

  Future<void> _cacheUserRole(String role, String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ROLE_KEY, role);
    await prefs.setString(UID_KEY, uid);
  }

  void _navigateToHomeScreen(String role) {
    Widget homeScreen;
    switch (role.toLowerCase()) {
      case 'admin':
        homeScreen = const AdminHome();
        break;
      case 'seller':
        homeScreen = const SellerHome();
        break;
      case 'user':
        homeScreen = const Showroom();
        break;
      default:
        homeScreen = CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            middle: Center(child: Material(child: Text("Unknown Role"))),
            backgroundColor: CupertinoColors.systemGrey6,
          ),
          child: Center(
            child: Center(
              child: Material(
                child: Text(
                  'Unknown Role: $role',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        );
    }
    Navigator.pushReplacement(
      context,
      CupertinoPageRoute(builder: (_) => homeScreen),
    );
  }

  /// **Custom Snackbar with iOS Design**
  void _showSnackBar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.black,
      // Set background color to black
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      isDismissible: true,
      overlayBlur: 2,
      // Slight blur effect
      colorText: Colors.white,
      // White text for visibility
      titleText: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.white, // White title text
        ),
      ),
      messageText: Text(
        message,
        style: const TextStyle(
          fontWeight: FontWeight.bold, // Bold message text
          fontSize: 14,
          color: Colors.white, // White message text
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.grey[200],
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset("assets/images/SubaruLogo.png", height: 100),
              const SizedBox(height: 20),
              CupertinoTextField(
                controller: _emailController,
                placeholder: "Email",
                keyboardType: TextInputType.emailAddress,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: _passwordController,
                placeholder: "Password",
                obscureText: _isPasswordHidden,
                padding: const EdgeInsets.all(16),
                suffix: GestureDetector(
                  onTap: () =>
                      setState(() => _isPasswordHidden = !_isPasswordHidden),
                  child: Icon(
                    _isPasswordHidden
                        ? CupertinoIcons.eye_slash
                        : CupertinoIcons.eye,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ForgotPasswordPage()),
                  ),
                  child: Material(
                    color: Colors.grey[200],
                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.activeBlue,
                        backgroundColor: Colors.grey[200],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : CupertinoButton(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: _login,
                      child: const Text("Login",
                          style: TextStyle(color: Colors.white)),
                    ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Material(
                    color: Colors.grey[200],
                    child: const Text("Don't have an account? ",
                        style: TextStyle(fontSize: 12)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      CupertinoPageRoute(builder: (_) => const SignupScreen()),
                    ),
                    child: Material(
                      color: Colors.grey[200],
                      child: Text(
                        "Signup here",
                        style: TextStyle(
                            fontSize: 13,
                            color: CupertinoColors.activeBlue,
                            backgroundColor: Colors.grey[200],
                            fontWeight: FontWeight.bold),
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
}
