import 'package:flutter/material.dart';
import 'package:flutter_app/db/functions.dart';
import 'package:flutter_app/user/profile_details.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import Firebase Core if you haven't already
import 'package:firebase_core/firebase_core.dart';
import 'user_profile_widget_menu.dart';

// Define tPrimaryColor and tBlackColor (or import from your constants file)
const tPrimaryColor = Colors.blue; // Replace with your actual primary color
const tBlackColor = Colors.black; // Replace with your actual black color

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({Key? key}) : super(key: key);

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
    // Initialize Firebase Authentication instance
    final auth = FirebaseAuth.instance;

    // Initialize Firebase (if not already done)
    WidgetsFlutterBinding.ensureInitialized();
    Firebase.initializeApp();

    // Get current user from Firebase Authentication
    final user = auth.currentUser;

    // Check if user is authenticated
    if (user != null) {
      // Set text controllers with current user's information
      nameController.text = user.displayName ?? '';
      emailController.text = user.email ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(LineAwesomeIcons.angle_left_solid),
        ),
        title: Text('Edit User Profile',
            style: Theme.of(context).textTheme.headlineMedium),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              // -- IMAGE with ICON
              Stack(
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: const Image(
                        image: AssetImage('assets/images/ph12.jpg'),
                        // Ensure this image exists
                        fit: BoxFit.cover, // Ensure the image fits properly
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      // Make the icon tappable
                      onTap: () {
                        // Implement image selection logic here
                        print("Change profile picture tapped");
                      },
                      child: Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          color: tPrimaryColor,
                        ),
                        child: const Icon(LineAwesomeIcons.camera_solid,
                            color: Colors.black, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),

              // -- Form Fields
              Form(
                key: _formKey, // Assign the form key
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(LineAwesomeIcons.user),
                      ),
                      validator: (value) {
                        // Add basic validation
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20), // Increased spacing
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(LineAwesomeIcons.envelope),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      // Hint to keyboard
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(LineAwesomeIcons.phone_alt_solid),
                      ),
                      keyboardType: TextInputType.phone, // Hint to keyboard
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        prefixIcon: Icon(LineAwesomeIcons.location_arrow_solid),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.fingerprint),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? LineAwesomeIcons.eye_slash
                                : LineAwesomeIcons.eye,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // -- Form Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            // Validate the form
                            // Form is valid, process data
                            print("Form is valid, processing data...");

                            // Get the current user from Firebase Auth
                            final auth = FirebaseAuth.instance;
                            final user = auth.currentUser;

                            if (user != null) {
                              // Create a map of the user info to update
                              Map<String, dynamic> userInfoMap = {
                                "name": nameController.text,
                                "email": emailController.text,
                                "phone": phoneController.text,
                                "location": locationController.text,
                                // Access the text value
                                // DO NOT include "role" in the map being sent to Firestore
                                // Let admins or secure backend functions handle role management.
                              };
                              try {
                                // Call the DatabaseMethods function to update user details
                                await DatabaseMethods()
                                    .addUserDetails(userInfoMap, user.uid);

                                // Optionally, update the user's profile in Firebase Auth
                                await user
                                    .updateDisplayName(nameController.text);
                                await user.updateEmail(emailController.text);
                                // Update the password using Firebase Auth, NOT Firestore
                                if (passwordController.text.isNotEmpty) {
                                  await user
                                      .updatePassword(passwordController.text);
                                }

                                // Show a success message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Profile updated successfully!'),
                                  ),
                                );
                              } catch (error) {
                                // Handle errors
                                print("Error updating profile: $error");
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Error updating profile: $error'),
                                  ),
                                );
                              }
                            } else {
                              // Handle the case where the user is not logged in.
                              print("User is not logged in.");
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('User is not logged in.'),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2.0),
                          ),
                          backgroundColor: Colors.blueGrey,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 15),
                        ),
                        child: const Text(
                          'Update Profile',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // -- Created Date and Delete Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text.rich(
                          TextSpan(
                            text: 'Created Date: ',
                            style: TextStyle(fontSize: 12),
                            children: [
                              TextSpan(
                                text: 'Some Date Here',
                                // Replace with actual date
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12),
                              )
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Implement delete account logic here
                            print("Delete account tapped");
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const ProfileDetailsScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent.withOpacity(0.1),
                            elevation: 0,
                            foregroundColor: Colors.blue,
                            shape: const StadiumBorder(),
                            side: BorderSide.none,
                          ),
                          child: const Text('User Details'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
