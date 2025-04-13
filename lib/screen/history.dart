import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CarRentalHistoryScreen extends StatelessWidget {
  const CarRentalHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: const CupertinoNavigationBar(
        middle: Text("Rental History"),
      ),
      child: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Booking')
              .where('userId', isEqualTo: currentUserId)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CupertinoActivityIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  "No rental history found.",
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 16,
                  ),
                ),
              );
            }

            var bookings = snapshot.data!.docs;

            return CupertinoScrollbar(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  var booking = bookings[index];
                  var bookingData = booking.data() as Map<String, dynamic>;

                  Timestamp timestamp = bookingData['timestamp'];
                  String formattedDate =
                      DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toDate());

                  Timestamp? cancelledAt = bookingData['cancelledAt'];
                  String? cancelledDate = cancelledAt != null
                      ? DateFormat('yyyy-MM-dd HH:mm')
                          .format(cancelledAt.toDate())
                      : null;

                  return BookingCard(
                    bookingId: booking.id,
                    vendorName: bookingData['vendorName'] ?? 'Unknown Vendor',
                    amount: bookingData['amount']?.toString() ?? 'N/A',
                    modelName: bookingData['carDetails']?['Model Name'] ??
                        'Unknown Model',
                    location: bookingData['carDetails']?['Location'] ??
                        'Unknown Location',
                    frontImage: bookingData['carDetails']?['frontImage'],
                    bookingDateTime: formattedDate,
                    status: bookingData['Status'] ?? 'Unknown',
                    cancelledDate: cancelledDate,
                    pickupDate: bookingData['pickupDate'] ?? 'Unknown Date',
                    returnDate: bookingData['returnDate'] ?? 'Unknown Date',
                    pickupTime: bookingData['pickupTime'] ?? 'Unknown Time',
                    returnTime: bookingData['returnTime'] ?? 'Unknown Time',
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class BookingCard extends StatelessWidget {
  final String bookingId;
  final String vendorName;
  final String amount;
  final String modelName;
  final String location;
  final String? frontImage;
  final String bookingDateTime;
  final String status;
  final String? cancelledDate;
  final String pickupDate;
  final String returnDate;
  final String pickupTime;
  final String returnTime;

  const BookingCard({
    super.key,
    required this.bookingId,
    required this.vendorName,
    required this.amount,
    required this.modelName,
    required this.location,
    required this.bookingDateTime,
    required this.status,
    this.frontImage,
    this.cancelledDate,
    required this.pickupDate,
    required this.returnDate,
    required this.pickupTime,
    required this.returnTime,
  });

  @override
  Widget build(BuildContext context) {
    String formattedPickupDateTime = _formatDateTime(pickupDate, pickupTime);
    String formattedReturnDateTime = _formatDateTime(returnDate, returnTime);

    final isCancelled = status.toLowerCase() == 'cancelled';
    final cardColor =
        isCancelled ? CupertinoColors.systemGrey5 : CupertinoColors.white;
    final textColor =
        isCancelled ? CupertinoColors.systemGrey : CupertinoColors.black;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with image and basic info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Car image
                Container(
                  width: 100,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: frontImage != null
                        ? Colors.transparent
                        : CupertinoColors.systemGrey5,
                  ),
                  child: frontImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Opacity(
                            opacity: isCancelled ? 0.6 : 1.0,
                            child: Image.network(
                              frontImage!,
                              width: 100,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(CupertinoIcons.photo,
                                      size: 40,
                                      color: CupertinoColors.systemGrey),
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(CupertinoIcons.photo,
                              size: 40, color: CupertinoColors.systemGrey),
                        ),
                ),
                const SizedBox(width: 12),
                // Car details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        modelName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vendorName,
                        style: TextStyle(
                          fontSize: 14,
                          color: isCancelled
                              ? CupertinoColors.systemGrey2
                              : CupertinoColors.systemGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "₹$amount/day",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          const Divider(height: 1, thickness: 0.5),

          // Location and rating
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(CupertinoIcons.location_solid,
                    size: 16,
                    color: isCancelled
                        ? CupertinoColors.systemGrey2
                        : CupertinoColors.systemGrey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Dates section with time
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDateTimeInfo(
                    "Pickup", formattedPickupDateTime, isCancelled),
                _buildDateTimeInfo(
                    "Return", formattedReturnDateTime, isCancelled),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Status section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCancelled
                        ? CupertinoColors.systemGrey4
                        : CupertinoColors.systemGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCancelled
                          ? CupertinoColors.systemGrey
                          : CupertinoColors.systemGreen,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (status.toLowerCase() == 'cancelled' &&
                    cancelledDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "Cancelled on: $cancelledDate",
                      style: TextStyle(
                        color: CupertinoColors.systemRed,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Cancel button (if applicable)
          if (status.toLowerCase() != 'cancelled') ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: CupertinoColors.systemRed,
                  borderRadius: BorderRadius.circular(8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: const Text("Cancel Booking"),
                  onPressed: () {
                    // Implement cancel booking logic here
                  },
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDateTimeInfo(String label, String dateTime, bool isCancelled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isCancelled
                ? CupertinoColors.systemGrey2
                : CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          dateTime,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isCancelled
                ? CupertinoColors.systemGrey
                : CupertinoColors.black,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(String date, String time) {
    try {
      // Combine date and time strings
      String dateTimeString = "$date $time";

      // Parse the combined string
      DateTime parsedDateTime = DateTime.parse(dateTimeString);

      // Format as "MMM dd, yyyy hh:mm a" (e.g., "Dec 25, 2023 02:30 PM")
      return DateFormat('MMM dd, yyyy hh:mm a').format(parsedDateTime);
    } catch (e) {
      return "$date $time"; // Return original if parsing fails
    }
  }
}
