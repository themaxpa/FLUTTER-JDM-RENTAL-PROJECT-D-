import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_app/screen/screen_splash.dart';
import 'package:flutter_app/user/update_user_profile.dart';

import '../user/my_documents.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({Key? key}) : super(key: key);

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isDarkMode =
      WidgetsBinding.instance.window.platformBrightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _updateBrightness();
    WidgetsBinding.instance.window.onPlatformBrightnessChanged = () {
      _updateBrightness();
    };
  }

  Future<void> updateAdminProfile(String name, String email) async {
    if (_user == null) return;

    try {
      await _firestore.collection('admin').doc(_user!.uid).update({
        'name': name,
        'email': email,
      });
      await _loadUserData();
      Get.back(); // Go back after updating
    } catch (e) {
      print("Profile update failed: $e");
    }
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    _user = _auth.currentUser;

    if (_user != null) {
      try {
        DocumentSnapshot snapshot = await _firestore
            .collection('admin')
            .doc(_user!.uid)
            .get(); // Change to 'admin' collection
        if (snapshot.exists && snapshot.data() != null) {
          setState(() => _userData = snapshot.data() as Map<String, dynamic>);
        }
      } catch (error) {
        print("Error fetching admin data: $error");
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _uploadImage() async {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: Text(
            "Select Image Source",
            style: TextStyle(
              color:
                  _isDarkMode ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),
          actions: [
            CupertinoActionSheetAction(
              child: Text(
                "Camera",
                style: TextStyle(
                  color: _isDarkMode
                      ? CupertinoColors.white
                      : CupertinoColors.black,
                ),
              ),
              onPressed: () async {
                Navigator.pop(context);
                await _pickImage(ImageSource.camera);
              },
            ),
            CupertinoActionSheetAction(
              child: Text(
                "Gallery",
                style: TextStyle(
                  color: _isDarkMode
                      ? CupertinoColors.white
                      : CupertinoColors.black,
                ),
              ),
              onPressed: () async {
                Navigator.pop(context);
                await _pickImage(ImageSource.gallery);
              },
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: Text(
              "Cancel",
              style: TextStyle(
                color: _isDarkMode
                    ? CupertinoColors.systemRed
                    : CupertinoColors.destructiveRed,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image == null || _user == null) return;

    final cloudinary = CloudinaryPublic('dageosse2', 'project-d', cache: false);
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(image.path,
            resourceType: CloudinaryResourceType.Image),
      );

      await _firestore
          .collection('admin') // Change from 'users' to 'admin'
          .doc(_user!.uid)
          .update({'profileImage': response.secureUrl});
      await _loadUserData();
    } catch (e) {
      print("Upload failed: $e");
    }
  }

  void _showLogoutDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          "Logout",
          style: TextStyle(
            color: _isDarkMode ? CupertinoColors.white : CupertinoColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Are you sure you want to log out?",
          style: TextStyle(
            color: _isDarkMode ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(
              "Cancel",
              style: TextStyle(
                color: _isDarkMode
                    ? CupertinoColors.systemBlue
                    : CupertinoColors.activeBlue,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Get.offAll(() => const SplashScreen());
            },
            child: Text(
              "Logout",
              style: TextStyle(
                color: _isDarkMode
                    ? CupertinoColors.systemRed
                    : CupertinoColors.destructiveRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundImage: _userData?['profileImage'] != null
              ? NetworkImage(_userData!['profileImage'])
              : const AssetImage('assets/images/img.jpg') as ImageProvider,
          backgroundColor: Colors.grey.shade200,
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _uploadImage,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.shade600,
              border: Border.all(color: Colors.white, width: 2),
            ),
            padding: const EdgeInsets.all(6),
            child: const Icon(CupertinoIcons.camera_fill,
                color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      children: [
        SizedBox(
          height: 20,
        ),
        Material(
          color: Colors.transparent,
          child: Text(
            _userData?['name'] ?? 'N/A',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _isDarkMode ? CupertinoColors.white : Colors.black,
            ),
          ),
        ),
        Material(
          color: Colors.transparent,
          child: Text(
            _user?.email ?? 'N/A',
            style: TextStyle(
              fontSize: 16,
              color: _isDarkMode
                  ? CupertinoColors.systemGrey
                  : Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(String title, IconData icon, VoidCallback onTap,
      {Color? textColor}) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: _isDarkMode
              ? CupertinoColors.darkBackgroundGray
              : CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: _isDarkMode ? Colors.black26 : Colors.black12,
                blurRadius: 4)
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 22,
                    color: textColor ??
                        (_isDarkMode ? CupertinoColors.white : Colors.black)),
                const SizedBox(width: 15),
                Text(title,
                    style: TextStyle(
                        fontSize: 16,
                        color: textColor ??
                            (_isDarkMode
                                ? CupertinoColors.white
                                : Colors.black))),
              ],
            ),
            Icon(CupertinoIcons.forward,
                color: _isDarkMode ? CupertinoColors.systemGrey : Colors.grey),
          ],
        ),
      ),
    );
  }

  void _updateBrightness() {
    setState(() {
      _isDarkMode =
          WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.window.onPlatformBrightnessChanged = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: _isDarkMode
          ? CupertinoColors.black
          : CupertinoColors.systemGroupedBackground,
      child: _isLoading
          ? const Center(child: CupertinoActivityIndicator(radius: 15))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 100), // Added top margin
                      _buildProfileImage(),
                      const SizedBox(height: 15),
                      _buildProfileInfo(),
                      const SizedBox(height: 20),
                      _buildMenuItem("Edit Profile", CupertinoIcons.pencil,
                          () => Get.to(() => const UpdateProfileScreen())),
                      _buildMenuItem(
                          "Settings", CupertinoIcons.gear_alt, () {}),
                      _buildMenuItem("My Documents", CupertinoIcons.doc_text,
                          () {
                        Get.to(() => MyDocumentsScreen());
                      }),
                      _buildMenuItem(
                          "Support", CupertinoIcons.person_2_alt, () {}),
                      _buildMenuItem(
                          "Information", CupertinoIcons.info_circle, () {}),
                      _buildMenuItem(
                          "Logout", CupertinoIcons.power, _showLogoutDialog,
                          textColor: Colors.red),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
