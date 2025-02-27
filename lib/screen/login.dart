import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/screen/signup_page.dart';
import 'package:flutter_app/seller/seller_home.dart';
import 'package:flutter_app/user/showroom.dart';
import '../admin/home.dart';
import '../services/auth_services.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
import '../main.dart'; // Import to use AuthController

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
    setState(() {
      _isLoading = true;
    });

    try {
      String? role = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      setState(() {
        _isLoading = false;
      });

      if (role != null) {
        // Get the current user's UID
        final user = FirebaseAuth.instance.currentUser;
        final String uid = user?.uid ?? ''; // Get User UID
        await _cacheUserRole(role, uid);
        _navigateToHomeScreen(role);
      } else {
        _showSnackBar('Login Failed: Could not determine user role.');
      }
    } catch (error) {
      _showSnackBar('An error occurred during login.');
      print("Login Error: $error");
    } finally {
      setState(() {
        _isLoading = false;
      });
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
          backgroundColor: const Color(0xFF20232b),
          body: Center(
            child: Text(
              'Unknown Role: $role',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
        print('Unknown role: $role');
    }

    // Navigate to the corresponding HomeScreen and clear the login Route
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => homeScreen),
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Image.asset("assets/images/SubaruLogo.png"),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _isPasswordHidden = !_isPasswordHidden;
                      });
                    },
                    icon: Icon(
                      _isPasswordHidden
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
                obscureText: _isPasswordHidden,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 15),
                          backgroundColor: Colors.blueAccent,
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(fontSize: 16),
                  ),
                  InkWell(
                    onTap: () {
                      _navigateTo(const SignupScreen());
                    },
                    child: const Text(
                      "Signup here",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
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
