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
                  Location: bookingData['carDetails']?['Location'] ??
                      'Unknown Location',
                  location: bookingData['carDetails']?['Location'] ??
                      'Unknown Location',
                  pickupDate: bookingData['pickupDate'] ?? 'Unknown Date',
                  returnDate: bookingData['returnDate'] ?? 'Unknown Date',
                  frontImage: bookingData['carDetails']?['frontImage'],
                  bookingDateTime: formattedDate,
                  status: bookingData['Status'] ?? 'Unknown',
                  cancelledDate: cancelledDate,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class BookingCard extends StatefulWidget {
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
    required Location,
  });

  @override
  _BookingCardState createState() => _BookingCardState();
}

class _BookingCardState extends State<BookingCard> {
  late String _status;
  String? _cancelledDate;

  @override
  void initState() {
    super.initState();
    _status = widget.status;
    _cancelledDate = widget.cancelledDate;
  }

  void _cancelBooking() async {
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

    if (confirmCancel) {
      Timestamp now = Timestamp.now();

      await FirebaseFirestore.instance
          .collection('Booking')
          .doc(widget.bookingId)
          .update({
        'Status': 'cancelled',
        'cancelledAt': now,
      });

      setState(() {
        _status = 'cancelled';
        _cancelledDate = DateFormat('yyyy-MM-dd').format(now.toDate());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedPickupDate =
        DateFormat('yyyy-MM-dd').format(DateTime.parse(widget.pickupDate));
    String formattedReturnDate =
        DateFormat('yyyy-MM-dd').format(DateTime.parse(widget.returnDate));

    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (widget.frontImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      widget.frontImage!,
                      width: screenWidth * 0.2,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.modelName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.vendorName,
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.systemGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  "₹${widget.amount}/day",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  CupertinoIcons.star_fill,
                  color: CupertinoColors.systemYellow,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  "4.99",
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.location,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    "Pickup: $formattedPickupDate",
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.systemGrey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  child: Text(
                    "Return: $formattedReturnDate",
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.systemGrey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_status == 'cancelled' && _cancelledDate != null)
              Text(
                "Cancelled on: $_cancelledDate",
                style: const TextStyle(
                  color: CupertinoColors.systemRed,
                  fontSize: 14,
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Status: $_status",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _status == 'cancelled'
                        ? CupertinoColors.systemOrange
                        : CupertinoColors.systemGreen,
                  ),
                ),
                if (_status != 'cancelled')
                  CupertinoButton(
                    color: CupertinoColors.systemRed,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: const Text("Cancel"),
                    onPressed: _cancelBooking,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
