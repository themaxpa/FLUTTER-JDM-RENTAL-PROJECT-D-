import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppSettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text('Settings'),
        backgroundColor: CupertinoColors.systemBackground,
      ),
      child: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 20),
            _buildSettingTile(
              icon: CupertinoIcons.person,
              title: 'Account',
              onTap: () => Get.toNamed('/account'),
            ),
            _buildSettingTile(
              icon: CupertinoIcons.bell,
              title: 'Notifications',
              onTap: () => Get.toNamed('/notifications'),
            ),
            _buildSettingTile(
              icon: CupertinoIcons.paintbrush,
              title: 'Appearance',
              onTap: () => Get.toNamed('/appearance'),
            ),
            _buildSettingTile(
              icon: CupertinoIcons.lock,
              title: 'Privacy & Security',
              onTap: () => Get.toNamed('/privacy'),
            ),
            _buildSettingTile(
              icon: CupertinoIcons.info,
              title: 'About',
              onTap: () => Get.toNamed('/about'),
            ),
            _buildSettingTile(
              icon: CupertinoIcons.square_arrow_right,
              title: 'Logout',
              onTap: () => Get.defaultDialog(
                title: 'Log Out',
                middleText: 'Are you sure you want to log out?',
                textConfirm: 'Yes',
                textCancel: 'No',
                confirmTextColor: Colors.white,
                onConfirm: () {
                  // AuthController logout
                  Get.back(); // close dialog
                  Get.offAllNamed('/login'); // go to login
                },
              ),
              trailing: Icon(CupertinoIcons.arrow_right),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return CupertinoListTile(
      leading: Icon(icon, color: CupertinoColors.systemBlue),
      title: Text(title),
      trailing: trailing ?? Icon(CupertinoIcons.right_chevron),
      onTap: onTap,
    );
  }
}
