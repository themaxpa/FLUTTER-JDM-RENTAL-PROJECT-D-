// In functions.dart (or wherever your DatabaseMethods class is)
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethods {
  Future<void> addUserDetails(
      Map<String, dynamic> userInfoMap, String userId) async {
    try {
      // Reference to the user document in Firestore
      DocumentReference userDocRef =
          FirebaseFirestore.instance.collection("users").doc(userId);

      // Get existing data from Firestore
      DocumentSnapshot docSnapshot = await userDocRef.get();
      Map<String, dynamic> existingData = {};
      if (docSnapshot.exists) {
        existingData = docSnapshot.data() as Map<String, dynamic>;
      }

      // Merge existing data with new data
      Map<String, dynamic> mergedData = {
        ...existingData,
        ...userInfoMap,
      };

      // Update all the fields, including potentially new ones
      await userDocRef.set(mergedData, SetOptions(merge: true));

      print("User details updated successfully for UID: $userId");
    } catch (e) {
      print("Error adding/updating user details: $e");
      rethrow; // Re-throw the exception for the caller to handle
    }
  }

  Future<DocumentSnapshot> getUserDetails(String uid) async {
    try {
      return await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();
    } catch (e) {
      print("Error fetching user details: $e");
      rethrow; // Re-throw the exception to handle it further up the call stack
    }
  }
}
