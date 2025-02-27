import 'package:flutter/material.dart';
import 'package:flutter_app/seller/add_cars.dart';

import 'package:flutter_app/seller/seller_home.dart';
import 'package:flutter_app/seller/seller_profile.dart';

class SellerBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const SellerBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.business),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: Colors.amber[800],
      onTap: (index) {
        // Call the passed-in function with the selected index
        onItemTapped(index);

        // Perform navigation based on the index
        switch (index) {
          case 0: // Home
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const SellerHome()));
            break;
          case 1: // Orders
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const AddCars()));
            break;
          case 2: // Profile
            Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (context) => const SellerProfileScreen()));
            break;
          default:
            break;
        }
      },
    );
  }
}
