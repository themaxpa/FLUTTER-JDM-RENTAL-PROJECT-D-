import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      // Create user with email and password
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;

      // Store user data in Firestore with default fields
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'role': role,
        'profileImage': '', // Default empty profile image
        'phone': '', // Default empty phone number
        'location': '', // Default empty location
        'createdAt': FieldValue.serverTimestamp(), // Store signup timestamp
      });

      // Create 'MyDocuments' subcollection for the user
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('MyDocuments')
          .doc('initialDocument') // Optional: Create an initial document
          .set({
        'title': 'Initial Document',
        'timestamp': FieldValue.serverTimestamp(),
      });

      return null; // Return null on successful signup
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'The password is too weak.';
      } else if (e.code == 'email-already-in-use') {
        return 'The email address is already in use.';
      } else {
        return e.message ?? 'An error occurred during signup.';
      }
    } catch (e) {
      print("Error: $e");
      return 'An unexpected error occurred: ${e.toString()}';
    }
  }

  // Login Function
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in user with email and password
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get the user's role from Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (userDoc.exists) {
        String role = (userDoc['role'] as String? ?? '').toLowerCase();
        return role; // Return the user's role on successful login
      } else {
        return 'Failed to fetch user role.';
      }
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      print(e);
      return 'An unexpected error occurred.';
    }
  }

  // SignOut Function
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
