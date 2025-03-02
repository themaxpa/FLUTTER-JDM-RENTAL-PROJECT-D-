import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/admin/profile.dart';
import 'package:flutter_app/admin/users.dart';
import 'package:get/get.dart';
import 'dart:ui';

import '../main.dart'; // Import AuthController

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
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
    AuthController authController;
    try {
      authController = Get.find<AuthController>();
    } catch (e) {
      print("AuthController not found: $e");
      return Scaffold(
          backgroundColor: Colors.grey[200],
          body: const Center(child: Text("Error: AuthController missing")));
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      drawer: _buildNavigationDrawer(authController), // Add Drawer
      body: Center(
        child: Text(
          "Welcome Admin!",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Navigation Drawer
  Widget _buildNavigationDrawer(AuthController authController) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(),
          _buildDrawerItem(Icons.dashboard, "Dashboard", () {
            Get.back(); // Close drawer
          }),
          _buildDrawerItem(Icons.settings, "Settings", () {
            Get.snackbar(
                "Coming Soon", "Settings feature is under development.");
          }),
          _buildDrawerItem(Icons.calendar_month, "Date", () {
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (_) => UsersCardScreen()),
            );
          }),
          _buildDrawerItem(Icons.person, "Profile", () {
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (_) => const AdminProfileScreen()),
            );
          }),
          const Divider(), // Adds a visual separator
          _buildDrawerItem(Icons.logout, "Logout", () {
            _showLogoutDialog(authController);
          }),
        ],
      ),
    );
  }

  // Drawer Header
  Widget _buildDrawerHeader() {
    return DrawerHeader(
      decoration: const BoxDecoration(color: Colors.black),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.admin_panel_settings, size: 50, color: Colors.white),
          const SizedBox(height: 10),
          Text(
            _userData != null ? (_userData!['name'] ?? 'N/A') : 'N/A',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            _user?.email ?? 'N/A',
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  // Drawer Item
  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(AuthController authController) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent, // Transparent background
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20), // Rounded edges
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            // Frosted Glass Effect
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                // Semi-transparent background
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.red, size: 50),
                  const SizedBox(height: 15),
                  const Text(
                    "Confirm Logout",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Are you sure you want to logout?",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Cancel Button
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text("Cancel",
                            style: TextStyle(fontSize: 16, color: Colors.blue)),
                      ),
                      // Logout Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: () async {
                          Get.back(); // Close Dialog
                          try {
                            await authController.signOut();
                          } catch (e) {
                            print("Error signing out: $e");
                            Get.snackbar("Logout Failed",
                                "An error occurred during logout.");
                          }
                        },
                        child: const Text("Logout",
                            style:
                                TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
