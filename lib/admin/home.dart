import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../screen/screen_splash.dart';
import '../main.dart'; // Import AuthController

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    AuthController authController;
    try {
      authController = Get.find<AuthController>();
    } catch (e) {
      print("AuthController not found: $e");
      return const Scaffold(
          body: Center(child: Text("Error: AuthController missing")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      drawer: _buildNavigationDrawer(authController), // Add Drawer
      body: const Center(
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
            Get.snackbar("Coming Soon", "Date feature is under development.");
          }),
          _buildDrawerItem(Icons.person, "Profile", () {
            Get.snackbar(
                "Coming Soon", "Profile feature is under development.");
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
    return const DrawerHeader(
      decoration: BoxDecoration(color: Colors.blue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.admin_panel_settings, size: 50, color: Colors.white),
          SizedBox(height: 10),
          Text(
            "Admin Panel",
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            "admin@example.com",
            style: TextStyle(color: Colors.white70, fontSize: 14),
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

  // Logout Dialog
  void _showLogoutDialog(AuthController authController) {
    Get.dialog(
      AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () {
              Get.back(); // Close dialog
            },
          ),
          TextButton(
            child: const Text("Logout"),
            onPressed: () async {
              Get.back(); // Close dialog
              try {
                await authController.signOut();
              } catch (e) {
                print("Error signing out: $e");
                Get.snackbar(
                    "Logout Failed", "An error occurred during logout.");
              }
            },
          ),
        ],
      ),
    );
  }
}
