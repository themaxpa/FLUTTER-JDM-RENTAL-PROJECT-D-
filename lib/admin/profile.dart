import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flutter_app/screen/screen_splash.dart';
import 'package:flutter_app/user/update_user_profile.dart';
import 'package:flutter_app/user/user_profile_widget_menu.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({Key? key}) : super(key: key);

  @override
  State<AdminProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<AdminProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  DocumentSnapshot? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    _user = _auth.currentUser; // Get the current user

    if (_user != null) {
      try {
        DocumentSnapshot snapshot =
            await _firestore.collection('users').doc(_user!.uid).get();

        // Check if the document exists before accessing its data
        if (snapshot.exists && snapshot.data() != null) {
          setState(() {
            _userData = snapshot;
            _isLoading = false; // Hide loading indicator
          });
        } else {
          print("User data does not exist for user ID: ${_user!.uid}");
          // Handle the case where user data doesn't exist
          _userData = null; // Set _userData to null
          setState(() {
            _isLoading = false; // Hide loading indicator
          });
        }
      } catch (error) {
        print("Error fetching user data: $error");
        // Handle error (e.g., show an error message)
        setState(() {
          _isLoading = false; // Hide loading indicator
        });
      }
    } else {
      print("No user logged in.");
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    /// -- IMAGE
                    Stack(
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: const Image(
                              image: AssetImage('assets/images/ph12.jpg'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              color: Colors.yellow,
                            ),
                            child: const Icon(
                              LineAwesomeIcons.pencil_alt_solid,
                              color: Colors.black,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _userData != null &&
                              _userData!.exists &&
                              _userData!.data() != null
                          ? (_userData!['name'] as String? ??
                              'N/A') // Use null safety
                          : 'N/A',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(
                      _user?.email ?? 'N/A',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),

                    /// -- BUTTON
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () =>
                            Get.to(() => const UpdateProfileScreen()),
                        child: const Text('Edit Profile'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2.0),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Divider(),
                    const SizedBox(height: 10),

                    /// -- MENU
                    ProfileMenuWidget(
                      title: "Settings",
                      icon: LineAwesomeIcons.cog_solid,
                      onPress: () {},
                    ),
                    ProfileMenuWidget(
                      title: "My Documents",
                      icon: LineAwesomeIcons.wallet_solid,
                      onPress: () {},
                    ),
                    ProfileMenuWidget(
                      title: "Support",
                      icon: LineAwesomeIcons.user_check_solid,
                      onPress: () {},
                    ),
                    const Divider(),
                    const SizedBox(height: 10),
                    ProfileMenuWidget(
                      title: "Information",
                      icon: LineAwesomeIcons.info_solid,
                      onPress: () {},
                    ),
                    ProfileMenuWidget(
                      title: "Logout",
                      icon: LineAwesomeIcons.sign_out_alt_solid,
                      textColor: Colors.red,
                      endIcon: false,
                      onPress: () {
                        Get.defaultDialog(
                          backgroundColor: Colors.white,
                          middleText: "Logout",
                          title: "Logout",
                          // Removes the default title spacing for a cleaner look
                          barrierDismissible: true,
                          // Allows dismissing by tapping outside
                          content: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              // Acrylic Blur

                              child: Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  // Semi-transparent for iOS feel
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                        LineAwesomeIcons
                                            .exclamation_circle_solid,
                                        color: Colors.red,
                                        size: 50),
                                    SizedBox(height: 15),
                                    Text(
                                      "Are you sure you want to logout?",
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        // Cancel Button
                                        TextButton(
                                          onPressed: () => Get.back(),
                                          child: Text(
                                            "Cancel",
                                            style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.blue),
                                          ),
                                        ),
                                        // Confirm Logout Button
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blueGrey,
                                            // More noticeable
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                          ),
                                          onPressed: () async {
                                            Get.back(); // Close Dialog
                                            try {
                                              await FirebaseAuth.instance
                                                  .signOut();
                                              Get.offAll(() =>
                                                  SplashScreen()); // Redirect to SplashScreen
                                            } catch (e) {
                                              Get.snackbar("Logout Failed",
                                                  "An error occurred during logout.");
                                            }
                                          },
                                          child: Text("Logout",
                                              style: TextStyle(fontSize: 16)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
