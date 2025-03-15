import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SellerUpdateProfileScreen extends StatefulWidget {
  const SellerUpdateProfileScreen({super.key});

  @override
  _SellerUpdateProfileScreenState createState() =>
      _SellerUpdateProfileScreenState();
}

class _SellerUpdateProfileScreenState extends State<SellerUpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  String? profileImageUrl;
  String? userRole;
  bool isLoadingImage = true;

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
      final userDoc =
          await FirebaseFirestore.instance.collection('vendors').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null) {
          setState(() {
            nameController.text = data['name'] ?? '';
            phoneController.text = data['phone'] ?? '';
            locationController.text = data['location'] ?? '';
            userRole = data['role'] ?? 'Vendor'; // Fetch role
            profileImageUrl = data['profileImage'] ?? '';
            isLoadingImage = false;
          });
        }
      } else {
        setState(() => isLoadingImage = false);
      }
    } catch (e) {
      setState(() => isLoadingImage = false);
      Get.snackbar("Error", "Failed to fetch user data: $e",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> updateUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await user.updateDisplayName(nameController.text);
      await FirebaseFirestore.instance.collection('vendors').doc(user.uid).set({
        "name": nameController.text,
        "email": emailController.text,
        "phone": phoneController.text,
        "location": locationController.text,
      }, SetOptions(merge: true));

      Get.snackbar("Success", "Profile updated successfully!",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: CupertinoColors.activeGreen,
          colorText: CupertinoColors.white);
    } catch (error) {
      Get.snackbar("Error", "Error updating profile: $error",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: CupertinoColors.systemRed,
          colorText: CupertinoColors.white);
    }
  }

  void showUserDetailsDrawer() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: const Text("User Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          message: Column(
            children: [
              _buildCupertinoListTile(
                  CupertinoIcons.person, "Name", nameController.text),
              _buildCupertinoListTile(
                  CupertinoIcons.mail, "Email", emailController.text),
              _buildCupertinoListTile(
                  CupertinoIcons.phone, "Phone", phoneController.text),
              _buildCupertinoListTile(
                  CupertinoIcons.location, "Location", locationController.text),
              _buildCupertinoListTile(
                  CupertinoIcons.person_crop_circle, "Role", userRole ?? 'N/A'),
            ],
          ),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        );
      },
    );
  }

  /// Helper method to create a Cupertino-style list item
  Widget _buildCupertinoListTile(IconData icon, String title, String value) {
    return CupertinoListTile(
      leading: Icon(icon, color: CupertinoColors.systemBlue),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle:
          Text(value, style: TextStyle(color: CupertinoColors.systemGrey)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Center(child: Text('Edit Profile')),
            backgroundColor: CupertinoColors.systemBackground,
          ),
          SliverFillRemaining(
            hasScrollBody: true,
            child: CupertinoScrollbar(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  children: [
                    /// Profile Picture Section
                    Center(
                      child: CupertinoContextMenu(
                        actions: [
                          CupertinoContextMenuAction(
                            child: const Text('Choose from Gallery'),
                            onPressed: () {
                              // Handle picking image from gallery
                              Navigator.pop(context);
                            },
                          ),
                          CupertinoContextMenuAction(
                            child: const Text('Take a Photo'),
                            onPressed: () {
                              // Handle opening camera
                              Navigator.pop(context);
                            },
                          ),
                          CupertinoContextMenuAction(
                            isDestructiveAction: true,
                            child: const Text('Remove Photo'),
                            onPressed: () {
                              // Handle removing the image
                              Navigator.pop(context);
                            },
                          ),
                        ],
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: CupertinoColors.systemGrey4, width: 2),
                          ),
                          child: ClipOval(
                            child: isLoadingImage
                                ? CupertinoActivityIndicator()
                                : profileImageUrl != null &&
                                        profileImageUrl!.isNotEmpty
                                    ? Image.network(profileImageUrl!,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover)
                                    : Image.asset('assets/images/img.jpg',
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// Profile Form
                    CupertinoListSection.insetGrouped(
                      children: [
                        CupertinoTextFormFieldRow(
                          controller: nameController,
                          placeholder: 'Full Name',
                          prefix: Icon(CupertinoIcons.person,
                              color: CupertinoColors.systemGrey),
                        ),
                        CupertinoTextFormFieldRow(
                          controller: emailController,
                          placeholder: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          prefix: Icon(CupertinoIcons.mail,
                              color: CupertinoColors.systemGrey),
                        ),
                        CupertinoTextFormFieldRow(
                          controller: phoneController,
                          placeholder: 'Phone Number',
                          keyboardType: TextInputType.phone,
                          prefix: Icon(CupertinoIcons.phone,
                              color: CupertinoColors.systemGrey),
                        ),
                        CupertinoTextFormFieldRow(
                          controller: locationController,
                          placeholder: 'Location',
                          prefix: Icon(CupertinoIcons.location,
                              color: CupertinoColors.systemGrey),
                        ),
                      ],
                    ),

                    /// Action Buttons
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        onPressed: updateUserProfile,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        color: CupertinoColors.black,
                        borderRadius: BorderRadius.circular(12),
                        child: const Text(
                          'Update Profile',
                          style: TextStyle(
                              color: CupertinoColors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        onPressed: showUserDetailsDrawer,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: const Text(
                          'User Details',
                          style: TextStyle(
                              color: CupertinoColors.black,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
