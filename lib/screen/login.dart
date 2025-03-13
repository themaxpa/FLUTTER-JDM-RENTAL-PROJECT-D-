import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
        homeScreen = const Center(child: Text("Unknown Role"));
    }
    // Use Get.offAll to clear all previous screens from the navigation stack.
    Get.offAll(() => homeScreen);
  }

  void _showErrorDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) {
        return CupertinoAlertDialog(
          title: Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(message,
                style: const TextStyle(
                    fontWeight: FontWeight.normal, fontSize: 14)),
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
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
                  onTap: () => Get.to(() => const ForgotPasswordPage()),
                  child: Material(
                    color: Colors.grey[200],
                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.activeBlue,
                          fontSize: 13),
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
                    child: const Text("Don't have an account?",
                        style: TextStyle(fontSize: 12)),
                  ),
                  GestureDetector(
                    onTap: () => Get.off(() => const SignupScreen()),
                    child: Material(
                      color: Colors.grey[200],
                      child: Text(
                        " Signup here",
                        style: TextStyle(
                            fontSize: 13,
                            color: CupertinoColors.activeBlue,
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
