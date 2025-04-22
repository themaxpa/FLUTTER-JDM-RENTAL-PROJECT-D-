import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class InformationPage extends StatelessWidget {
  const InformationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('About Project D'),
        backgroundColor: CupertinoColors.systemBackground,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildMissionSection(),
            const SizedBox(height: 24),
            _buildFeaturesSection(),
            const SizedBox(height: 24),
            _buildVisionSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          Image.asset(
            'assets/images/acura_2.png',
            height: 100,
            cacheWidth: 500, // Optimized image display
          ),
          const SizedBox(height: 12),
          const Material(
            color: Colors.transparent,
            child: Text(
              'Project D - JDM Car Rental',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          const Material(
            color: Colors.transparent,
            child: Text(
              'Powered by passion, designed for car enthusiasts.',
              style: TextStyle(
                fontSize: 16,
                color: CupertinoColors.systemGrey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionSection() {
    return _buildInfoSection(
      title: 'Our Mission',
      content:
          'Project D is dedicated to delivering an authentic Japanese Domestic Market (JDM) car rental experience. '
          'Whether you’re looking to cruise in a Nissan Skyline or drift in a Toyota Supra, our goal is to make iconic cars accessible to everyone.',
    );
  }

  Widget _buildFeaturesSection() {
    return _buildInfoSection(
      title: 'What We Offer',
      content: '• A curated fleet of legendary JDM cars\n'
          '• Flexible rental plans (daily, monthly, yearly)\n'
          '• Transparent pricing & secure online booking\n'
          '• 24/7 customer support\n'
          '• Pickup and return from multiple locations',
    );
  }

  Widget _buildVisionSection() {
    return _buildInfoSection(
      title: 'Our Vision',
      content:
          'To become the go-to platform for JDM lovers across the globe by blending technology, style, and automotive culture.',
    );
  }

  Widget _buildInfoSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              color: CupertinoColors.label,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
