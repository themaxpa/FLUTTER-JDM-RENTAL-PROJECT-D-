import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app/user/update_user_profile.dart';

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
      _isLoading = true;
    });

    _user = _auth.currentUser;

    if (_user != null) {
      try {
        _userData = await _firestore.collection('users').doc(_user!.uid).get();
      } catch (error) {
        print("Error fetching user data: $error");
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'Profile Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(
                child:
                    CupertinoActivityIndicator(radius: 16)) // iOS-style loader
            : _user == null
                ? const Center(
                    child: Text(
                      'No user logged in.',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  )
                : _userData == null || !_userData!.exists
                    ? const Center(
                        child: Text(
                          'User data not found.',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Profile Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: Image.asset(
                                'assets/images/ph12.jpg',
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // User Details
                            Material(
                                child:
                                    _buildInfoRow('Name', _userData!['name'])),
                            Material(
                                child: _buildInfoRow(
                                    'Email', _userData!['email'])),
                            Material(
                                child: _buildInfoRow(
                                    'Phone', _userData!['phone'])),
                            Material(
                                child: _buildInfoRow(
                                    'Location', _userData!['location'])),
                            Material(
                                child:
                                    _buildInfoRow('Role', _userData!['role'])),

                            const SizedBox(height: 30),

                            // Edit Profile Button
                            CupertinoButton.filled(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
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

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey5,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Material(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  backgroundColor: CupertinoColors.systemGrey5,
                ),
              ),
            ),
            Material(
              child: Text(
                value ?? 'N/A',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.systemGrey,
                  backgroundColor: CupertinoColors.systemGrey5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
