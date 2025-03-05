import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(25),
        topRight: Radius.circular(25),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.withOpacity(0.9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: CupertinoTabBar(
          backgroundColor: CupertinoColors.systemBackground.withOpacity(0.8),
          activeColor: CupertinoColors.activeBlue,
          inactiveColor: CupertinoColors.systemGrey,
          currentIndex: selectedIndex,
          onTap: onItemTapped,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.house),
              // label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.car_detailed),
              // label: 'Cars',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.bell),
              // label: 'Alerts',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.person),
              // label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
