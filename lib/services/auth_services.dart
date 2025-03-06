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

      // Store additional user data in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': name,
        'email': email,
        'role': role,
      });

      // Create 'MyDocuments' subcollection for the user
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .collection('MyDocuments')
          .doc('initialDocument') // Optional: Create an initial document
          .set({
        'title': 'Initial Document',
        'timestamp': FieldValue.serverTimestamp(),
      });

      return null; // Return null on successful signup
    } on FirebaseAuthException catch (e) {
      // Handle FirebaseAuth errors (e.g., email already in use, weak password)
      if (e.code == 'weak-password') {
        return 'The password is too weak.';
      } else if (e.code == 'email-already-in-use') {
        return 'The email address is already in use.';
      } else {
        return e.message ?? 'An error occurred during signup.';
      }
    } catch (e) {
      // Handle any other errors (e.g., Firestore issues)
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
        // Use toLowerCase for case-insensitive comparison
        String role = (userDoc['role'] as String? ?? '').toLowerCase();
        return role; // Return the user's role on successful login
      } else {
        return 'Failed to fetch user role.'; // Handle case where role is not found
      }
    } on FirebaseAuthException catch (e) {
      return e.message; // Return Firebase Auth error message
    } catch (e) {
      print(e);
      return 'An unexpected error occurred.'; // Handle other errors
    }
  }

  // SignOut Function
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
