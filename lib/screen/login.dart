import 'package:flutter/material.dart';
import 'package:flutter_app/screen/signup_page.dart';
import 'package:flutter_app/seller/seller_home.dart';
import 'package:flutter_app/user/showroom.dart';
import '../admin/home.dart';
import '../services/auth_services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key); // Added Key? key

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController =
      TextEditingController(); // Made final
  final TextEditingController _passwordController =
      TextEditingController(); // Made final
  bool _isLoading = false;
  bool _isPasswordHidden = true; // Renamed for clarity

  @override
  void dispose() {
    // Dispose of controllers to prevent memory leaks
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Made async function return void
    setState(() {
      _isLoading = true;
    });

    try {
      String? result = await _authService.login(
        email: _emailController.text.trim(), // Trim whitespace
        password: _passwordController.text.trim(), // Trim whitespace
      );

      setState(() {
        _isLoading = false;
      });

      if (result == 'Admin') {
        _navigateTo(const AdminHome());
      } else if (result == 'User') {
        _navigateTo(const Showroom());
      } else if (result == 'seller') {
        _navigateTo(const SellerHome());
      } else {
        _showSnackBar('Login Failed: $result');
      }
    } catch (error) {
      // Handle potential errors during the login process
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('An error occurred during login.');
      print("Login Error: $error"); // Log the error for debugging
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          // Added SingleChildScrollView
          child: Padding(
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
                  keyboardType:
                      TextInputType.emailAddress, // Added keyboard type
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
                  obscureText: _isPasswordHidden, // Use the renamed variable
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
                              borderRadius: BorderRadius.circular(2.0),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 15),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(fontSize: 18),
                    ),
                    InkWell(
                      onTap: () {
                        _navigateTo(
                            const SignupScreen()); // Use navigate function
                      },
                      child: const Text(
                        "Signup here",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                          letterSpacing: -1,
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
    );
  }
}
