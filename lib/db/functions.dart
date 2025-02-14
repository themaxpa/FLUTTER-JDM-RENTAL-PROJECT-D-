// In functions.dart (or wherever your DatabaseMethods class is)
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethods {
  Future<void> addUserDetails(
      Map<String, dynamic> userInfoMap, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update(userInfoMap); // Changed from .set() to .update()
      print("User details added successfully for user: $userId"); // Log success
    } catch (e) {
      print("Error adding user details to Firestore: $e"); // Log the error
      rethrow; // Re-throw the error so the caller knows something went wrong.
    }
  }
}
