import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/vendor/vendor_home.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_app/user/showroom.dart';
import 'admin/home.dart';
import 'package:flutter_app/screen/screen_splash.dart';

const String ROLE_KEY = 'user_role';
const String UID_KEY = 'user_uid';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Get.put(AuthController(), permanent: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'PROJECT D',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: GoogleFonts.mulishTextTheme(),
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthCheck(),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({Key? key}) : super(key: key);

  @override
  _AuthCheckState createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthAndRole();
  }

  Future<void> _checkAuthAndRole() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      String? cachedRole = prefs.getString(ROLE_KEY);
      String? cachedUid = prefs.getString(UID_KEY);

      if (cachedRole != null && cachedUid == user.uid) {
        _navigateToHomeScreen(cachedRole);
      } else {
        try {
          String role = await Get.find<AuthController>().getUserRole(user.uid);
          await _cacheUserRole(role, user.uid);
          _navigateToHomeScreen(role);
        } catch (error) {
          print("Error fetching user role: $error");
          _navigateToSplashScreen();
        }
      }
    } else {
      _navigateToSplashScreen();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cacheUserRole(String role, String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ROLE_KEY, role.trim().toLowerCase());
    await prefs.setString(UID_KEY, uid);
    print("Cached Role: ${prefs.getString(ROLE_KEY)}");
  }

  void _navigateToHomeScreen(String role) {
    // Determine the correct home screen based on the user role.
    Widget? homeScreen;
    switch (role.trim().toLowerCase()) {
      case 'admin':
        homeScreen = const AdminHome();
        break;
      case 'vendor':
      case 'vendors':
        homeScreen = const SellerHome();
        break;
      case 'user':
      case 'users':
        homeScreen = const Showroom();
        break;
      default:
        print("Invalid role detected: $role");
        // If role is invalid, fallback to the splash screen.
        _navigateToSplashScreen();
        return;
    }

    // Navigate after the current frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offAll(() => homeScreen!);
    });
  }

  void _navigateToSplashScreen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offAll(() => const SplashScreen());
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : const SizedBox.shrink();
  }
}

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Rx<User?> user = Rx<User?>(null);

  @override
  void onInit() {
    super.onInit();
    user.bindStream(_auth.authStateChanges());
  }

  Future<String> getUserRole(String uid) async {
    // Helper function to safely get the role from a document's data.
    String? extractRole(Map<String, dynamic>? data) {
      if (data == null) return null;
      // Try both uppercase and lowercase field keys.
      return (data['ROLE'] ?? data['role'])?.toString();
    }

    // Check the 'admin' collection.
    DocumentSnapshot adminDoc =
        await _firestore.collection('admin').doc(uid).get();
    if (adminDoc.exists) {
      String? role = extractRole(adminDoc.data() as Map<String, dynamic>?);
      if (role != null && role.isNotEmpty) {
        print("User found in 'admin' collection with role: $role");
        return role.trim().toLowerCase();
      }
    }

    // Check the 'vendors' collection.
    DocumentSnapshot vendorDoc =
        await _firestore.collection('vendors').doc(uid).get();
    if (vendorDoc.exists) {
      String? role = extractRole(vendorDoc.data() as Map<String, dynamic>?);
      if (role != null && role.isNotEmpty) {
        print("User found in 'vendors' collection with role: $role");
        return role.trim().toLowerCase();
      }
    }

    // Check the 'users' collection.
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(uid).get();
    if (userDoc.exists) {
      String? role = extractRole(userDoc.data() as Map<String, dynamic>?);
      if (role != null && role.isNotEmpty) {
        print("User found in 'users' collection with role: $role");
        return role.trim().toLowerCase();
      }
    }

    // If no document is found, default to 'user'.
    print("User not found in any collection, defaulting to 'user'");
    return 'user';
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ROLE_KEY);
    await prefs.remove(UID_KEY);
    await _auth.signOut();
    Get.offAll(() => const SplashScreen());
  }
}
