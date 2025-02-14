import 'package:flutter/material.dart';

import '../services/auth_services.dart';
import 'login.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthService _authService =
      AuthService(); // Instance of AuthService for authentication logic

  // Controllers for capturing input from text fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedRole = 'User'; // Default selected role for dropdown
  bool _isLoading = false; // To show loading spinner during signup
  bool isPasswordHidden = true;

  // Signup function to handle user registration
  void _signup() async {
    setState(() {
      _isLoading = true; // Show loading spinner
    });

    // Call signup method from AuthService with user inputs
    String? result = await _authService.signup(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      role: _selectedRole,
    );

    setState(() {
      _isLoading = false; // Hide loading spinner
    });

    if (result == null) {
      // Signup successful: Navigate to LoginScreen with success message
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Signup Successful! Now Turn to Login'),
      ));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      // Signup failed: Show error message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Signup Failed: $result'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.all(16.0), // Add padding to the screen
          child: SingleChildScrollView(
            // Makes the screen scrollable
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset("assets/images/tesla.jpg"),
                SizedBox(
                  height: 40,
                ),
                // Display an image at the top
                // Input for name
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
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
                  obscureText: isPasswordHidden, // Hide the password
                ),
                const SizedBox(height: 16),
                // Dropdown for selecting role
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedRole = newValue!; // Update role selection
                    });
                  },
                  items: ['seller', 'User'].map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                // Signup button or loading spinner
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        width: double.infinity, // Button stretches across width
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: ElevatedButton(
                            onPressed: _signup,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(2.0),
                              ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 15),
                            ), // Call signup function
                            child: const Text(
                              'Signup',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                const SizedBox(height: 10),
                // Navigation to LoginScreen
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(fontSize: 18),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text(
                        "Login here",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            letterSpacing: -1),
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
