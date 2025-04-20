import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ViewBooking extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy hh:mm a');

  ViewBooking({Key? key}) : super(key: key);

  DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    if (date is Timestamp) return date.toDate();
    if (date is String) return DateTime.tryParse(date);
    return null;
  }

  Future<void> _toggleBookingStatus(BuildContext context, String bookingId,
      bool currentStatus, String carId, String vendorId) async {
    try {
      // Update booking status
      await _firestore.collection('Booking').doc(bookingId).update({
        'status': currentStatus ? 'inactive' : 'active',
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Update car availability in vendor's subcollection
      await _firestore
          .collection('vendors')
          .doc(vendorId)
          .collection('CarDetails')
          .doc(carId)
          .update({
        'Status': currentStatus ? 'unavailable' : 'available',
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Booking marked as ${currentStatus ? 'inactive' : 'active'} and car availability updated'),
          backgroundColor: currentStatus ? Colors.orange : Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildBookingCard(
    BuildContext context,
    Map<String, dynamic> bookingData,
    Map<String, dynamic> carDetails,
    String userId,
    String displayName,
    DateTime? pickupDate,
    DateTime? returnDate,
    DateTime? bookingTimestamp,
    String bookingId,
    String vendorId,
  ) {
    final bool isActive = bookingData['status'] == 'active';
    final bool isCompleted = bookingData['status'] == 'completed';
    final String carId = carDetails['carId'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      // Added margin to prevent edge overflow
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (carDetails['frontImage'] != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                carDetails['frontImage'],
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 180,
                    color: Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 180,
                    color: Colors.grey[200],
                    child: const Center(
                      child:
                          Icon(Icons.car_rental, size: 50, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${carDetails['Car Brand'] ?? 'N/A'} ${carDetails['Model Name'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pickup Date',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pickupDate != null
                                ? _dateFormat.format(pickupDate)
                                : 'Not specified',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Return Date',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            returnDate != null
                                ? _dateFormat.format(returnDate)
                                : 'Not specified',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Booking Created',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bookingTimestamp != null
                                ? _dateFormat.format(bookingTimestamp)
                                : 'Not specified',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 0.5,
                  color: Colors.grey[200],
                  margin: const EdgeInsets.symmetric(vertical: 8),
                ),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_outline,
                        color: Colors.blue[400],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'User ID: ${userId.isNotEmpty ? userId : 'N/A'}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (bookingData['amount'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Booking Amount',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '₹${bookingData['amount']}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Status Button
                        if (!isCompleted)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isActive ? Colors.green : Colors.grey,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () => _toggleBookingStatus(context,
                                  bookingId, isActive, carId, vendorId),
                              child: Text(
                                isActive
                                    ? 'Active - Car Available'
                                    : 'Inactive - Car Unavailable ',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                'Completed',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentVendorId = _auth.currentUser?.uid;

    if (currentVendorId == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view bookings')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[50],
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('Booking')
            .where('vendorId', isEqualTo: currentVendorId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  if (snapshot.error.toString().contains('PERMISSION_DENIED'))
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text(
                        'Please check your Firestore security rules',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                ],
              ),
            );
          }

          final bookings = snapshot.data?.docs ?? [];
          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No bookings found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final bookingDoc = bookings[index];
              final bookingData = bookingDoc.data() as Map<String, dynamic>;
              final carDetails =
                  bookingData['carDetails'] as Map<String, dynamic>? ?? {};
              final userId = bookingData['userId'] as String? ?? '';

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(userId).get(),
                builder: (context, userSnapshot) {
                  String displayName = 'Unknown User';
                  if (userSnapshot.hasData && userSnapshot.data != null) {
                    final userData =
                        userSnapshot.data!.data() as Map<String, dynamic>?;
                    displayName = userData?['displayName'] ?? 'Unknown User';
                  }

                  final pickupDate = _parseDate(bookingData['pickupDate']);
                  final returnDate = _parseDate(bookingData['returnDate']);
                  final bookingTimestamp = _parseDate(bookingData['timestamp']);

                  return _buildBookingCard(
                    context,
                    bookingData,
                    carDetails,
                    userId,
                    displayName,
                    pickupDate,
                    returnDate,
                    bookingTimestamp,
                    bookingDoc.id,
                    currentVendorId,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
