import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // iOS Icons

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
      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      // Keeps labels visible
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.house), // iOS-style icon
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.car), // iOS-style icon
          label: 'Cars',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.person), // iOS-style icon
          label: 'Profile',
        ),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: Color(0xFF20232B),
      // iOS-style color
      unselectedItemColor: Colors.grey,
      // iOS-style inactive color
      onTap: onItemTapped,
    );
  }
}
