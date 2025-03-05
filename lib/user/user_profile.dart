import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_app/screen/screen_splash.dart';
import 'package:flutter_app/user/update_user_profile.dart';
import 'package:flutter_app/user/user_profile_widget_menu.dart';
import 'my_documents.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _SellerProfileState();
}

class _SellerProfileState extends State<ProfileScreen> {
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

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    _user = _auth.currentUser;

    if (_user != null) {
      try {
        DocumentSnapshot snapshot =
            await _firestore.collection('users').doc(_user!.uid).get();
        if (snapshot.exists && snapshot.data() != null) {
          setState(() => _userData = snapshot.data() as Map<String, dynamic>);
        }
      } catch (error) {
        print("Error fetching user data: $error");
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _uploadImage() async {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: const Text("Select Image Source"),
          actions: [
            CupertinoActionSheetAction(
              child: const Text("Camera"),
              onPressed: () async {
                Navigator.pop(context);
                await _pickImage(ImageSource.camera);
              },
            ),
            CupertinoActionSheetAction(
              child: const Text("Gallery"),
              onPressed: () async {
                Navigator.pop(context);
                await _pickImage(ImageSource.gallery);
              },
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: const Text("Cancel"),
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
          .collection('users')
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
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          CupertinoDialogAction(
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            onPressed: () => Get.back(),
          ),
          CupertinoDialogAction(
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Get.back();
              await FirebaseAuth.instance.signOut();
              Get.offAll(() => const SplashScreen());
            },
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
              : const AssetImage('assets/images/ph12.jpg') as ImageProvider,
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
        Text(
          _userData?['name'] ?? 'N/A',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        Text(
          _user?.email ?? 'N/A',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
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
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 22, color: textColor ?? Colors.black),
                const SizedBox(width: 15),
                Text(title,
                    style: TextStyle(
                        fontSize: 16, color: textColor ?? Colors.black)),
              ],
            ),
            const Icon(CupertinoIcons.forward, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: _isLoading
          ? const Center(child: CupertinoActivityIndicator(radius: 15))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildProfileImage(),
                  const SizedBox(height: 15),
                  _buildProfileInfo(),
                  const SizedBox(height: 20),
                  _buildMenuItem("Edit Profile", CupertinoIcons.pencil,
                      () => Get.to(() => const UpdateProfileScreen())),
                  _buildMenuItem("Settings", CupertinoIcons.gear_alt, () {}),
                  _buildMenuItem("My Documents", CupertinoIcons.doc_text, () {
                    Get.to(() => MyDocumentsScreen());
                  }),
                  _buildMenuItem("Support", CupertinoIcons.person_2_alt, () {}),
                  _buildMenuItem(
                      "Information", CupertinoIcons.info_circle, () {}),
                  _buildMenuItem(
                      "Logout", CupertinoIcons.power, _showLogoutDialog,
                      textColor: Colors.red),
                ],
              ),
            ),
    );
  }
}
