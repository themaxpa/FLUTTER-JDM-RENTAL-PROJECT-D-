import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/screen/signup_page.dart';
import 'package:flutter_app/seller/seller_home.dart';
import 'package:flutter_app/user/showroom.dart';
import '../admin/home.dart';
import '../services/auth_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

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
        _showSnackBar('Login Failed: Could not determine user role.');
      }
    } catch (error) {
      _showSnackBar('An error occurred during login.');
      print("Login Error: $error");
    } finally {
      setState(() => _isLoading = false);
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
        homeScreen = Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Text(
              'Unknown Role: $role',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        );
    }
    Navigator.pushReplacement(
      context,
      CupertinoPageRoute(builder: (_) => homeScreen),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      _showSnackBar("Please enter your email to reset password");
      return;
    }
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text.trim());
      _showSnackBar("Password reset link sent to your email");
    } catch (e) {
      _showSnackBar("Failed to send reset email: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
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
                  onTap: _resetPassword,
                  child: Material(
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(
                          color: CupertinoColors.activeBlue, fontSize: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : CupertinoButton.filled(
                      onPressed: _login,
                      borderRadius: BorderRadius.circular(12),
                      child: const Text("Login"),
                    ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Material(
                    child: const Text(
                      "Don't have an account? ",
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      CupertinoPageRoute(builder: (_) => const SignupScreen()),
                    ),
                    child: Material(
                      child: const Text(
                        "Signup here",
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.activeBlue),
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
