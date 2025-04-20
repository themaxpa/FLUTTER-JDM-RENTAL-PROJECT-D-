import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/vendor/vendor_showroom.dart';
import 'package:flutter_app/vendor/view_booking.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/vendor/profile/vendor_profile.dart';
import 'cars/all_cars.dart';
import 'cars/add_cars.dart';

class SellerHome extends StatefulWidget {
  const SellerHome({Key? key}) : super(key: key);

  @override
  _SellerHomeState createState() => _SellerHomeState();
}

class _SellerHomeState extends State<SellerHome> {
  int _currentIndex = 0;
  late PageController _pageController;

  final List<Widget> _pages = [
    VendorDashboard(),
    AddCars(),
    CreateAdScreen(),
    SellerProfile(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final shouldExit = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('No'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Yes'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: CupertinoPageScaffold(
        backgroundColor: CupertinoColors.systemGroupedBackground,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  physics: const NeverScrollableScrollPhysics(),
                  // Disable swipe
                  children: _pages,
                ),
              ),
              CupertinoTabBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                  _pageController.jumpToPage(index);
                },
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.car_detailed),
                    label: 'Add Car',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.add_circled),
                    label: 'Create Ad',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.person),
                    label: 'Profile',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VendorDashboard extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '₹');

  Future<int> _getCarCount(String vendorId) async {
    try {
      final querySnapshot = await _firestore
          .collection('vendors')
          .doc(vendorId)
          .collection('CarDetails')
          .get();
      return querySnapshot.size;
    } catch (e) {
      print('Error getting car count: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentVendorId = _auth.currentUser?.uid;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: _firestore
                  .collection('vendors')
                  .doc(currentVendorId)
                  .snapshots(),
              builder: (context, vendorSnapshot) {
                if (!vendorSnapshot.hasData) {
                  return const Center(child: CupertinoActivityIndicator());
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('Booking')
                      .where('carDetails.vendorId', isEqualTo: currentVendorId)
                      .snapshots(),
                  builder: (context, bookingSnapshot) {
                    // Calculate total earnings from bookings
                    double totalEarnings = 0;
                    int totalBookingsCount = 0;

                    if (bookingSnapshot.hasData) {
                      totalBookingsCount = bookingSnapshot.data!.docs.length;
                      for (var doc in bookingSnapshot.data!.docs) {
                        final booking = doc.data() as Map<String, dynamic>;
                        final amount = booking['amount'] as num? ?? 0;
                        totalEarnings += amount.toDouble();
                      }
                    }

                    final vendorData =
                        vendorSnapshot.data!.data() as Map<String, dynamic>? ??
                            {};
                    final totalCars = vendorData['totalCars'] ?? 0;

                    return FutureBuilder<int>(
                      future: _getCarCount(currentVendorId!),
                      builder: (context, carCountSnapshot) {
                        final actualCarCount = carCountSnapshot.data ?? 0;

                        return Material(
                          color: Colors.transparent,
                          child: Column(
                            children: [
                              _buildSummaryCard(
                                context,
                                title: 'Total Earnings',
                                value: _currencyFormat.format(totalEarnings),
                                icon: CupertinoIcons.money_dollar_circle,
                                color: CupertinoColors.systemGreen,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildSummaryCard(
                                      context,
                                      title: 'Cars',
                                      value: actualCarCount.toString(),
                                      icon: CupertinoIcons.car_detailed,
                                      color: CupertinoColors.systemBlue,
                                      subtitle: 'In your showroom',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildSummaryCard(
                                      context,
                                      title: 'Bookings',
                                      value: totalBookingsCount.toString(),
                                      icon: CupertinoIcons.book,
                                      color: CupertinoColors.systemPurple,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
            // Rest of your existing code...
            const SizedBox(height: 24),
            Material(
              color: Colors.transparent,
              child: const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.label,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildQuickActions(context),
            const SizedBox(height: 24),
            Material(
              color: Colors.transparent,
              child: const Text(
                'Recent Bookings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.label,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildRecentBookings(currentVendorId!),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: CupertinoColors.secondaryLabel,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildActionButton(
          context,
          icon: CupertinoIcons.car_detailed,
          label: 'View Cars',
          color: CupertinoColors.systemBlue,
          onTap: () => Navigator.push(
            context,
            CupertinoPageRoute(builder: (context) => SellerShowroom()),
          ),
        ),
        _buildActionButton(
          context,
          icon: CupertinoIcons.book,
          label: 'All Bookings',
          color: CupertinoColors.systemPurple,
          onTap: () => Navigator.push(
            context,
            CupertinoPageRoute(builder: (context) => ViewBooking()),
          ),
        ),
        _buildActionButton(
          context,
          icon: CupertinoIcons.add_circled,
          label: 'Add Car',
          color: CupertinoColors.systemGreen,
          onTap: () => Navigator.push(
            context,
            CupertinoPageRoute(builder: (context) => AddCars()),
          ),
        ),
        _buildActionButton(
          context,
          icon: CupertinoIcons.settings,
          label: 'Settings',
          color: CupertinoColors.systemGrey,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(12),
        onPressed: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.label,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentBookings(String vendorId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('Booking')
          .where('carDetails.vendorId', isEqualTo: vendorId)
          .orderBy('timestamp', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: CupertinoActivityIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Error loading bookings',
              style: TextStyle(color: CupertinoColors.systemRed),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: const Text(
                'No recent bookings',
                style: TextStyle(color: CupertinoColors.secondaryLabel),
              ),
            ),
          );
        }

        final bookings = snapshot.data!.docs;
        return Container(
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bookings.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              thickness: 0.5,
              color: CupertinoColors.separator,
            ),
            itemBuilder: (context, index) {
              final doc = bookings[index];
              final booking = doc.data() as Map<String, dynamic>;
              final carDetails = booking['carDetails'] as Map<String, dynamic>;
              final imageUrl = carDetails['frontImage'] as String?;

              return Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: CupertinoColors.systemGrey5,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                loadingBuilder: (BuildContext context,
                                    Widget child,
                                    ImageChunkEvent? loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  );
                                },
                                errorBuilder: (BuildContext context,
                                    Object error, StackTrace? stackTrace) {
                                  return Container(
                                    color: CupertinoColors.systemGrey5,
                                    child: const Center(
                                      child: Icon(
                                        CupertinoIcons.car_detailed,
                                        size: 40,
                                        color: CupertinoColors.systemGrey,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : const Center(
                                child: Icon(
                                  CupertinoIcons.car_detailed,
                                  size: 40,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${carDetails['Car Brand']} ${carDetails['Model Name']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('MMM dd, yyyy').format(
                                (booking['timestamp'] as Timestamp).toDate(),
                              ),
                              style: TextStyle(
                                color: CupertinoColors.secondaryLabel,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _currencyFormat.format(booking['amount']),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: CupertinoColors.activeGreen,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(booking['Status'])
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              booking['Status'] ?? 'Pending',
                              style: TextStyle(
                                color: _getStatusColor(booking['Status']),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
        return CupertinoColors.activeGreen;
      case 'pending':
        return CupertinoColors.systemOrange;
      case 'cancelled':
        return CupertinoColors.destructiveRed;
      default:
        return CupertinoColors.systemGrey;
    }
  }
}
