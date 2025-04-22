import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Support'),
        backgroundColor: CupertinoColors.systemBackground,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 24),
            _buildContactSection(context),
            const SizedBox(height: 24),
            _buildFaqSection(context),
            const SizedBox(height: 24),
            _buildSocialMediaSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          Image.asset(
            'assets/images/ferrari_spider_488_2.png',
            height: 180,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          const Text(
            'How can we help you?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Our support team is available 24/7 to assist you with any questions or issues.',
            style: TextStyle(
              fontSize: 16,
              color: CupertinoColors.systemGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return CupertinoListSection.insetGrouped(
      header: const Text('Contact Options'),
      children: [
        CupertinoListTile(
          leading:
              Icon(CupertinoIcons.phone, color: CupertinoColors.activeBlue),
          title: const Text('Call Support'),
          subtitle: const Text('7907149184'),
          trailing: const CupertinoListTileChevron(),
          onTap: () => _launchUrl('tel:+7907149184'),
        ),
        CupertinoListTile(
          leading: Icon(CupertinoIcons.mail, color: CupertinoColors.activeBlue),
          title: const Text('Email Us'),
          subtitle: const Text('support@projectd.com'),
          trailing: const CupertinoListTileChevron(),
          onTap: () => _launchUrl('mailto:support@projectd.com'),
        ),
        CupertinoListTile(
          leading: Icon(CupertinoIcons.chat_bubble_text,
              color: CupertinoColors.activeBlue),
          title: const Text('Live Chat'),
          subtitle: const Text('Available 24/7'),
          trailing: const CupertinoListTileChevron(),
          onTap: () => _showLiveChatDialog(context),
        ),
      ],
    );
  }

  Widget _buildFaqSection(BuildContext context) {
    return CupertinoListSection.insetGrouped(
      header: const Text('FAQs'),
      children: [
        _buildFaqTile(
          context,
          'How do I cancel my reservation?',
          'You can cancel your reservation through the app up to 24 hours before your scheduled pickup time.',
        ),
        _buildFaqTile(
          context,
          'What payment methods do you accept?',
          'We accept all major credit cards, Apple Pay, Google Pay, and PayPal.',
        ),
        _buildFaqTile(
          context,
          'What is your late return policy?',
          'Late returns are subject to additional fees. Please contact us if you anticipate being late.',
        ),
        CupertinoListTile(
          title: const Text('View All FAQs'),
          trailing: const CupertinoListTileChevron(),
          onTap: () => _showAllFaqs(context),
        ),
      ],
    );
  }

  Widget _buildFaqTile(BuildContext context, String question, String answer) {
    return CupertinoListTile.notched(
      title: Text(question),
      onTap: () => _showFaqAnswer(context, question, answer),
    );
  }

  Widget _buildSocialMediaSection() {
    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Connect With Us',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSocialIcon(CupertinoIcons.arrow_up_right_square, 'Twitter',
                  () => _launchUrl('https://twitter.com/projectd')),
              _buildSocialIcon(CupertinoIcons.arrow_up_right_square, 'Facebook',
                  () => _launchUrl('https://facebook.com/projectd')),
              _buildSocialIcon(
                  CupertinoIcons.arrow_up_right_square,
                  'Instagram',
                  () => _launchUrl('https://instagram.com/themaxpa')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, String label, VoidCallback onTap) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, size: 28),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showLiveChatDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Live Chat'),
        content:
            const Text('Our chat support will open in a new window. Continue?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: const Text('Open Chat'),
            onPressed: () {
              Navigator.pop(context);
              _launchUrl('https://projectd.com/chat');
            },
          ),
        ],
      ),
    );
  }

  void _showFaqAnswer(BuildContext context, String question, String answer) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(question),
        message: Text(answer),
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Close'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _showAllFaqs(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('All FAQs'),
        content: const Text(
          'This would display all frequently asked questions in a scrollable view.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
