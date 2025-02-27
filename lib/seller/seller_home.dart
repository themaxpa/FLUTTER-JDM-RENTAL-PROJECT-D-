import 'dart:ui'; // For Acrylic Blur
import 'package:flutter/material.dart';
import 'package:flutter_app/seller/seller_bottom_navigation.dart';
import 'package:flutter_app/seller/add_cars.dart';
import 'package:flutter_app/seller/seller_profile.dart';

class SellerHome extends StatefulWidget {
  const SellerHome({Key? key}) : super(key: key);

  @override
  _SellerHomeState createState() => _SellerHomeState();
}

class _SellerHomeState extends State<SellerHome> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<String> _titles = [
    "Home",
    "Add Cars",
    "Profile"
  ]; // Dynamic Titles

  final List<Widget> _pages = [
    Center(
        child: Text('Home',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold))),
    AddCars(),
    SellerProfileScreen(),
  ];

  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            // Acrylic Blur Effect
            child: AppBar(
              backgroundColor: Colors.white.withOpacity(0.7),
              // Semi-transparent
              elevation: 0,
              centerTitle: true,
              title: AnimatedSwitcher(
                duration: Duration(milliseconds: 300), // Smooth transition
                child: Text(
                  _titles[_selectedIndex], // Dynamic Title
                  key: ValueKey(_titles[_selectedIndex]),
                  // Ensures smooth animation
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: SellerBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
