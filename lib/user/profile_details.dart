import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app/user/update_user_profile.dart'; // Import the UpdateProfileScreen

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({Key? key}) : super(key: key);

  @override
  _ProfileDetailsScreenState createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
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
      _isLoading = true; // Show loading indicator
    });

    _user = _auth.currentUser; // Get the current user

    if (_user != null) {
      try {
        _userData = await _firestore.collection('users').doc(_user!.uid).get();

        setState(() {
          _isLoading = false; // Hide loading indicator
        });
      } catch (error) {
        print("Error fetching user data: $error");
        // Handle error (e.g., show an error message)
        setState(() {
          _isLoading = false; // Hide loading indicator
        });
      }
    } else {
      print("No user logged in.");
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
            child: const Text(
          'User Profile Details',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        )),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Loading Indicator
          : _user == null
              ? const Center(
                  child: Text('No user logged in.'),
                ) // No User Message
              : _userData == null || !_userData!.exists
                  ? const Center(
                      child: Text('User data not found.'),
                    ) // Data Not Found Message
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Name: ${_userData!['name'] ?? 'N/A'}'),
                            const SizedBox(height: 8),
                            Text('Email: ${_userData!['email'] ?? 'N/A'}'),
                            const SizedBox(height: 8),
                            Text('Phone: ${_userData!['phone'] ?? 'N/A'}'),
                            const SizedBox(height: 8),
                            Text(
                                'Location: ${_userData!['location'] ?? 'N/A'}'),
                            const SizedBox(height: 8),
                            Text(
                                'Role: ${_userData!['role'] ?? 'N/A'}'), // Display the role
                            const SizedBox(height: 8),
                            // Add more details as needed

                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const UpdateProfileScreen()),
                                );
                              },
                              child: const Text('Edit Profile'),
                            ),
                          ],
                        ),
                      ),
                    ),
    );
  }
}
