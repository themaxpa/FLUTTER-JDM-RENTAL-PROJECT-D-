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
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
    try {
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
    } catch (e) {
      print('Error in exit dialog: $e');
      return false;
    }
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
      throw Exception('Failed to load car count');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentVendorId = _auth.currentUser?.uid;
    if (currentVendorId == null) {
      return _buildErrorWidget('User not authenticated');
    }

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
                if (vendorSnapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingIndicator();
                }

                if (vendorSnapshot.hasError) {
                  return _buildErrorWidget(
                      'Failed to load vendor data: ${vendorSnapshot.error}');
                }

                if (!vendorSnapshot.hasData || !vendorSnapshot.data!.exists) {
                  return _buildErrorWidget('Vendor profile not found');
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('Booking')
                      .where('carDetails.vendorId', isEqualTo: currentVendorId)
                      .snapshots(),
                  builder: (context, bookingSnapshot) {
                    if (bookingSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return _buildLoadingIndicator();
                    }

                    if (bookingSnapshot.hasError) {
                      return _buildErrorWidget(
                          'Failed to load bookings: ${bookingSnapshot.error}');
                    }

                    // Calculate total earnings from bookings
                    double totalEarnings = 0;
                    int totalBookingsCount = 0;

                    if (bookingSnapshot.hasData) {
                      totalBookingsCount = bookingSnapshot.data!.docs.length;
                      for (var doc in bookingSnapshot.data!.docs) {
                        try {
                          final booking = doc.data() as Map<String, dynamic>;
                          final amount = booking['amount'] as num? ?? 0;
                          totalEarnings += amount.toDouble();
                        } catch (e) {
                          print('Error processing booking: $e');
                        }
                      }
                    }

                    final vendorData =
                        vendorSnapshot.data!.data() as Map<String, dynamic>? ??
                            {};
                    final totalCars = vendorData['totalCars'] ?? 0;

                    return FutureBuilder<int>(
                      future: _getCarCount(currentVendorId),
                      builder: (context, carCountSnapshot) {
                        if (carCountSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _buildLoadingIndicator();
                        }

                        if (carCountSnapshot.hasError) {
                          return _buildErrorWidget(
                              'Failed to load car count: ${carCountSnapshot.error}');
                        }

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
                                      icon: CupertinoIcons.ticket,
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
            const SizedBox(height: 24),
            _buildSectionTitle('Quick Actions'),
            const SizedBox(height: 16),
            _buildQuickActions(context),
            const SizedBox(height: 24),
            _buildSectionTitle('Recent Bookings'),
            const SizedBox(height: 16),
            _buildRecentBookings(currentVendorId),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: const Center(child: CupertinoActivityIndicator()),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(CupertinoIcons.exclamationmark_triangle,
              color: CupertinoColors.systemRed, size: 40),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: CupertinoColors.systemRed),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Material(
      color: Colors.transparent,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: CupertinoColors.label,
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
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: CupertinoColors.secondaryLabel,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    try {
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
            icon: CupertinoIcons.building_2_fill,
            label: 'Company Details',
            color: CupertinoColors.systemBlue,
            onTap: () => Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => SellerShowroom(
                  vendorId: _auth.currentUser?.uid ?? '',
                ),
              ),
            ),
          ),
          _buildActionButton(
            context,
            icon: CupertinoIcons.tickets,
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
            onTap: () {
              try {
                // Handle settings navigation
              } catch (e) {
                _showErrorSnackbar(context, 'Failed to open settings: $e');
              }
            },
          ),
        ],
      );
    } catch (e) {
      return _buildErrorWidget('Failed to load quick actions: $e');
    }
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
    try {
      return StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('Booking')
            .where('carDetails.vendorId', isEqualTo: vendorId)
            .orderBy('timestamp', descending: true)
            .limit(5)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingContainer();
          }

          if (snapshot.hasError) {
            return _buildErrorContainer(
                'Error loading bookings: ${snapshot.error}');
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyContainer('No recent bookings');
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
                try {
                  final doc = bookings[index];
                  final booking = doc.data() as Map<String, dynamic>;
                  final carDetails =
                      booking['carDetails'] as Map<String, dynamic>? ?? {};
                  final imageUrl = carDetails['frontImage'] as String?;

                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        _buildCarImage(imageUrl),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${carDetails['Car Brand'] ?? 'Unknown'} ${carDetails['Model Name'] ?? 'Car'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatBookingDate(booking['timestamp']),
                                  style: TextStyle(
                                    color: CupertinoColors.secondaryLabel,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        _buildBookingAmountAndStatus(booking),
                      ],
                    ),
                  );
                } catch (e) {
                  print('Error rendering booking item: $e');
                  return _buildErrorBookingItem();
                }
              },
            ),
          );
        },
      );
    } catch (e) {
      return _buildErrorContainer('Failed to load bookings: $e');
    }
  }

  Widget _buildCarImage(String? imageUrl) {
    return Container(
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
                loadingBuilder: (BuildContext context, Widget child,
                    ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (BuildContext context, Object error,
                    StackTrace? stackTrace) {
                  return _buildDefaultCarIcon();
                },
              )
            : _buildDefaultCarIcon(),
      ),
    );
  }

  Widget _buildDefaultCarIcon() {
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
  }

  String _formatBookingDate(dynamic timestamp) {
    try {
      if (timestamp is Timestamp) {
        return DateFormat('MMM dd, yyyy').format(timestamp.toDate());
      }
      return 'Date not available';
    } catch (e) {
      print('Error formatting date: $e');
      return 'Invalid date';
    }
  }

  Widget _buildBookingAmountAndStatus(Map<String, dynamic> booking) {
    try {
      return Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _currencyFormat.format(booking['amount'] ?? 0),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: CupertinoColors.activeGreen,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(booking['Status']).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                booking['Status']?.toString().toUpperCase() ?? 'PENDING',
                style: TextStyle(
                  color: _getStatusColor(booking['Status']),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error building booking amount/status: $e');
      return const SizedBox();
    }
  }

  Widget _buildErrorBookingItem() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(CupertinoIcons.exclamationmark_triangle,
              color: CupertinoColors.systemRed),
          SizedBox(width: 8),
          Text('Error loading booking',
              style: TextStyle(color: CupertinoColors.systemRed)),
        ],
      ),
    );
  }

  Widget _buildLoadingContainer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: CupertinoActivityIndicator()),
    );
  }

  Widget _buildErrorContainer(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(CupertinoIcons.exclamationmark_triangle,
              color: CupertinoColors.systemRed),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: CupertinoColors.systemRed),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContainer(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: Text(
          message,
          style: const TextStyle(color: CupertinoColors.secondaryLabel),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    try {
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
    } catch (e) {
      return CupertinoColors.systemGrey;
    }
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: CupertinoColors.destructiveRed,
      ),
    );
  }
}
