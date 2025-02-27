import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_app/seller/seller_home.dart';
import 'package:flutter_app/user/showroom.dart';
import 'admin/home.dart';
import 'package:flutter_app/screen/fullscreen.dart';
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
      home: AuthCheck(),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  _AuthCheckState createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  String? _cachedRole;
  String? _cachedUid;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthAndRole();
  }

  Future<void> _checkAuthAndRole() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      _cachedRole = prefs.getString(ROLE_KEY);
      _cachedUid = prefs.getString(UID_KEY);

      //Also check the User to verify current user;
      if (_cachedRole != null && _cachedUid == user.uid) {
        //Navigate to the homeScreen with push and Remove Until to never allow the back button
        _navigateToHomeScreen(_cachedRole!);
      } else {
        final authController = Get.find<AuthController>();
        try {
          String role = await authController.getUserRole(user.uid);
          //Cache the role
          _cacheUserRole(role, user.uid);

          //Navigate to homeScreen
          _navigateToHomeScreen(role);
        } catch (error) {
          print("Error fetching user role: $error");
          //If for some reason it is unable to redirect
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

  // Navigate to the HomeScreen
  void _navigateToHomeScreen(String role) {
    print("Navigating to home screen for role: $role"); // Debugging

    Widget homeScreen;

    if (role.trim().toLowerCase() == 'admin') {
      homeScreen = const AdminHome();
    } else if (role.trim().toLowerCase() == 'seller') {
      homeScreen = const SellerHome();
    } else if (role.trim().toLowerCase() == 'user') {
      homeScreen = const Showroom();
    } else {
      print("Invalid role detected: $role"); // Debugging
      homeScreen = const FullScreenBackground(); // Default case
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => homeScreen),
        (route) => false,
      );
    });
  }

  //If the app is unable to get the desired user, Navigate to the login Screen.
  void _navigateToSplashScreen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SplashScreen()),
          (route) => false);
    });
  }

  Future<void> _cacheUserRole(String role, String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ROLE_KEY, role.trim().toLowerCase());
    await prefs.setString(UID_KEY, uid);
    print("Cached Role: ${prefs.getString(ROLE_KEY)}"); // Debugging
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
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        var data = userDoc.data() as Map<String, dynamic>?;
        String? role = data?['ROLE'];

        if (role != null) {
          print("Fetched role from Firestore: $role"); // Debugging
          return role.trim().toLowerCase();
        }
      }
      print('User document does not exist for UID: $uid');
      return 'user'; // Default to 'user' if no role found
    } catch (e) {
      print('Error fetching user role: $e');
      return 'user';
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ROLE_KEY);
    await prefs.remove(UID_KEY);
    await _auth.signOut();
    Get.offAll(() => const SplashScreen()); // Navigate to SplashScreen
  }
}
