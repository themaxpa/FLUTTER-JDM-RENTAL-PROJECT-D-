import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class SellerShowroom extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String vendorId;

  SellerShowroom({super.key, required this.vendorId});

  Future<void> _launchUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch $url: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Vendor Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('vendors').doc(vendorId).snapshots(),
        builder: (context, vendorSnapshot) {
          if (vendorSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!vendorSnapshot.hasData || !vendorSnapshot.data!.exists) {
            return const Center(child: Text('Vendor not found'));
          }

          final vendorData =
              vendorSnapshot.data!.data() as Map<String, dynamic>;
          final name = vendorData['name'] ?? 'No Name';
          final email = vendorData['email'] ?? 'No Email';
          final phone = vendorData['phone'] ?? 'No Phone';
          final company = vendorData['company'] ?? 'No company information';
          final profileImageUrl = vendorData['profileImage'] ?? '';
          final instagramUrl = vendorData['instagram'] ?? '';
          final facebookUrl = vendorData['facebook'] ?? '';
          final twitterUrl = vendorData['twitter'] ?? '';
          final telegramUrl = vendorData['telegram'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildProfileCard(
                  profileImageUrl: profileImageUrl,
                  name: name,
                  company: company,
                ),
                const SizedBox(height: 20),
                _buildContactSection(email, phone),
                const SizedBox(height: 20),
                if (instagramUrl.isNotEmpty ||
                    facebookUrl.isNotEmpty ||
                    twitterUrl.isNotEmpty ||
                    telegramUrl.isNotEmpty)
                  _buildSocialMediaSection(
                    instagramUrl: instagramUrl,
                    facebookUrl: facebookUrl,
                    twitterUrl: twitterUrl,
                    telegramUrl: telegramUrl,
                  ),
                const SizedBox(height: 20),
                _buildReviewsSection(),
                const SizedBox(height: 20),
                _buildAvailableCarsSection(),
                const SizedBox(height: 20),
                _buildCarDetailsSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard({
    required String profileImageUrl,
    required String name,
    required String company,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: profileImageUrl.isNotEmpty
                  ? NetworkImage(profileImageUrl)
                  : null,
              child: profileImageUrl.isEmpty
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              company,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(String email, String phone) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: Text(email),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: Text(phone),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialMediaSection({
    required String instagramUrl,
    required String facebookUrl,
    required String twitterUrl,
    required String telegramUrl,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connect With Us',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (instagramUrl.isNotEmpty)
                    _buildSocialButton(
                      label: 'Instagram',
                      onTap: () => _launchUrl(_ensureHttps(instagramUrl)),
                      margin: const EdgeInsets.only(right: 8),
                    ),
                  if (facebookUrl.isNotEmpty)
                    _buildSocialButton(
                      label: 'Facebook',
                      onTap: () => _launchUrl(_ensureHttps(facebookUrl)),
                      margin: const EdgeInsets.only(right: 8),
                    ),
                  if (twitterUrl.isNotEmpty)
                    _buildSocialButton(
                      label: 'Twitter',
                      onTap: () => _launchUrl(_ensureHttps(twitterUrl)),
                      margin: const EdgeInsets.only(right: 8),
                    ),
                  if (telegramUrl.isNotEmpty)
                    _buildSocialButton(
                      label: 'Telegram',
                      onTap: () => _launchUrl(_ensureHttps(telegramUrl)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required VoidCallback onTap,
    EdgeInsets margin = EdgeInsets.zero,
  }) {
    return Container(
      margin: margin,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
      ),
    );
  }

  String _ensureHttps(String url) {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'https://$url';
    }
    return url;
  }

  Widget _buildReviewsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Customer Reviews',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Chip(
              backgroundColor: Colors.amber[100],
              label: const Text('4.8/5'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableCarsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Vehicles',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 0,
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('CarDetails')
                .where('vendorId', isEqualTo: vendorId)
                .where('Status', isEqualTo: 'available')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              //   return const Center(
              //     child: Text('No vehicles available'),
              //   );
              // }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final car = snapshot.data!.docs[index];
                  final carData = car.data() as Map<String, dynamic>;

                  return Container(
                    width: 180,
                    margin: const EdgeInsets.only(right: 12),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                              child: carData['frontImage'] != null
                                  ? Image.network(
                                      carData['frontImage'],
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _buildCarPlaceholder(),
                                    )
                                  : _buildCarPlaceholder(),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${carData['Car Brand'] ?? ''} ${carData['Model Name'] ?? ''}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${carData['1DayPrice'] ?? '0'}/day',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCarDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('vendors')
              .doc(vendorId)
              .collection('CarDetails')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text('No car listings available'),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final carDoc = snapshot.data!.docs[index];
                final carData = carDoc.data() as Map<String, dynamic>;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: carData['frontImage'] != null
                              ? Image.network(
                                  carData['frontImage'],
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildCarPlaceholder(),
                                )
                              : _buildCarPlaceholder(),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${carData['Car Brand'] ?? 'Unknown Brand'}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  carData['Model Name'] ?? 'Unknown Model',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Daily Rate',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  '₹${carData['1DayPrice'] ?? '0'}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCarPlaceholder() {
    return Container(
      height: 180,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.car_repair, size: 50, color: Colors.grey),
      ),
    );
  }
}
