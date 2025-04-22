import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/admin/profile.dart';
import 'package:flutter_app/admin/users.dart';
import 'package:get/get.dart';
import 'dart:ui';

import '../main.dart';
import 'all_cars.dart';

// Constants for the app
class AppConstants {
  static const String usersCollection = 'users';
  static const String nameField = 'name';
  static const String emailField = 'email';
  static const Duration snackbarDuration = Duration(seconds: 3);
}

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  DocumentSnapshot? _userData;
  bool _isLoading = true;
  bool _isDarkMode =
      WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
  bool _isDrawerOpen = false;
  int _totalCars = 0;
  int _activeRentals = 0;
  int _availableCars = 0;
  double _totalRevenue = 0.0;
  List<Map<String, dynamic>> _recentActivities = [];
  List<Map<String, dynamic>> _notifications = [];
  int _unreadNotifications = 0;
  StreamSubscription<QuerySnapshot>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCarData();
    _loadRecentActivities();
    _setupNotificationListener();
    _updateBrightness();
    WidgetsBinding.instance.window.onPlatformBrightnessChanged = () {
      _updateBrightness();
    };
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    WidgetsBinding.instance.window.onPlatformBrightnessChanged = null;
    super.dispose();
  }

  void _setupNotificationListener() {
    _notificationSubscription = _firestore
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _notifications = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              ...data,
              'id': doc.id,
            };
          }).toList();

          _unreadNotifications =
              _notifications.where((n) => n['read'] == false).length;
        });
      }
    });
  }

  Future<void> _markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
      });
    } catch (e) {
      _showErrorSnackbar(
          'Failed to mark notification as read: ${e.toString()}');
    }
  }

  Future<void> _markAllNotificationsAsRead() async {
    try {
      final batch = _firestore.batch();

      for (var notification in _notifications) {
        if (notification['read'] == false) {
          final docRef =
              _firestore.collection('notifications').doc(notification['id']);
          batch.update(docRef, {'read': true});
        }
      }

      await batch.commit();
    } catch (e) {
      _showErrorSnackbar(
          'Failed to mark notifications as read: ${e.toString()}');
    }
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      _user = _auth.currentUser;

      if (_user != null) {
        final DocumentSnapshot snapshot = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(_user!.uid)
            .get();

        if (mounted) {
          setState(() {
            _userData = snapshot.exists ? snapshot : null;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _userData = null;
            _isLoading = false;
          });
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackbar('Failed to load user data: ${error.toString()}');
      }
    }
  }

  Future<void> _loadCarData() async {
    try {
      // Get total cars count
      final QuerySnapshot carSnapshot = await _firestore
          .collection('vendors')
          .doc('carDetails')
          .collection('CarDetails')
          .get();

      // Get active rentals count
      final QuerySnapshot activeRentalsSnapshot = await _firestore
          .collection('vendors')
          .doc('carDetails')
          .collection('CarDetails')
          .where('status', isEqualTo: 'rented')
          .get();

      // Get available cars count
      final QuerySnapshot availableCarsSnapshot = await _firestore
          .collection('vendors')
          .doc('CarDetails')
          .collection('CarDetails')
          .where('status', isEqualTo: 'approved')
          .get();

      // Calculate total revenue (this is a placeholder - you'll need to implement the actual revenue calculation)
      double revenue = 0.0;
      for (var doc in activeRentalsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        revenue += (data['price'] ?? 0).toDouble();
      }

      if (mounted) {
        setState(() {
          _totalCars = carSnapshot.docs.length;
          _activeRentals = activeRentalsSnapshot.docs.length;
          _availableCars = availableCarsSnapshot.docs.length;
          _totalRevenue = revenue;
        });
      }
    } catch (error) {
      _showErrorSnackbar('Failed to load car data: ${error.toString()}');
    }
  }

  Future<void> _loadRecentActivities() async {
    try {
      // Get recent user activities (logins and registrations)
      final QuerySnapshot userActivities = await _firestore
          .collection('users')
          .orderBy('lastLoginAt', descending: true)
          .limit(10)
          .get();

      List<Map<String, dynamic>> activities = [];

      for (var doc in userActivities.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final Timestamp? lastLoginAt = data['lastLoginAt'] as Timestamp?;
        final Timestamp? createdAt = data['createdAt'] as Timestamp?;
        final String? lastLoginEmail = data['lastLoginEmail'] as String?;

        if (lastLoginAt != null) {
          activities.add({
            'type': 'login',
            'userName': data['name'] ?? 'Unknown User',
            'email': lastLoginEmail ?? data['email'] ?? 'No email',
            'timestamp': lastLoginAt,
            'role': data['role'] ?? 'user',
            'userId': doc.id,
          });
        }

        if (createdAt != null) {
          activities.add({
            'type': 'registration',
            'userName': data['name'] ?? 'Unknown User',
            'email': data['email'] ?? 'No email',
            'timestamp': createdAt,
            'role': data['role'] ?? 'user',
            'userId': doc.id,
          });
        }
      }

      // Sort activities by timestamp
      activities.sort((a, b) =>
          (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));

      if (mounted) {
        setState(() {
          _recentActivities = activities;
        });
      }
    } catch (error) {
      _showErrorSnackbar(
          'Failed to load recent activities: ${error.toString()}');
    }
  }

  String _getTimeAgo(Timestamp timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp.toDate());

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      duration: AppConstants.snackbarDuration,
      backgroundColor:
          _isDarkMode ? CupertinoColors.darkBackgroundGray : Colors.white,
      colorText: _isDarkMode ? CupertinoColors.white : CupertinoColors.black,
    );
  }

  void _updateBrightness() {
    setState(() {
      _isDarkMode =
          WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
    });
  }

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    AuthController authController;
    try {
      authController = Get.find<AuthController>();
    } catch (e) {
      return _buildErrorScreen('AuthController not found: $e');
    }

    return Scaffold(
      backgroundColor: _isDarkMode ? CupertinoColors.black : Colors.grey[200],
      appBar: AppBar(
        backgroundColor: _isDarkMode ? CupertinoColors.black : Colors.grey[200],
        title: Text(
          'Admin Dashboard',
          style: TextStyle(
            color: _isDarkMode ? CupertinoColors.white : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      drawer: _buildNavigationDrawer(authController),
      body: _isLoading ? _buildLoadingIndicator() : _buildMainContent(),
    );
  }

  Widget _buildErrorScreen(String message) {
    return Scaffold(
      backgroundColor: _isDarkMode ? CupertinoColors.black : Colors.grey[200],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 48,
              color: _isDarkMode
                  ? CupertinoColors.white
                  : CupertinoColors.destructiveRed,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    _isDarkMode ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Try to reload the controller or navigate back
                Get.back();
              },
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CupertinoActivityIndicator(
            color: _isDarkMode ? CupertinoColors.white : CupertinoColors.black,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading...',
            style: TextStyle(
              color:
                  _isDarkMode ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(),
          const SizedBox(height: 24),
          _buildStatsSection(),
          const SizedBox(height: 24),
          _buildNotificationsSection(),
          const SizedBox(height: 24),
          _buildRecentActivitySection(),
          const SizedBox(height: 24),
          _buildQuickActionsSection(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDarkMode
              ? [CupertinoColors.darkBackgroundGray, CupertinoColors.black]
              : [Colors.blue.shade700, Colors.blue.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    fontSize: 18,
                    color: _isDarkMode
                        ? CupertinoColors.white.withOpacity(0.8)
                        : Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _userData != null
                      ? (_userData!.get(AppConstants.nameField) ?? 'Admin')
                      : 'Admin',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Here\'s what\'s happening with your car rental business today.',
                  style: TextStyle(
                    fontSize: 14,
                    color: _isDarkMode
                        ? CupertinoColors.white.withOpacity(0.7)
                        : Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.directions_car,
            size: 60,
            color: _isDarkMode
                ? CupertinoColors.white.withOpacity(0.8)
                : Colors.white.withOpacity(0.8),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Material(
            color: Colors.transparent,
            child: Text(
              'Business Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color:
                    _isDarkMode ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatCard(
              'Total Cars',
              _totalCars.toString(),
              CupertinoIcons.car_detailed,
              CupertinoColors.systemBlue,
            ),
            _buildStatCard(
              'Active Rentals',
              _activeRentals.toString(),
              CupertinoIcons.car_detailed,
              CupertinoColors.systemGreen,
            ),
            _buildStatCard(
              'Available Cars',
              _availableCars.toString(),
              CupertinoIcons.checkmark_circle,
              CupertinoColors.systemOrange,
            ),
            _buildStatCard(
              'Total Revenue',
              'AED ${_totalRevenue.toStringAsFixed(2)}',
              CupertinoIcons.money_dollar_circle,
              CupertinoColors.systemPurple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? CupertinoColors.darkBackgroundGray : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 32,
            color: color,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color:
                  _isDarkMode ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: _isDarkMode
                  ? CupertinoColors.white.withOpacity(0.7)
                  : CupertinoColors.black.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color:
                    _isDarkMode ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
            if (_unreadNotifications > 0)
              TextButton(
                onPressed: _markAllNotificationsAsRead,
                child: Text(
                  'Mark all as read',
                  style: TextStyle(
                    color:
                        _isDarkMode ? CupertinoColors.systemBlue : Colors.blue,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color:
                _isDarkMode ? CupertinoColors.darkBackgroundGray : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _isDarkMode
                    ? Colors.black.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _notifications.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'No notifications',
                      style: TextStyle(
                        color: _isDarkMode
                            ? CupertinoColors.white.withOpacity(0.7)
                            : CupertinoColors.black.withOpacity(0.7),
                      ),
                    ),
                  ),
                )
              : Column(
                  children: _notifications.map((notification) {
                    final bool isLogin = notification['type'] == 'login';
                    final bool isUnread = notification['read'] == false;
                    final IconData icon = isLogin
                        ? CupertinoIcons.person_crop_circle_badge_checkmark
                        : CupertinoIcons.bell;
                    final Color color = isLogin
                        ? (_isDarkMode
                            ? CupertinoColors.systemGreen
                            : Colors.green)
                        : (_isDarkMode
                            ? CupertinoColors.systemBlue
                            : Colors.blue);

                    return Column(
                      children: [
                        InkWell(
                          onTap: () {
                            if (isUnread) {
                              _markNotificationAsRead(notification['id']);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    icon,
                                    color: color,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            notification['title'] ??
                                                'Notification',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: _isDarkMode
                                                  ? CupertinoColors.white
                                                  : CupertinoColors.black,
                                            ),
                                          ),
                                          if (isUnread)
                                            Container(
                                              margin: const EdgeInsets.only(
                                                  left: 8),
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notification['message'] ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _isDarkMode
                                              ? CupertinoColors.white
                                                  .withOpacity(0.7)
                                              : CupertinoColors.black
                                                  .withOpacity(0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _getTimeAgo(notification['timestamp']),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _isDarkMode
                                              ? CupertinoColors.white
                                                  .withOpacity(0.5)
                                              : CupertinoColors.black
                                                  .withOpacity(0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_notifications.last != notification)
                          _buildActivityDivider(),
                      ],
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color:
                    _isDarkMode ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
            TextButton(
              onPressed: _loadRecentActivities,
              child: Text(
                'Refresh',
                style: TextStyle(
                  color: _isDarkMode ? CupertinoColors.systemBlue : Colors.blue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color:
                _isDarkMode ? CupertinoColors.darkBackgroundGray : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _isDarkMode
                    ? Colors.black.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _recentActivities.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'No recent activities',
                      style: TextStyle(
                        color: _isDarkMode
                            ? CupertinoColors.white.withOpacity(0.7)
                            : CupertinoColors.black.withOpacity(0.7),
                      ),
                    ),
                  ),
                )
              : Column(
                  children: _recentActivities.map((activity) {
                    final bool isLogin = activity['type'] == 'login';
                    final IconData icon = isLogin
                        ? CupertinoIcons.person_crop_circle_badge_checkmark
                        : CupertinoIcons.person_add;
                    final Color color = isLogin
                        ? (_isDarkMode
                            ? CupertinoColors.systemGreen
                            : Colors.green)
                        : (_isDarkMode
                            ? CupertinoColors.systemBlue
                            : Colors.blue);

                    return Column(
                      children: [
                        _buildActivityItem(
                          isLogin ? 'User Login' : 'New Registration',
                          '${activity['userName']} (${activity['role']})\n${activity['email']}',
                          _getTimeAgo(activity['timestamp']),
                          icon,
                          color,
                        ),
                        if (_recentActivities.last != activity)
                          _buildActivityDivider(),
                      ],
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String description, String time,
      IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isDarkMode
                        ? CupertinoColors.white
                        : CupertinoColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: _isDarkMode
                        ? CupertinoColors.white.withOpacity(0.7)
                        : CupertinoColors.black.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: _isDarkMode
                        ? CupertinoColors.white.withOpacity(0.5)
                        : CupertinoColors.black.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityDivider() {
    return Divider(
      height: 1,
      color: _isDarkMode
          ? CupertinoColors.white.withOpacity(0.1)
          : CupertinoColors.black.withOpacity(0.1),
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _isDarkMode ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Manage Cars',
                CupertinoIcons.car_detailed,
                _isDarkMode ? CupertinoColors.systemBlue : Colors.blue,
                () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (_) => AllCarsScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                'Manage Users',
                CupertinoIcons.person_2,
                _isDarkMode ? CupertinoColors.systemGreen : Colors.green,
                () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (_) => UsersCardScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'View Reports',
                CupertinoIcons.chart_bar,
                _isDarkMode ? CupertinoColors.systemOrange : Colors.orange,
                () {
                  Get.snackbar(
                    "Coming Soon",
                    "Reports feature is under development.",
                    duration: AppConstants.snackbarDuration,
                    backgroundColor: _isDarkMode
                        ? CupertinoColors.darkBackgroundGray
                        : Colors.white,
                    colorText: _isDarkMode
                        ? CupertinoColors.white
                        : CupertinoColors.black,
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                'Settings',
                CupertinoIcons.settings,
                _isDarkMode ? CupertinoColors.systemPurple : Colors.purple,
                () {
                  Get.snackbar(
                    "Coming Soon",
                    "Settings feature is under development.",
                    duration: AppConstants.snackbarDuration,
                    backgroundColor: _isDarkMode
                        ? CupertinoColors.darkBackgroundGray
                        : Colors.white,
                    colorText: _isDarkMode
                        ? CupertinoColors.white
                        : CupertinoColors.black,
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color:
              _isDarkMode ? CupertinoColors.darkBackgroundGray : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _isDarkMode
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color:
                    _isDarkMode ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Navigation Drawer
  Widget _buildNavigationDrawer(AuthController authController) {
    return Drawer(
      backgroundColor:
          _isDarkMode ? CupertinoColors.black : CupertinoColors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(),
          _buildDrawerItem(Icons.dashboard, "Dashboard", () {
            Navigator.pop(context); // Close drawer
          }),
          _buildDrawerItem(Icons.settings, "Settings", () {
            Navigator.pop(context); // Close drawer
            Get.snackbar(
              "Coming Soon",
              "Settings feature is under development.",
              duration: AppConstants.snackbarDuration,
              backgroundColor: _isDarkMode
                  ? CupertinoColors.darkBackgroundGray
                  : Colors.white,
              colorText:
                  _isDarkMode ? CupertinoColors.white : CupertinoColors.black,
            );
          }),
          _buildDrawerItem(Icons.person, "Users", () {
            Navigator.pop(context); // Close drawer
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (_) => UsersCardScreen()),
            );
          }),
          _buildDrawerItem(Icons.car_rental, "Cars", () {
            Navigator.pop(context); // Close drawer
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (_) => AllCarsScreen()),
            );
          }),
          _buildDrawerItem(Icons.person, "Profile", () {
            Navigator.pop(context); // Close drawer
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (_) => const AdminProfileScreen()),
            );
          }),
          Divider(
              color:
                  _isDarkMode ? CupertinoColors.white : CupertinoColors.black),
          _buildDrawerItem(Icons.logout, "Logout", () {
            Navigator.pop(context); // Close drawer
            _showLogoutDialog(authController);
          }),
        ],
      ),
    );
  }

  // Drawer Header
  Widget _buildDrawerHeader() {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: _isDarkMode ? CupertinoColors.darkBackgroundGray : Colors.black,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.admin_panel_settings,
            size: 50,
            color: _isDarkMode ? CupertinoColors.white : Colors.white,
          ),
          const SizedBox(height: 10),
          Text(
            _userData != null
                ? (_userData!.get(AppConstants.nameField) ?? 'N/A')
                : 'N/A',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? CupertinoColors.white : Colors.white,
            ),
          ),
          Text(
            _user?.email ?? 'N/A',
            style: TextStyle(
              fontSize: 14,
              color: _isDarkMode ? CupertinoColors.white : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  // Drawer Item
  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(
        icon,
        color: _isDarkMode ? CupertinoColors.white : CupertinoColors.black,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: _isDarkMode ? CupertinoColors.white : CupertinoColors.black,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(AuthController authController) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _isDarkMode
                    ? CupertinoColors.darkBackgroundGray.withOpacity(0.8)
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: _isDarkMode ? CupertinoColors.systemRed : Colors.red,
                    size: 50,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Confirm Logout",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _isDarkMode ? CupertinoColors.white : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Are you sure you want to logout?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: _isDarkMode ? CupertinoColors.white : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            fontSize: 16,
                            color: _isDarkMode
                                ? CupertinoColors.systemBlue
                                : Colors.blue,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isDarkMode
                              ? CupertinoColors.systemRed
                              : Colors.redAccent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: () => _handleLogout(authController),
                        child: Text(
                          "Logout",
                          style: TextStyle(
                            fontSize: 16,
                            color: _isDarkMode
                                ? CupertinoColors.white
                                : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(AuthController authController) async {
    Get.back(); // Close Dialog
    try {
      await authController.signOut();
    } catch (e) {
      _showErrorSnackbar('Failed to logout: ${e.toString()}');
    }
  }
}
