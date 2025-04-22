import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textStyle = _buildTextStyle(context);
    final headerStyle = _buildHeaderStyle(context);
    final titleStyle = _buildTitleStyle(context);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Privacy Policy'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Material(
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Privacy Policy', style: titleStyle),
                const SizedBox(height: 16),
                Text(
                  'Your privacy is important to us. This privacy policy explains how we collect, use, and protect your information.',
                  style: textStyle,
                ),
                const SizedBox(height: 16),
                _buildSection(
                    'Information Collection',
                    'We collect information you provide directly to us when you use our services, such as when you create an account, make a booking, or contact customer support.',
                    headerStyle,
                    textStyle),
                _buildSection(
                    'Information Usage',
                    'We use the information to provide, improve, and personalize our services, process transactions, and communicate with you.',
                    headerStyle,
                    textStyle),
                _buildSection(
                    'Information Sharing',
                    'We do not share your personal information with third parties except as necessary to provide our services or as required by law.',
                    headerStyle,
                    textStyle),
                _buildSection(
                    'Data Security',
                    'We implement security measures to protect your personal information from unauthorized access and disclosure.',
                    headerStyle,
                    textStyle),
                _buildSection(
                    'Changes to This Policy',
                    'We may update this privacy policy from time to time. We encourage you to review this policy periodically.',
                    headerStyle,
                    textStyle),
                _buildSection(
                    'Contact Us',
                    'If you have any questions about this privacy policy, please contact us.',
                    headerStyle,
                    textStyle),
                const SizedBox(height: 24),
                Center(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) =>
                              const TermsAndConditionsScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'View Terms and Conditions',
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 18,
                        color: CupertinoColors.systemBlue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String header, String content, TextStyle headerStyle,
      TextStyle contentStyle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(header, style: headerStyle),
          const SizedBox(height: 4),
          Text(content, style: contentStyle),
        ],
      ),
    );
  }

  TextStyle _buildTextStyle(BuildContext context) => TextStyle(
        fontFamily: 'SF Pro Display',
        fontSize: 16,
        color: CupertinoColors.label.resolveFrom(context),
        height: 1.5,
      );

  TextStyle _buildHeaderStyle(BuildContext context) => TextStyle(
        fontFamily: 'SF Pro Display',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: CupertinoColors.label.resolveFrom(context),
      );

  TextStyle _buildTitleStyle(BuildContext context) => TextStyle(
        fontFamily: 'SF Pro Display',
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: CupertinoColors.label.resolveFrom(context),
      );
}

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({Key? key}) : super(key: key);

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = _textStyle(context);
    final headingStyle = _headingStyle(context);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Terms & Conditions'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Material(
              color: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Effective Date: 01/01/2025', style: textStyle),
                  Text('Last Updated: 22/04/2025', style: textStyle),
                  const SizedBox(height: 16),
                  _paragraph(
                      'Welcome to Project D. These Terms and Conditions ("Terms") govern your use of our mobile application and services. By accessing or using Project D, you agree to be bound by these Terms.',
                      textStyle),
                  _heading('1. Acceptance of Terms', headingStyle),
                  _paragraph(
                      'By creating an account or using the app, you confirm that you are at least 18 years old and agree to comply with these Terms and our Privacy Policy.',
                      textStyle),
                  _heading('2. User Accounts', headingStyle),
                  _subHeading('a. Registration:', headingStyle),
                  _paragraph(
                      'Users must register using a valid email and phone number. Vendors must provide additional verification, including valid ID and vehicle documents.',
                      textStyle),
                  _subHeading('b. Responsibility:', headingStyle),
                  _paragraph(
                      'You are responsible for maintaining the confidentiality of your account credentials. Any activity under your account is your responsibility.',
                      textStyle),
                  _heading('3. Services Offered', headingStyle),
                  _bulletList([
                    'Vendors to list JDM vehicles for rent',
                    'Users to browse and rent available vehicles',
                    'Admins to monitor and manage the platform',
                  ], textStyle),
                  _heading('4. Booking and Payment', headingStyle),
                  _bulletList([
                    'Bookings are subject to availability and vendor approval.',
                    'All payments must be made via secure payment gateways integrated into the app.',
                    'Cancellations and refunds are subject to the vendor\'s individual policies.',
                  ], textStyle),
                  _heading('5. User Obligations', headingStyle),
                  _bulletList([
                    'Use the app for unlawful or fraudulent purposes',
                    'Post false or misleading information',
                    'Damage, disable, or impair the app\'s functionality',
                    'Violate any applicable laws or third-party rights',
                  ], textStyle),
                  _heading('6. Vendor Responsibilities', headingStyle),
                  _bulletList([
                    'Ensuring vehicle accuracy and condition',
                    'Complying with local vehicle rental regulations',
                    'Honoring confirmed bookings',
                  ], textStyle),
                  _heading('7. Intellectual Property', headingStyle),
                  _paragraph(
                      'All content in the app, including logos, trademarks, and code, is the property of Project D or its licensors. Unauthorized use is strictly prohibited.',
                      textStyle),
                  _heading('8. Termination', headingStyle),
                  _paragraph(
                      'We reserve the right to suspend or terminate accounts that violate these Terms or engage in suspicious or fraudulent activity.',
                      textStyle),
                  _heading('9. Limitation of Liability', headingStyle),
                  _bulletList([
                    'Any damages or losses resulting from rental transactions',
                    'Vendor misconduct or vehicle issues',
                    'App downtime or data loss',
                    'Use of the platform is at your own risk.',
                  ], textStyle),
                  _heading('10. Changes to Terms', headingStyle),
                  _paragraph(
                      'We reserve the right to update these Terms at any time. Users will be notified of significant changes via email or in-app notifications.',
                      textStyle),
                  _heading('11. Governing Law', headingStyle),
                  _paragraph(
                      'These Terms are governed by and construed in accordance with the laws of [Insert Jurisdiction]. Any disputes shall be resolved in the courts of [Insert Location].',
                      textStyle),
                  _heading('12. Contact Us', headingStyle),
                  _paragraph(
                      'For questions or concerns regarding these Terms, please contact:',
                      textStyle),
                  _paragraph('Email: themaxpa69@gmail.com', textStyle),
                  _paragraph('Phone: 7907149184', textStyle),
                  GestureDetector(
                    onTap: () => _launchUrl('themaxpa.com'),
                    child: Text(
                      'Website: themaxpa.com',
                      style: textStyle.copyWith(
                        color: CupertinoColors.systemBlue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _paragraph(String text, TextStyle style) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text, style: style),
      );

  Widget _heading(String text, TextStyle style) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Text(text, style: style),
      );

  Widget _subHeading(String text, TextStyle style) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(text, style: style),
      );

  Widget _bulletList(List<String> items, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) => Text('• $item', style: style)).toList(),
      ),
    );
  }

  TextStyle _textStyle(BuildContext context) => TextStyle(
        fontFamily: 'SF Pro Display',
        fontSize: 16,
        color: CupertinoColors.label.resolveFrom(context),
        height: 1.5,
      );

  TextStyle _headingStyle(BuildContext context) => TextStyle(
        fontFamily: 'SF Pro Display',
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: CupertinoColors.label.resolveFrom(context),
        height: 1.5,
      );
}
