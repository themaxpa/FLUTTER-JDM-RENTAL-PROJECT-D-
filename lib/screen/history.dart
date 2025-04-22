import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

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

                  // Extract location coordinates
                  LatLng? carLocation;
                  if (bookingData['carDetails']?['ELocation'] != null) {
                    final geoPoint =
                        bookingData['carDetails']?['ELocation'] as GeoPoint;
                    carLocation = LatLng(geoPoint.latitude, geoPoint.longitude);
                  }

                  return ExpandableBookingCard(
                    bookingId: booking.id,
                    vendorName: bookingData['vendorName'] ?? 'Unknown Vendor',
                    amount: bookingData['amount']?.toString() ?? 'N/A',
                    modelName: bookingData['carDetails']?['Model Name'] ??
                        'Unknown Model',
                    location: bookingData['carDetails']?['Location'] ??
                        'Unknown Location',
                    frontImage: bookingData['carDetails']?['frontImage'],
                    bookingDateTime: formattedDate,
                    status: bookingData['status'] ??
                        bookingData['Status'] ??
                        'Unknown',
                    cancelledDate: cancelledDate,
                    pickupDate: bookingData['pickupDate'] ?? 'Unknown Date',
                    returnDate: bookingData['returnDate'] ?? 'Unknown Date',
                    pickupTime: bookingData['pickupTime'] ?? 'Unknown Time',
                    returnTime: bookingData['returnTime'] ?? 'Unknown Time',
                    mediaQuery: mediaQuery,
                    carLocation: carLocation,
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

class ExpandableBookingCard extends StatefulWidget {
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
  final LatLng? carLocation;

  const ExpandableBookingCard({
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
    this.carLocation,
  });

  @override
  State<ExpandableBookingCard> createState() => _ExpandableBookingCardState();
}

class _ExpandableBookingCardState extends State<ExpandableBookingCard> {
  bool _isExpanded = false;

  Future<void> _openGoogleMaps(LatLng location) async {
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCancelled = widget.status.toLowerCase() == 'cancelled';
    final cardColor =
        isCancelled ? CupertinoColors.systemGrey5 : CupertinoColors.white;
    final textColor =
        isCancelled ? CupertinoColors.systemGrey : CupertinoColors.black;

    final imageSize = widget.mediaQuery.size.width * 0.25;
    final cardPadding = widget.mediaQuery.size.width * 0.04;
    final fontSizeTitle = widget.mediaQuery.size.width * 0.045;
    final fontSizeSubtitle = widget.mediaQuery.size.width * 0.035;
    final mapHeight = widget.mediaQuery.size.height * 0.2;

    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: widget.mediaQuery.size.height * 0.015),
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
            // Collapsed view (always visible)
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
                      color: widget.frontImage != null
                          ? Colors.transparent
                          : CupertinoColors.systemGrey5,
                    ),
                    child: widget.frontImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Opacity(
                              opacity: isCancelled ? 0.6 : 1.0,
                              child: Image.network(
                                widget.frontImage!,
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
                  SizedBox(width: widget.mediaQuery.size.width * 0.03),
                  // Car details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.modelName,
                          style: TextStyle(
                            fontSize: fontSizeTitle,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: widget.mediaQuery.size.height * 0.005),
                        Text(
                          widget.vendorName,
                          style: TextStyle(
                            fontSize: fontSizeSubtitle,
                            color: isCancelled
                                ? CupertinoColors.systemGrey2
                                : CupertinoColors.systemGrey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: widget.mediaQuery.size.height * 0.01),
                        Text(
                          "₹${widget.amount}/day",
                          style: TextStyle(
                            fontSize: fontSizeTitle,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Expand/collapse icon
                  Icon(
                    _isExpanded
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    color: CupertinoColors.systemGrey,
                  ),
                ],
              ),
            ),

            // Status chip (always visible)
            Padding(
              padding: EdgeInsets.only(
                  left: cardPadding,
                  right: cardPadding,
                  bottom: _isExpanded ? 0 : cardPadding),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: widget.mediaQuery.size.width * 0.02,
                    vertical: widget.mediaQuery.size.height * 0.005),
                decoration: BoxDecoration(
                  color: isCancelled
                      ? CupertinoColors.systemGrey4
                      : CupertinoColors.systemGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.status.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCancelled
                        ? CupertinoColors.systemGrey
                        : CupertinoColors.systemGreen,
                    fontSize: fontSizeSubtitle * 0.9,
                  ),
                ),
              ),
            ),

            // Expanded content (only visible when expanded)
            if (_isExpanded) ...[
              const Divider(height: 1, thickness: 0.5),

              // Cancelled date (if applicable)
              if (widget.status.toLowerCase() == 'cancelled' &&
                  widget.cancelledDate != null)
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: cardPadding,
                      vertical: widget.mediaQuery.size.height * 0.01),
                  child: Text(
                    "Cancelled on: ${widget.cancelledDate}",
                    style: TextStyle(
                      color: CupertinoColors.systemRed,
                      fontSize: fontSizeSubtitle,
                    ),
                  ),
                ),

              // Map section
              if (widget.carLocation != null) ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: cardPadding),
                  child: GestureDetector(
                    onTap: () => _openGoogleMaps(widget.carLocation!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          SizedBox(
                            height: mapHeight,
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter: widget.carLocation!,
                                initialZoom: 15.0,
                                interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag.all &
                                      ~InteractiveFlag.rotate,
                                ),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.app',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      width: 40,
                                      height: 40,
                                      point: widget.carLocation!,
                                      child: const Icon(
                                        Icons.location_pin,
                                        color: Colors.red,
                                        size: 40,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Positioned(
                            top: 8,
                            right: 8,
                            child: Icon(
                              Icons.open_in_new,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${widget.carLocation!.latitude.toStringAsFixed(4)}, '
                                '${widget.carLocation!.longitude.toStringAsFixed(4)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: widget.mediaQuery.size.height * 0.015),
              ],

              // Dates and Times section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pickup Date and Time
                    _buildDateTimeSection(
                      "Pickup",
                      widget.pickupDate,
                      widget.pickupTime,
                      isCancelled,
                      fontSizeSubtitle,
                    ),
                    SizedBox(height: widget.mediaQuery.size.height * 0.01),
                    // Return Date and Time
                    _buildDateTimeSection(
                      "Return",
                      widget.returnDate,
                      widget.returnTime,
                      isCancelled,
                      fontSizeSubtitle,
                    ),
                  ],
                ),
              ),

              SizedBox(height: widget.mediaQuery.size.height * 0.012),

              // Location section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: cardPadding),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.location_solid,
                        size: fontSizeSubtitle,
                        color: isCancelled
                            ? CupertinoColors.systemGrey2
                            : CupertinoColors.systemGrey),
                    SizedBox(width: widget.mediaQuery.size.width * 0.02),
                    Expanded(
                      child: Text(
                        widget.location,
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

              SizedBox(height: widget.mediaQuery.size.height * 0.015),

              // Cancel button (if applicable)
              if (widget.status.toLowerCase() == 'paid' && !isCancelled) ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: cardPadding),
                  child: Column(
                    children: [
                      const Divider(height: 1, thickness: 0.5),
                      SizedBox(height: widget.mediaQuery.size.height * 0.015),
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoButton(
                          color: CupertinoColors.destructiveRed,
                          borderRadius: BorderRadius.circular(8),
                          padding: EdgeInsets.symmetric(
                              vertical: widget.mediaQuery.size.height * 0.015),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(CupertinoIcons.xmark_circle, size: 20),
                              SizedBox(
                                  width: widget.mediaQuery.size.width * 0.02),
                              Text(
                                "Cancel Booking",
                                style: TextStyle(fontSize: fontSizeSubtitle),
                              ),
                            ],
                          ),
                          onPressed: () => _cancelBooking(context),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: widget.mediaQuery.size.height * 0.01),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _cancelBooking(BuildContext context) async {
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
      try {
        // First get the current booking data
        final bookingDoc = await FirebaseFirestore.instance
            .collection('Booking')
            .doc(widget.bookingId)
            .get();

        if (!bookingDoc.exists) {
          throw Exception('Booking not found');
        }

        final bookingData = bookingDoc.data() as Map<String, dynamic>;
        final carDetails = bookingData['carDetails'] as Map<String, dynamic>;

        // Update booking status to cancelled
        await FirebaseFirestore.instance
            .collection('Booking')
            .doc(widget.bookingId)
            .update({
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
          'carDetails': {
            ...carDetails,
            'Status': 'available' // Update car status to available
          }
        });

        // Update car status in vendor's collection
        if (carDetails['vendorId'] != null && carDetails['carId'] != null) {
          await FirebaseFirestore.instance
              .collection('vendors')
              .doc(carDetails['vendorId'])
              .collection('CarDetails')
              .doc(carDetails['carId'])
              .update({'Status': 'available'});
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel booking: $e'),
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
        SizedBox(height: widget.mediaQuery.size.height * 0.005),
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
            SizedBox(width: widget.mediaQuery.size.width * 0.02),
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
                  _formatTime(time),
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

  String _formatTime(String time) {
    try {
      // Try to parse time in 24-hour format first
      final format24 = DateFormat('HH:mm');
      DateTime parsedTime = format24.parse(time);
      return DateFormat('h:mm a').format(parsedTime);
    } catch (e) {
      // If parsing fails, try 12-hour format with AM/PM
      try {
        final format12 = DateFormat('h:mm a');
        DateTime parsedTime = format12.parse(time);
        return DateFormat('h:mm a').format(parsedTime);
      } catch (e) {
        // If all parsing fails, return original time
        return time;
      }
    }
  }
}
