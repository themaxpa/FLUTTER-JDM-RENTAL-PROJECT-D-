import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Signup Function
  Future<String?> signup({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user == null) return 'User creation failed.';

      String uid = user.uid;
      String roleLower = role.toLowerCase();
      String collection = _getCollectionForRole(roleLower);
      if (collection.isEmpty) return "Invalid role specified.";

      WriteBatch batch = _firestore.batch();
      DocumentReference userRef = _firestore.collection(collection).doc(uid);

      batch.set(userRef, {
        'uid': uid,
        'name': name,
        'email': email,
        'role': roleLower,
        'profileImage': '',
        'phone': '',
        'location': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (roleLower == 'vendor') {
        _addVendorSubcollections(uid, batch);
      } else if (roleLower == 'user') {
        _addUserSubcollection(uid, batch);
      }

      await batch.commit();
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    } catch (e) {
      debugPrint("\uD83D\uDD25 Signup Error: $e");
      return 'An unexpected error occurred.';
    }
  }

  // Login Function
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user == null) return 'Login failed. Please try again.';

      String uid = user.uid;
      String? role = await _getUserRoleFromFirestore(uid);
      if (role == null) return 'User data not found.';

      await _ensurePhoneAndLocation(uid, role);

      debugPrint("✅ Login Successful: Role - $role");
      return role;
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    } catch (e) {
      debugPrint("\uD83D\uDD25 Login Error: $e");
      return 'An unexpected error occurred.';
    }
  }

  // Ensure phone and location exist
  Future<void> _ensurePhoneAndLocation(String uid, String role) async {
    String collection = _getCollectionForRole(role);
    if (collection.isEmpty) return;

    DocumentReference userRef = _firestore.collection(collection).doc(uid);
    DocumentSnapshot doc = await userRef.get();
    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

    if (data != null) {
      Map<String, dynamic> updateData = {};
      if (data['phone'] == null || data['phone'].toString().isEmpty) {
        updateData['phone'] = '';
      }

      if (data['location'] == null || data['location'].toString().isEmpty) {
        updateData['location'] = '';
      }

      if (updateData.isNotEmpty) {
        await userRef.update(updateData);
        debugPrint("\uD83D\uDCCC Updated phone & location for $role: $uid");
      }
    }
  }

  // Fetch User Role from Firestore
  Future<String?> _getUserRoleFromFirestore(String uid) async {
    try {
      debugPrint("\uD83D\uDD0D Checking role for UID: $uid");

      List<String> collections = ['admin', 'vendors', 'users'];
      for (String collection in collections) {
        DocumentSnapshot doc =
            await _firestore.collection(collection).doc(uid).get();

        debugPrint(
            "\uD83D\uDCC4 Checking in collection: $collection, Exists: ${doc.exists}");

        if (doc.exists) {
          Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
          if (data != null && data['role'] != null) {
            String role = data['role'].toString().toLowerCase();
            debugPrint("✅ Found role: $role in $collection");
            return role;
          }
        }
      }

      debugPrint("❌ No role found for UID: $uid");
      return null;
    } catch (e) {
      debugPrint("\uD83D\uDD25 Error fetching role: $e");
      return null;
    }
  }

  // Create User Subcollection
  void _addUserSubcollection(String uid, WriteBatch batch) {
    batch.set(
      _firestore.collection('users').doc(uid).collection('MyDocuments').doc(),
      {
        'DLFrontSide': '',
        'DLBackSide': '',
        'PanCard': '',
        'timestamp': FieldValue.serverTimestamp(),
        'AadhaarCardFront': '',
        'AadhaarCardBack': '',
      },
    );
  }

  // Create Vendor Subcollections
  void _addVendorSubcollections(String uid, WriteBatch batch) {
    batch.set(
      _firestore
          .collection('vendors')
          .doc(uid)
          .collection('CompanyDetails')
          .doc(),
      {
        'companyName': 'Default Company',
        'companyLogo': '',
        'companyAbout': '',
        'location': 'Not specified',
        'contact': '',
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
  }

  // Determine Firestore Collection for Role
  String _getCollectionForRole(String role) {
    switch (role) {
      case 'admin':
        return 'admin';
      case 'vendor':
        return 'vendors';
      case 'user':
        return 'users';
      default:
        return '';
    }
  }

  // Handle FirebaseAuthException Errors
  String _handleAuthError(FirebaseAuthException e) {
    const errorMessages = {
      'weak-password': 'The password is too weak.',
      'email-already-in-use': 'The email address is already in use.',
      'user-not-found': 'No user found with this email.',
      'wrong-password': 'Incorrect password.',
      'invalid-email': 'Invalid email format.',
    };
    return errorMessages[e.code] ??
        e.message ??
        'An authentication error occurred.';
  }

  // SignOut Function
  Future<String?> signOut() async {
    try {
      await _auth.signOut();
      return null;
    } catch (e) {
      debugPrint("\uD83D\uDD25 SignOut Error: $e");
      return 'An error occurred while signing out.';
    }
  }
}
