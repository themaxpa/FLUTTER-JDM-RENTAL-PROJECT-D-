import 'dart:ui'; // For Acrylic Blur
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flutter_app/screen/screen_splash.dart';
import 'package:flutter_app/user/update_user_profile.dart';
import 'package:flutter_app/user/user_profile_widget_menu.dart';

class SellerProfileScreen extends StatefulWidget {
  const SellerProfileScreen({super.key});

  @override
  State<SellerProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<SellerProfileScreen> {
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
      _isLoading = true;
    });

    _user = _auth.currentUser;

    if (_user != null) {
      try {
        DocumentSnapshot snapshot =
            await _firestore.collection('users').doc(_user!.uid).get();

        if (snapshot.exists && snapshot.data() != null) {
          setState(() {
            _userData = snapshot;
            _isLoading = false;
          });
        } else {
          _userData = null;
          setState(() {
            _isLoading = false;
          });
        }
      } catch (error) {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background for clean UI
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    /// -- PROFILE IMAGE WITH ACRYLIC BLUR
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: Image.asset(
                            'assets/images/ph12.jpg',
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _userData != null ? (_userData!['name'] ?? 'N/A') : 'N/A',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _user?.email ?? 'N/A',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 20),

                    /// -- EDIT PROFILE BUTTON
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () =>
                            Get.to(() => const UpdateProfileScreen()),
                        child: Text('Edit Profile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Divider(),
                    const SizedBox(height: 10),

                    /// -- MENU ITEMS
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
