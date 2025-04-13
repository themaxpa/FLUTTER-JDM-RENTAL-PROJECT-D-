import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/user/user_profile.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../available_cars.dart';
import '../screen/history.dart';
import '../screen/screen_main.dart';
import '../screen/payment_screen.dart';
import 'my_documents.dart';

class Showroom extends StatefulWidget {
  const Showroom({super.key});

  @override
  _ShowroomState createState() => _ShowroomState();
}

class _ShowroomState extends State<Showroom> {
  PersistentTabController _controller =
      PersistentTabController(initialIndex: 0);
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String selectedBrand = '';

  final List<Map<String, String>> carBrands = [
    {'name': 'Toyota', 'logo': 'assets/images/logo/ToyotaLogo.png'},
    {'name': 'Nissan', 'logo': 'assets/images/logo/NissanLogo.png'},
    {'name': 'Subaru', 'logo': 'assets/images/logo/SubaruLogo.png'},
    {'name': 'Bugatti', 'logo': 'assets/brands/bugatti.png'},
    {'name': 'Cadillac', 'logo': 'assets/brands/cadillac.png'},
    {'name': 'Ferrari', 'logo': 'assets/brands/ferrari.png'},
    {'name': 'Lamborghini', 'logo': 'assets/brands/lamborghini.png'},
    {'name': 'Mercedes', 'logo': 'assets/brands/mercedes.png'},
    {'name': 'Porsche', 'logo': 'assets/brands/porsche.png'},
    {'name': 'Rolls Royce', 'logo': 'assets/brands/rolls-royce.png'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  List<Widget> _buildScreens() {
    return [
      _buildShowroomContent(),
      ScreenMain(),
      CarRentalHistoryScreen(),
      ProfileScreen()
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(CupertinoIcons.home),
        activeColorPrimary: CupertinoColors.activeBlue,
        inactiveColorPrimary: CupertinoColors.inactiveGray,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(CupertinoIcons.chat_bubble_2),
        activeColorPrimary: CupertinoColors.activeBlue,
        inactiveColorPrimary: CupertinoColors.inactiveGray,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(CupertinoIcons.bell),
        activeColorPrimary: CupertinoColors.activeBlue,
        inactiveColorPrimary: CupertinoColors.inactiveGray,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(CupertinoIcons.person),
        activeColorPrimary: CupertinoColors.activeBlue,
        inactiveColorPrimary: CupertinoColors.inactiveGray,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      context,
      controller: _controller,
      screens: _buildScreens(),
      items: _navBarsItems(),
      navBarStyle: NavBarStyle.style6,
    );
  }

  Widget _buildBrandSelector() {
    return Container(
      height: 70,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: carBrands.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final brand = carBrands[index];
          final isSelected = selectedBrand == brand['name'];

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedBrand = isSelected ? '' : brand['name']!;
                searchQuery = selectedBrand.toLowerCase();
                _searchController.text = selectedBrand;
              });
            },
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? CupertinoColors.activeBlue
                      : CupertinoColors.systemGrey4,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.systemGrey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Image.asset(
                  brand['logo']!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShowroomContent() {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: CupertinoSearchTextField(
                  controller: _searchController,
                  placeholder: 'Search by Model or Brand',
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                      if (value.isEmpty) {
                        selectedBrand = '';
                      }
                    });
                  },
                  onSuffixTap: () {
                    _searchController.clear();
                    setState(() {
                      searchQuery = '';
                      selectedBrand = '';
                    });
                  },
                ),
              ),
              _buildBrandSelector(),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Top Deals",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ),
              buildCarDetails(),
              const SizedBox(height: 16),
              _buildAvailableCarsButton(),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey5,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Vendor Card Placeholder',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableCarsButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => const AvailableCars(),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
          height: 100,
          decoration: BoxDecoration(
            color: CupertinoColors.systemBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Available Cars',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Long term and short term',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.right_chevron,
                  color: CupertinoColors.systemBlue,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCarDetails() {
    return SizedBox(
      height: 250,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collectionGroup('CarDetails')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error loading cars"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No cars available"));
          }

          final carDocs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final modelName =
                data['Model Name']?.toString().toLowerCase() ?? '';
            final carBrand = data['Car Brand']?.toString().toLowerCase() ?? '';
            final status = data['Status']?.toString().toLowerCase() ?? '';

            if (status == 'pending') return false;

            return modelName.contains(searchQuery) ||
                carBrand.contains(searchQuery);
          }).toList();

          if (carDocs.isEmpty) {
            return const Center(child: Text("No matching cars found"));
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: carDocs.length,
            itemBuilder: (context, index) {
              final car = carDocs[index];
              final carData = car.data() as Map<String, dynamic>;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => CarBookingScreen(
                        car: carData,
                        carId: car.id,
                        vendorId: carData['vendorId'],
                      ),
                    ),
                  );
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                    width: 200,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(15)),
                          child: Image.network(
                            carData['frontImage'] ?? '',
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              height: 120,
                              color: CupertinoColors.systemGrey5,
                              child: const Center(
                                child: Icon(CupertinoIcons.photo, size: 40),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                carData['Model Name'] ?? 'No Model Name',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                carData['Car Brand'] ?? 'No Brand',
                                style: TextStyle(
                                  color: CupertinoColors.systemGrey,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'From ₹${carData['1MonthPrice'] ?? '0'}/month',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class CarBookingScreen extends StatefulWidget {
  final Map<String, dynamic> car;
  final String? carId;
  final String? vendorId;

  const CarBookingScreen({
    Key? key,
    required this.car,
    this.carId,
    this.vendorId,
  }) : super(key: key);

  @override
  State<CarBookingScreen> createState() => _CarBookingScreenState();
}

class _CarBookingScreenState extends State<CarBookingScreen> {
  DateTime? pickupDate;
  DateTime? returnDate;
  TimeOfDay? pickupTime;
  TimeOfDay? returnTime;
  String selectedPlan = '1 Day';
  num selectedPrice = 0;
  bool isDescriptionExpanded = false;
  int _currentImageIndex = 0;
  Timer? _timer;
  final List<String> _imageUrls = [];
  final MapController _mapController = MapController();
  LatLng? _carLocation;

  @override
  void initState() {
    super.initState();
    _initializeImages();
    _startImageTimer();
    _calculatePrice();
    _initializeCarLocation();
  }

  void _initializeImages() {
    if (widget.car['frontImage'] != null) {
      _imageUrls.add(widget.car['frontImage']);
    }
    if (widget.car['backImage'] != null) {
      _imageUrls.add(widget.car['backImage']);
    }
    if (widget.car['sideImage'] != null) {
      _imageUrls.add(widget.car['sideImage']);
    }
  }

  void _startImageTimer() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_imageUrls.isNotEmpty && mounted) {
        setState(() {
          _currentImageIndex = (_currentImageIndex + 1) % _imageUrls.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculatePrice() {
    setState(() {
      selectedPrice = selectedPlan == '1 Day'
          ? num.tryParse(widget.car['1DayPrice'].toString()) ?? 0
          : selectedPlan == '1 Month'
              ? num.tryParse(widget.car['1MonthPrice'].toString()) ?? 0
              : num.tryParse(widget.car['6MonthPrice'].toString()) ?? 0;
    });
  }

  void _calculateReturnDate() {
    if (pickupDate != null) {
      setState(() {
        returnDate = selectedPlan == '1 Day'
            ? pickupDate!.add(const Duration(days: 1))
            : selectedPlan == '1 Month'
                ? pickupDate!.add(const Duration(days: 30))
                : pickupDate!.add(const Duration(days: 180));
        returnTime = pickupTime;
      });
    }
  }

  void _initializeCarLocation() {
    if (widget.car['ELocation'] != null) {
      final geoPoint = widget.car['ELocation'] as GeoPoint;
      setState(() {
        _carLocation = LatLng(geoPoint.latitude, geoPoint.longitude);
      });
    }
  }

  void _showMoreInfo() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Background Image Carousel
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height * 0.45,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  child: Image.network(
                    _imageUrls.isNotEmpty ? _imageUrls[_currentImageIndex] : '',
                    key: ValueKey<int>(_currentImageIndex),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[900],
                      child: const Icon(
                        Icons.car_rental,
                        size: 100,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              CustomScrollView(
                slivers: [
                  // Top Section with Navigation and Image Indicators
                  SliverToBoxAdapter(
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.45,
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 16,
                        left: 16,
                        right: 16,
                      ),
                      child: Column(
                        children: [
                          // Navigation Bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Image Indicators
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: _imageUrls.asMap().entries.map((entry) {
                              return Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentImageIndex == entry.key
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.5),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Car Details Section
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.car['Car Brand'] ?? 'Brand',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              widget.car['Model Name'] ?? 'Model',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 16),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text:
                                        '₹${widget.car['1MonthPrice'] ?? '0'}',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' per month',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            _buildSpecificationItem(
                              'Maximum Power',
                              '${widget.car['power'] ?? '0'} hp',
                              Icons.speed,
                            ),
                            _buildSpecificationItem(
                              'Top Speed',
                              '${widget.car['maxSpeed'] ?? '0'} mph',
                              Icons.speed_outlined,
                            ),
                            _buildSpecificationItem(
                              'Consumption',
                              '${widget.car['consumption'] ?? '0'} L/100km',
                              Icons.local_gas_station,
                            ),
                            _buildSpecificationItem(
                              'Acceleration\n0-100 Km/H',
                              '${widget.car['Speed (0-100)'] ?? '0'} sec',
                              Icons.timer,
                            ),
                            _buildSpecificationItem(
                              'Body Type',
                              widget.car['carType'] ?? '-',
                              Icons.car_rental,
                            ),
                            _buildSpecificationItem(
                              'Gearbox',
                              widget.car['Gearbox'] ?? '-',
                              Icons.settings,
                            ),
                            _buildSpecificationItem(
                              'Seats',
                              '${widget.car['Seats'] ?? '0'} seats',
                              Icons.event_seat,
                            ),
                            _buildSpecificationItem(
                              'Drive Type',
                              widget.car['drive'] ?? '-',
                              Icons.drive_eta,
                            ),
                            _buildSpecificationItem(
                              'Motor',
                              widget.car['Motor'] ?? '-',
                              Icons.engineering,
                            ),
                            _buildSpecificationItem(
                              'Color',
                              widget.car['Color'] ?? '-',
                              Icons.palette,
                            ),
                            _buildSpecificationItem(
                              'Location',
                              widget.car['Location'] ?? '-',
                              Icons.location_on,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecificationItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.black,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _checkRequiredDocuments() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final documentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('MyDocuments')
          .get();

      // List of required documents
      final requiredDocuments = [
        'DLFrontSide',
        'DLBackSide',
        'PanCard',
        'AadhaarCardFront',
        'AadhaarCardBack'
      ];

      // Check if all required documents are uploaded and have values
      for (var docTitle in requiredDocuments) {
        // Find the document with the matching title
        final matchingDocs = documentsSnapshot.docs
            .where((doc) => doc.data()['title'] == docTitle)
            .toList();

        // If no matching document found or URL is empty, return false
        if (matchingDocs.isEmpty ||
            matchingDocs.first.data()['url'] == null ||
            matchingDocs.first.data()['url'].toString().isEmpty) {
          return false;
        }
      }

      return true;
    } catch (e) {
      print('Error checking documents: $e');
      return false;
    }
  }

  void _handleRentNow() async {
    if (pickupDate == null || pickupTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select pickup date and time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if all required documents are uploaded with values
    final allDocumentsUploaded = await _checkRequiredDocuments();
    if (!allDocumentsUploaded) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Documents Required'),
          content: const Text(
              'Please upload all required documents (Aadhaar Card, Driving License, PAN Card) before renting a car.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              child: const Text('Upload Documents'),
              onPressed: () {
                Navigator.pop(context);
                // Navigate to MyDocumentsScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyDocumentsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      );
      return;
    }

    // Ensure returnTime is set to pickupTime if it's null
    if (returnTime == null) {
      setState(() {
        returnTime = pickupTime;
      });
    }

    // If all documents are uploaded with values, proceed to payment screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          amount: selectedPrice,
          vendorName: widget.car['vendorName'] ?? 'Unknown Vendor',
          car: widget.car,
          pickupDate: pickupDate!,
          returnDate: returnDate!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white24,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          'Car Details',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.white24,
              child: IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.white),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image Section
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.car['frontImage'] ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[900],
                      child: const Icon(Icons.car_rental,
                          size: 100, color: Colors.white54),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                          Colors.black,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${widget.car['Car Brand']} ${widget.car['Model Name']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _showMoreInfo,
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white24,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              child: const Text(
                                'More Info',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.car['carType'] ?? 'Car Type',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDescription(
                      widget.car['description'] ?? 'No description available'),
                  const SizedBox(height: 24),

                  // Rental Plans
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Rental Plan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildPlanCard(
                                  '1 Day', widget.car['1DayPrice'].toString()),
                              _buildPlanCard('1 Month',
                                  widget.car['1MonthPrice'].toString()),
                              _buildPlanCard('6 Month',
                                  widget.car['6MonthPrice'].toString()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Booking Details
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Booking Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateField(
                                'Pickup Date',
                                pickupDate,
                                () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now()
                                        .add(const Duration(days: 365)),
                                  );
                                  if (date != null) {
                                    setState(() {
                                      pickupDate = date;
                                      _calculateReturnDate();
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTimeField(
                                'Pickup Time',
                                pickupTime,
                                () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  );
                                  if (time != null) {
                                    setState(() {
                                      pickupTime = time;
                                      returnTime = time;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateField(
                                'Return Date',
                                returnDate,
                                null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTimeField(
                                'Return Time',
                                returnTime,
                                null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Add Location Map Section
            const Text(
              'Car Location',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            _buildLocationMap(),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black,
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '₹$selectedPrice',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _handleRentNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.car_rental, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Rent Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(String title, String price) {
    final isSelected = selectedPlan == title;
    return Container(
      width: 150, // Fixed width for all cards
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedPlan = title;
            _calculatePrice();
            _calculateReturnDate();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.red : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '₹$price',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? value, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value != null
                  ? DateFormat('MMM dd, yyyy').format(value)
                  : 'Select Date',
              style: TextStyle(
                color: onTap != null ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeField(String label, TimeOfDay? value, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value != null ? value.format(context) : 'Select Time',
              style: TextStyle(
                color: onTap != null ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription(String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        AnimatedCrossFade(
          firstChild: Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
          secondChild: Text(
            description,
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
          crossFadeState: isDescriptionExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              isDescriptionExpanded = !isDescriptionExpanded;
            });
          },
          child: Text(
            isDescriptionExpanded ? 'Show Less' : 'Read More',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationMap() {
    if (_carLocation == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'Location data not available',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _openInGoogleMaps,
      child: Container(
        height: 200,
        margin: const EdgeInsets.only(top: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _carLocation!,
                  initialZoom: 15.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 40,
                        height: 40,
                        point: _carLocation!,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_carLocation!.latitude.toStringAsFixed(4)}, '
                    '${_carLocation!.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.open_in_new,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openInGoogleMaps() async {
    if (_carLocation == null) return;

    // Try to open in Google Maps app first
    final mapsAppUrl =
        'google.navigation:q=${_carLocation!.latitude},${_carLocation!.longitude}';
    final mapsAppUri = Uri.parse(mapsAppUrl);

    // If that fails, try to open in browser
    final browserUrl =
        'https://www.google.com/maps/search/?api=1&query=${_carLocation!.latitude},${_carLocation!.longitude}';
    final browserUri = Uri.parse(browserUrl);

    try {
      // First try to open in Google Maps app
      if (await canLaunchUrl(mapsAppUri)) {
        print('Opening in Google Maps app: $mapsAppUrl');
        final result = await launchUrl(
          mapsAppUri,
          mode: LaunchMode.externalApplication,
        );

        if (result) {
          print('Successfully opened in Google Maps app');
          return;
        }
      }

      // If app launch failed, try browser
      print('Trying to open in browser: $browserUrl');
      if (await canLaunchUrl(browserUri)) {
        final result = await launchUrl(
          browserUri,
          mode: LaunchMode.externalApplication,
        );

        if (result) {
          print('Successfully opened in browser');
          return;
        }
      }

      // If both failed, show error
      _showErrorSnackBar('Could not open Google Maps. Please try again.');
    } catch (e) {
      print('Exception when launching URL: $e');
      _showErrorSnackBar('Error: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
