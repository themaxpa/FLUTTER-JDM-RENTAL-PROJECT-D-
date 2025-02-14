import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/user/update_user_profile.dart';
import 'package:flutter_app/user/user_profile_widget_menu.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:get/get.dart';

import '../screen/fullscreen.dart';

// Define tPrimaryColor and tBlackColor here or import them from a constants file
const tPrimaryColor = Colors.blue; // Replace with your actual primary color
const tBlackColor = Colors.black; // Replace with your actual black color

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Get.back(); // Use Get.back() for GetX navigation
          },
          icon: const Icon(LineAwesomeIcons.angle_left_solid),
        ),
        title: Text('maxpa', style: Theme.of(context).textTheme.bodyLarge),
        actions: [
          IconButton(
            onPressed: () {
              // Implement theme toggle logic here (dark/light mode)
              // Example:
              // Get.changeTheme(Get.isDarkMode ? ThemeData.light() : ThemeData.dark());
            },
            icon: Icon(isDark ? LineAwesomeIcons.sun : LineAwesomeIcons.moon),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(10),
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
                    child: InkWell(
                      // Use InkWell for tap effect on the edit icon
                      onTap: () {
                        // Implement image edit/upload logic here
                        print("Edit profile picture tapped");
                      },
                      child: Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          color: Colors.red,
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
              Text('User Name',
                  // Fetch the user's name from somewhere (e.g., Firebase, local storage)
                  style: Theme.of(context).textTheme.bodyLarge),
              Text(
                'user@example.com', //Fetch the user's email from Firebase auth.
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),

              /// -- BUTTON
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () => Get.to(() => const UpdateProfileScreen()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tPrimaryColor,
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Edit Profile',
                      style: TextStyle(color: tBlackColor)),
                ),
              ),
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 10),

              /// -- MENU
              ProfileMenuWidget(
                title: "Settings",
                icon: LineAwesomeIcons.cog_solid,
                onPress: () {
                  // Implement settings action
                  print("Settings tapped");
                },
              ),
              ProfileMenuWidget(
                title: "Billing Details",
                icon: LineAwesomeIcons.wallet_solid,
                onPress: () {
                  // Implement billing details action
                  print("Billing Details tapped");
                },
              ),
              ProfileMenuWidget(
                title: "User Management",
                icon: LineAwesomeIcons.user_check_solid,
                onPress: () {
                  // Implement user management action
                  print("User Management tapped");
                },
              ),
              const Divider(),
              const SizedBox(height: 10),
              ProfileMenuWidget(
                title: "Information",
                icon: LineAwesomeIcons.info_solid,
                onPress: () {
                  // Implement information action
                  print("Information tapped");
                },
              ),
              ProfileMenuWidget(
                title: "Logout",
                icon: LineAwesomeIcons.sign_out_alt_solid,
                textColor: Colors.red,
                endIcon: false,
                onPress: () {
                  print("LogOut tapped");
                  _showLogoutConfirmationDialog(
                      context); // Call the private dialog function
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Made it a private method.
  void _showLogoutConfirmationDialog(BuildContext context) {
    Get.defaultDialog(
      title: "LOGOUT",
      titleStyle: const TextStyle(fontSize: 20),
      content: const Padding(
        padding: EdgeInsets.symmetric(vertical: 15.0),
        child: Text(
          "Are you sure, you want to Logout?",
          style: TextStyle(
            color: Colors.black,
          ),
        ),
      ),
      confirm: ElevatedButton(
        onPressed: () async {
          Get.back(); // Close the dialog
          await _signOut(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
        ),
        child: const Text(
          "Yes",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      cancel: TextButton(
        // Use TextButton for the "No" option.
        onPressed: () => Get.back(),
        child: const Text(
          "No",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Get.offAll(() => FullScreenBackground()); // Use Get.offAll for navigation
    } catch (e) {
      print("Error signing out: $e");
      Get.snackbar("Logout Failed",
          "An error occurred during logout."); // Use Get.snackbar for quick messages
    }
  }
}
