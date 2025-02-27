import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/db/functions.dart';
import 'package:flutter_app/user/profile_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  _UpdateProfileScreenState createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  bool _isPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      nameController.text = user.displayName ?? '';
      emailController.text = user.email ?? '';
      fetchUserData(user.uid);
    }
  }

  Future<void> fetchUserData(String uid) async {
    try {
      final userData = await DatabaseMethods().getUserDetails(uid);
      if (userData.exists) {
        final data = userData.data() as Map<String, dynamic>?;
        if (data != null) {
          setState(() {
            nameController.text = data['name'] ?? '';
            phoneController.text = data['phone'] ?? '';
            locationController.text = data['location'] ?? '';
          });
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Error fetching user data: $e",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> updateUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await user.updateDisplayName(nameController.text);
      if (emailController.text != user.email) {
        await user.updateEmail(emailController.text);
      }

      if (passwordController.text.isNotEmpty) {
        await user.updatePassword(passwordController.text);
      }

      Map<String, dynamic> userInfoMap = {
        "name": nameController.text,
        "email": emailController.text,
        if (phoneController.text.isNotEmpty) "phone": phoneController.text,
        if (locationController.text.isNotEmpty)
          "location": locationController.text,
      };
      await DatabaseMethods().addUserDetails(userInfoMap, user.uid);

      Get.snackbar("Success", "Profile updated successfully!",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
    } catch (error) {
      Get.snackbar("Error", "Error updating profile: $error",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Edit Profile'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: Image.asset('assets/images/ph12.jpg',
                        fit: BoxFit.cover),
                  ),
                ),
                SizedBox(height: 20),
                CupertinoTextField(
                  controller: nameController,
                  placeholder: 'Full Name',
                  padding: EdgeInsets.all(16),
                ),
                SizedBox(height: 16),
                CupertinoTextField(
                  controller: emailController,
                  placeholder: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  padding: EdgeInsets.all(16),
                ),
                SizedBox(height: 16),
                CupertinoTextField(
                  controller: phoneController,
                  placeholder: 'Phone Number',
                  keyboardType: TextInputType.phone,
                  padding: EdgeInsets.all(16),
                ),
                SizedBox(height: 16),
                CupertinoTextField(
                  controller: locationController,
                  placeholder: 'Location',
                  padding: EdgeInsets.all(16),
                ),
                SizedBox(height: 16),
                CupertinoTextField(
                  controller: passwordController,
                  placeholder: 'Password',
                  obscureText: !_isPasswordVisible,
                  padding: EdgeInsets.all(16),
                  suffix: CupertinoButton(
                    child: Icon(
                      _isPasswordVisible
                          ? CupertinoIcons.eye_slash
                          : CupertinoIcons.eye,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                SizedBox(height: 30),
                CupertinoButton.filled(
                  onPressed: updateUserProfile,
                  child: Text('Update Profile'),
                ),
                SizedBox(height: 20),
                CupertinoButton(
                  child: Text('User Details',
                      style: TextStyle(color: CupertinoColors.destructiveRed)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                          builder: (context) => ProfileDetailsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
