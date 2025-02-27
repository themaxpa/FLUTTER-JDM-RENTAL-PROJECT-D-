import 'package:flutter/material.dart';
import 'package:flutter_app/db/functions.dart';
import 'package:flutter_app/user/profile_details.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart'; // Ensure this import is present

// Define tPrimaryColor and tBlackColor (or import from your constants file)
const tPrimaryColor = Colors.blue; // Replace with your actual primary color
const tBlackColor = Colors.black; // Replace with your actual black color

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

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

    // Initialize Firebase (if not already initialized)
    if (Firebase.apps.isEmpty) {
      Firebase.initializeApp();
    }

    // Get current user from Firebase Authentication
    final user = auth.currentUser;

    // Check if user is authenticated
    if (user != null) {
      // Set text controllers with current user's information
      nameController.text = user.displayName ?? '';
      emailController.text = user.email ?? '';

      // Fetch additional user data from Firestore
      fetchUserData(user.uid);
    }
  }

  Future<void> fetchUserData(String uid) async {
    try {
      final userData = await DatabaseMethods().getUserDetails(uid);
      if (userData.exists) {
        // Set text controllers with data from Firestore
        final data = userData.data() as Map<String, dynamic>?;
        if (data != null) {
          nameController.text = data['name'] ?? '';
          emailController.text = data['email'] ?? '';
          phoneController.text = data['phone'] ?? ''; // Use null-aware operator
          locationController.text =
              data['location'] ?? ''; // Use null-aware operator
        }
      } else {
        print("No user data found in Firestore for UID: $uid");
      }
    } catch (e) {
      print("Error fetching user data from Firestore: $e");
    }
  }

  // Function to show an AlertDialog
  void _showAlertDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
          ],
        );
      },
    );
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
                        fit: BoxFit.cover, // Ensure the image fits properly
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
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
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(LineAwesomeIcons.user),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(LineAwesomeIcons.envelope),
                      ),
                      keyboardType: TextInputType.emailAddress,
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
                      keyboardType: TextInputType.phone,
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
                            final auth = FirebaseAuth.instance;
                            final user = auth.currentUser;

                            if (user != null) {
                              // Build the user info map, only adding fields that are non-empty
                              Map<String, dynamic> userInfoMap = {};

                              userInfoMap["name"] = nameController.text;
                              userInfoMap["email"] = emailController.text;

                              // Add phone and location only if they are not empty
                              if (phoneController.text.isNotEmpty) {
                                userInfoMap["phone"] = phoneController.text;
                              }
                              if (locationController.text.isNotEmpty) {
                                userInfoMap["location"] =
                                    locationController.text;
                              }
                              try {
                                await DatabaseMethods()
                                    .addUserDetails(userInfoMap, user.uid);

                                await user
                                    .updateDisplayName(nameController.text);
                                await user.verifyBeforeUpdateEmail(
                                    emailController.text);

                                if (passwordController.text.isNotEmpty) {
                                  await user
                                      .updatePassword(passwordController.text);
                                }

                                _showAlertDialog('Success',
                                    'Profile updated successfully!'); // Show success alert
                              } catch (error) {
                                print("Error updating profile: $error");
                                _showAlertDialog('Error',
                                    'Error updating profile: $error'); // Show error alert
                              }
                            } else {
                              print("User is not logged in.");
                              _showAlertDialog('Error',
                                  'User is not logged in.'); // Show "not logged in" alert
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
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12),
                              )
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const ProfileDetailsScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent.withValues(),
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
