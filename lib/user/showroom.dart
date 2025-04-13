import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/user/book_car.dart'; // Only import from one location
import 'package:flutter_app/user/user_profile.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

import '../available_cars.dart';
import '../screen/history.dart';
import '../screen/screen_main.dart';

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
    {'name': 'Honda', 'logo': 'assets/images/logo/HondaLogo.png'},
    {'name': 'Mazda', 'logo': 'assets/images/logo/MazdaLogo.png'},
    {'name': 'Mitsubishi', 'logo': 'assets/images/logo/MitsubishiLogo.png'},
    {'name': 'Suzuki', 'logo': 'assets/images/logo/SuzukiLogo.png'},
    {'name': 'Mitsuoka', 'logo': 'assets/images/logo/MitsuokaLogo.png'},
    {'name': 'Isuzu', 'logo': 'assets/images/logo/IsuzuLogo.png'},
    {'name': 'hino', 'logo': 'assets/images/logo/HinoLogo.png'},
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
                  Navigator.of(context, rootNavigator: true).push(
                    CupertinoPageRoute(
                      builder: (context) => CupertinoPageScaffold(
                        child: CarBookingScreen(
                          car: carData,
                          carId: car.id,
                          vendorId: carData['vendorId'],
                        ),
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
