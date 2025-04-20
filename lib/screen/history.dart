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
    final mediaQuery = MediaQuery.of(context);

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
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(mediaQuery.size.width * 0.05),
                  child: const Text(
                    "No rental history found.",
                    style: TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            }

            var bookings = snapshot.data!.docs;

            return CupertinoScrollbar(
              child: ListView.builder(
                padding: EdgeInsets.all(mediaQuery.size.width * 0.03),
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
                    mediaQuery: mediaQuery,
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
  final MediaQueryData mediaQuery;

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
    required this.mediaQuery,
  });

  @override
  Widget build(BuildContext context) {
    final isCancelled = status.toLowerCase() == 'cancelled';
    final cardColor =
        isCancelled ? CupertinoColors.systemGrey5 : CupertinoColors.white;
    final textColor =
        isCancelled ? CupertinoColors.systemGrey : CupertinoColors.black;

    // Calculate responsive sizes
    final imageSize = mediaQuery.size.width * 0.25;
    final cardPadding = mediaQuery.size.width * 0.04;
    final fontSizeTitle = mediaQuery.size.width * 0.045;
    final fontSizeSubtitle = mediaQuery.size.width * 0.035;

    return Container(
      margin: EdgeInsets.only(bottom: mediaQuery.size.height * 0.015),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with image and basic info
          Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Car image
                Container(
                  width: imageSize,
                  height: imageSize * 0.8,
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
                              width: imageSize,
                              height: imageSize * 0.8,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(CupertinoIcons.photo,
                                      size: imageSize * 0.4,
                                      color: CupertinoColors.systemGrey),
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(CupertinoIcons.photo,
                              size: imageSize * 0.4,
                              color: CupertinoColors.systemGrey),
                        ),
                ),
                SizedBox(width: mediaQuery.size.width * 0.03),
                // Car details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        modelName,
                        style: TextStyle(
                          fontSize: fontSizeTitle,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: mediaQuery.size.height * 0.005),
                      Text(
                        vendorName,
                        style: TextStyle(
                          fontSize: fontSizeSubtitle,
                          color: isCancelled
                              ? CupertinoColors.systemGrey2
                              : CupertinoColors.systemGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: mediaQuery.size.height * 0.01),
                      Text(
                        "₹$amount/day",
                        style: TextStyle(
                          fontSize: fontSizeTitle,
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
            padding: EdgeInsets.symmetric(
                horizontal: cardPadding,
                vertical: mediaQuery.size.height * 0.012),
            child: Row(
              children: [
                Icon(CupertinoIcons.location_solid,
                    size: fontSizeSubtitle,
                    color: isCancelled
                        ? CupertinoColors.systemGrey2
                        : CupertinoColors.systemGrey),
                SizedBox(width: mediaQuery.size.width * 0.01),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(
                      fontSize: fontSizeSubtitle,
                      color: textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Dates and Times section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pickup Date and Time
                _buildDateTimeSection(
                  "Pickup",
                  pickupDate,
                  pickupTime,
                  isCancelled,
                  fontSizeSubtitle,
                ),
                SizedBox(height: mediaQuery.size.height * 0.01),
                // Return Date and Time
                _buildDateTimeSection(
                  "Return",
                  returnDate,
                  returnTime,
                  isCancelled,
                  fontSizeSubtitle,
                ),
              ],
            ),
          ),

          SizedBox(height: mediaQuery.size.height * 0.012),

          // Status section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: mediaQuery.size.width * 0.02,
                      vertical: mediaQuery.size.height * 0.005),
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
                      fontSize: fontSizeSubtitle * 0.9,
                    ),
                  ),
                ),
                if (status.toLowerCase() == 'cancelled' &&
                    cancelledDate != null)
                  Padding(
                    padding:
                        EdgeInsets.only(top: mediaQuery.size.height * 0.005),
                    child: Text(
                      "Cancelled on: $cancelledDate",
                      style: TextStyle(
                        color: CupertinoColors.systemRed,
                        fontSize: fontSizeSubtitle,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Cancel button (if applicable)
          if (status.toLowerCase() != 'cancelled') ...[
            SizedBox(height: mediaQuery.size.height * 0.015),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: cardPadding),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: CupertinoColors.systemRed,
                  borderRadius: BorderRadius.circular(8),
                  padding: EdgeInsets.symmetric(
                      vertical: mediaQuery.size.height * 0.015),
                  child: Text(
                    "Cancel Booking",
                    style: TextStyle(fontSize: fontSizeSubtitle),
                  ),
                  onPressed: () {
                    _cancelBooking(context);
                  },
                ),
              ),
            ),
          ],
          SizedBox(height: mediaQuery.size.height * 0.01),
        ],
      ),
    );
  }

  void _cancelBooking(BuildContext context) async {
    // Check if the current status is "Paid"
    if (status.toLowerCase() != 'paid') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only paid bookings can be cancelled.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show confirmation dialog
    bool confirmCancel = await showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text("Cancel Booking"),
          content: const Text("Are you sure you want to cancel this booking?"),
          actions: [
            CupertinoDialogAction(
              child: const Text("No"),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text("Yes"),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    // If confirmed, update Firestore and local state
    if (confirmCancel) {
      try {
        Timestamp now = Timestamp.now();

        // Get the current booking document to access carDetails
        final bookingDoc = await FirebaseFirestore.instance
            .collection('Booking')
            .doc(bookingId)
            .get();

        if (!bookingDoc.exists) {
          throw Exception("Booking not found");
        }

        final bookingData = bookingDoc.data() as Map<String, dynamic>;
        final carDetails = bookingData['carDetails'] as Map<String, dynamic>;

        // Update booking with new status and carDetails
        await FirebaseFirestore.instance
            .collection('Booking')
            .doc(bookingId)
            .update({
          'Status': 'cancelled',
          'cancelledAt': now,
          'carDetails': {...carDetails, 'Status': 'available'}
        });

        // Update car status in vendors collection
        if (carDetails["vendorId"] != null && carDetails["carId"] != null) {
          final carRef = FirebaseFirestore.instance
              .collection("vendors")
              .doc(carDetails["vendorId"])
              .collection("CarDetails")
              .doc(carDetails["carId"]);

          // Check if car document exists
          final carDoc = await carRef.get();
          if (carDoc.exists) {
            await carRef.update({"Status": "available"});
          } else {
            debugPrint("Car document not found in vendors collection");
          }
        } else {
          debugPrint("Missing vendorId or carId in carDetails");
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint("Error cancelling booking: $e");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error cancelling booking: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildDateTimeSection(String label, String date, String time,
      bool isCancelled, double fontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize * 0.9,
            color: isCancelled
                ? CupertinoColors.systemGrey2
                : CupertinoColors.systemGrey,
          ),
        ),
        SizedBox(height: mediaQuery.size.height * 0.005),
        Row(
          children: [
            Icon(
              label == "Pickup"
                  ? CupertinoIcons.car_detailed
                  : CupertinoIcons.arrow_turn_up_left,
              size: fontSize * 1.1,
              color: isCancelled
                  ? CupertinoColors.systemGrey2
                  : CupertinoColors.systemGrey,
            ),
            SizedBox(width: mediaQuery.size.width * 0.02),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(date),
                  style: TextStyle(
                    fontSize: fontSize * 1.1,
                    fontWeight: FontWeight.w500,
                    color: isCancelled
                        ? CupertinoColors.systemGrey
                        : CupertinoColors.black,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: fontSize * 1.0,
                    color: isCancelled
                        ? CupertinoColors.systemGrey2
                        : CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(String date) {
    try {
      DateTime parsedDate = DateTime.parse(date);
      return DateFormat('MMM dd, yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }
}
