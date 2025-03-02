import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/auth_services.dart';
import 'login.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _retypePasswordController =
      TextEditingController();

  String _selectedRole = 'user';
  bool _isLoading = false;
  bool isPasswordHidden = true;
  bool isRetypePasswordHidden = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _retypePasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (_passwordController.text != _retypePasswordController.text) {
      _showDialog(
          'Password Mismatch', 'Passwords do not match. Please re-enter them.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? result = await _authService.signup(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        role: _selectedRole,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (result == null) {
          _showDialog('Success', 'Signup Successful! Now turn to Login',
              isSuccess: true);
        } else {
          _showDialog('Error',
              'Please fill out all required fields before submitting.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showDialog('Error', 'An unexpected error occurred: ${e.toString()}');
      }
    }
  }

  void _showDialog(String title, String content, {bool isSuccess = false}) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () {
              Navigator.pop(context);
              if (isSuccess) {
                Navigator.pushReplacement(
                  context,
                  CupertinoPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.grey[200],
      navigationBar: CupertinoNavigationBar(
        middle: Text('Signup'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      "assets/images/tesla.jpg",
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: 40),
                _buildTextField(
                    controller: _nameController, placeholder: 'Name'),
                SizedBox(height: 16),
                _buildTextField(
                    controller: _emailController, placeholder: 'Email'),
                SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  placeholder: 'Password',
                  obscureText: isPasswordHidden,
                  toggleVisibility: () =>
                      setState(() => isPasswordHidden = !isPasswordHidden),
                ),
                SizedBox(height: 16),
                _buildTextField(
                  controller: _retypePasswordController,
                  placeholder: 'Retype Password',
                  obscureText: isRetypePasswordHidden,
                  toggleVisibility: () => setState(
                      () => isRetypePasswordHidden = !isRetypePasswordHidden),
                ),
                SizedBox(height: 16),
                _buildRolePicker(),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed: _signup,
                    child: _isLoading
                        ? CupertinoActivityIndicator()
                        : Text('Signup'),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Material(
                      color: Colors.grey[200],
                      child: Text("Already have an account? ",
                          style: TextStyle(fontSize: 10)),
                    ),
                    CupertinoButton(
                      child: Text("Login here",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        CupertinoPageRoute(builder: (_) => const LoginScreen()),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    bool obscureText = false,
    VoidCallback? toggleVisibility,
  }) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      obscureText: obscureText,
      padding: EdgeInsets.all(16),
      suffix: toggleVisibility != null
          ? CupertinoButton(
              child: Icon(
                  obscureText ? CupertinoIcons.eye_slash : CupertinoIcons.eye),
              onPressed: toggleVisibility,
            )
          : null,
      decoration: BoxDecoration(
        border: Border.all(color: CupertinoColors.systemGrey),
        borderRadius: BorderRadius.circular(8),
        color: CupertinoColors.systemGrey6,
      ),
    );
  }

  Widget _buildRolePicker() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: CupertinoPicker(
        itemExtent: 32.0,
        onSelectedItemChanged: (int index) =>
            setState(() => _selectedRole = ['seller', 'user'][index]),
        children: ['seller', 'user'].map((role) => Text(role)).toList(),
      ),
    );
  }
}
