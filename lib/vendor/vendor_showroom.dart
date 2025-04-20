import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SellerShowroom extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  SellerShowroom({super.key});

  @override
  Widget build(BuildContext context) {
    final currentVendorId = _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              _buildTopBar(),
              const SizedBox(height: 20),
              StreamBuilder<DocumentSnapshot>(
                stream: _firestore
                    .collection('vendors')
                    .doc(currentVendorId)
                    .snapshots(),
                builder: (context, vendorSnapshot) {
                  if (!vendorSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final vendorData =
                      vendorSnapshot.data!.data() as Map<String, dynamic>?;
                  final profileImageUrl =
                      vendorData?['profileImage'] as String? ?? '';

                  return StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('Booking')
                        .where('vendorId', isEqualTo: currentVendorId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      double totalEarnings = 0;
                      final bookings = snapshot.data!.docs;
                      for (var booking in bookings) {
                        final bookingData =
                            booking.data() as Map<String, dynamic>;
                        final amount = bookingData['amount'] as num? ?? 0;
                        totalEarnings += amount.toDouble();
                      }

                      return Column(
                        children: [
                          _buildMainCard(
                            totalEarnings: totalEarnings,
                            profileImageUrl: profileImageUrl,
                          ),
                          const SizedBox(height: 20),
                          _buildModerationSection(),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildReviewsSection(),
              const SizedBox(height: 20),
              _buildSocialLinks(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.white),
                const SizedBox(width: 10),
                const Text("Home",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(width: 20),
                const Text("About",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(width: 20),
                const Text("Contacts",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainCard({
    required double totalEarnings,
    required String profileImageUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Supplier center",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          const Text("With artificial intelligence technology"),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: profileImageUrl.isNotEmpty
                ? Image.network(
                    profileImageUrl,
                    fit: BoxFit.cover,
                    height: 150,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 150,
                      color: Colors.grey,
                      child: const Icon(Icons.person, size: 50),
                    ),
                  )
                : Container(
                    height: 150,
                    color: Colors.grey,
                    child: const Icon(Icons.person, size: 50),
                  ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.green),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Total Earnings",
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      "₹${totalEarnings.toStringAsFixed(2)}",
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
          ),
        ],
      ),
    );
  }

  Widget _buildModerationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield, color: Colors.white),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Manual moderation\nDon't worry about security, moderators check every transaction. Everything is transparent",
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.star, color: Colors.white),
              SizedBox(width: 10),
              Text("Reviews", style: TextStyle(color: Colors.white)),
            ],
          ),
          const Text("4.8/5",
              style: TextStyle(color: Colors.white, fontSize: 20)),
        ],
      ),
    );
  }

  Widget _buildSocialLinks() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const Text("INSTAGRAM", style: TextStyle(color: Colors.white)),
          const SizedBox(width: 10),
          const Text("//", style: TextStyle(color: Colors.white)),
          const SizedBox(width: 10),
          const Text("FACEBOOK", style: TextStyle(color: Colors.white)),
          const SizedBox(width: 10),
          const Text("//", style: TextStyle(color: Colors.white)),
          const SizedBox(width: 10),
          const Text("TWITTER", style: TextStyle(color: Colors.white)),
          const SizedBox(width: 10),
          const Text("//", style: TextStyle(color: Colors.white)),
          const SizedBox(width: 10),
          const Text("TELEGRAM", style: TextStyle(color: Colors.white)),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text("Go to suppliers"),
          )
        ],
      ),
    );
  }
}
