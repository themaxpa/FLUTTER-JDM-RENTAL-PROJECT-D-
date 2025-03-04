import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:flutter_app/screen/screen_splash.dart';
import 'package:flutter_app/user/update_user_profile.dart';
import 'package:flutter_app/user/user_profile_widget_menu.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Fetch user data from Firebase
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    _user = _auth.currentUser;

    if (_user != null) {
      try {
        DocumentSnapshot snapshot =
            await _firestore.collection('users').doc(_user!.uid).get();

        if (snapshot.exists && snapshot.data() != null) {
          setState(() {
            _userData = snapshot.data() as Map<String, dynamic>;
          });
        }
      } catch (error) {
        print("Error fetching user data: $error");
      }
    }

    setState(() => _isLoading = false);
  }

  /// Upload image to Cloudinary and update Firestore
  Future<void> _uploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    final cloudinary = CloudinaryPublic('dageosse2', 'project-d', cache: false);

    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(image.path,
            resourceType: CloudinaryResourceType.Image),
      );

      String imageUrl = response.secureUrl;

      // Store image URL in Firestore
      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .update({'profileImage': imageUrl});

      // Reload user data from Firestore after updating
      await _loadUserData();
    } catch (e) {
      print("Upload failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    /// -- IMAGE
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: _userData != null &&
                                  _userData!['profileImage'] != null
                              ? Image.network(
                                  _userData!['profileImage'],
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  'assets/images/ph12.jpg',
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _uploadImage,
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _userData != null ? (_userData!['name'] ?? 'N/A') : 'N/A',
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
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Divider(),
                    const SizedBox(height: 10),

                    /// -- MENU
                    ProfileMenuWidget(
                        title: "Settings",
                        icon: LineAwesomeIcons.cog_solid,
                        onPress: () {}),
                    ProfileMenuWidget(
                        title: "My Documents",
                        icon: LineAwesomeIcons.wallet_solid,
                        onPress: () {}),
                    ProfileMenuWidget(
                        title: "Support",
                        icon: LineAwesomeIcons.user_check_solid,
                        onPress: () {}),
                    const Divider(),
                    const SizedBox(height: 10),
                    ProfileMenuWidget(
                        title: "Information",
                        icon: LineAwesomeIcons.info_solid,
                        onPress: () {}),
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
                          barrierDismissible: true,
                          content: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
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
                                    const SizedBox(height: 15),
                                    const Text(
                                      "Are you sure you want to logout?",
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        TextButton(
                                            onPressed: () => Get.back(),
                                            child: const Text("Cancel")),
                                        ElevatedButton(
                                          onPressed: () async {
                                            Get.back();
                                            try {
                                              await FirebaseAuth.instance
                                                  .signOut();
                                              Get.offAll(
                                                  () => const SplashScreen());
                                            } catch (e) {
                                              Get.snackbar("Logout Failed",
                                                  "An error occurred during logout.");
                                            }
                                          },
                                          child: const Text("Logout"),
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
