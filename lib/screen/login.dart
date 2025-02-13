// This screen handles user login with email and password
import 'package:flutter/material.dart';
import 'package:flutter_app/screen/signup_page.dart';
import 'package:flutter_app/seller/seller_home.dart';
import 'package:flutter_app/user/showroom.dart';

import '../admin/home.dart';
import '../services/auth_services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService(); // Instance of AuthService
// Controller for email input
  final _emailController = TextEditingController();

  // Controller for password input
  final _passwordController = TextEditingController();

  // To show spinner during login
  bool _isLoading = false;

  // Login function to handle user authentication
  void _login() async {
    setState(() {
      _isLoading = true; // Show spinner
    });

    // Call login method from AuthService with user inputs
    String? result = await _authService.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    setState(() {
      _isLoading = false; // Hide spinner
    });

    // Navigate based on role or show error message
    if (result == 'Admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminHome(),
        ),
      );
    } else if (result == 'User') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const Showroom(),
        ),
      );
    } else if (result == 'seller') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const SellerHome(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Login Failed: $result'), // Show error message
      ));
    }
  }

  bool isPasswordHidden = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Add padding
          child: Column(
            children: [
              Image.asset("assets/3094352.jpg"), // Display login screen image
              const SizedBox(height: 20),
              // Input for email
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Input for password
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        isPasswordHidden = !isPasswordHidden;
                      });
                    },
                    icon: Icon(
                      isPasswordHidden
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
                obscureText: true, // Hide password
              ),
              const SizedBox(height: 20),
              // Login button or spinner
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _login, // Call login function
                        child: const Text('Login'),
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
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      );
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
    );
  }
}
