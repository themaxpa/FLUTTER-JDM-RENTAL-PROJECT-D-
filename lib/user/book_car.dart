import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../screen/payment_screen.dart';
import '../vendor/cars/more_car_details.dart';

class CarBookingScreen extends StatefulWidget {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  bool showMyCars = false;
  final Map<String, dynamic> car;

  CarBookingScreen(
      {super.key, required this.car, required carId, required vendorId});

  @override
  _CarBookingScreenState createState() => _CarBookingScreenState();
}

class _CarBookingScreenState extends State<CarBookingScreen> {
  DateTime? pickupDate;
  DateTime? returnDate;
  double pickupTime = 5.0;
  double returnTime = 22.0;
  String selectedPlan = '1 Month';
  String vendorName = '';

  TextEditingController pickupDateController = TextEditingController();
  TextEditingController returnDateController = TextEditingController();

  @override
  void dispose() {
    pickupDateController.dispose();
    returnDateController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    String vendorId = widget.car['uid'] ?? '';
    vendorName =
        widget.car['vendorName'] ?? 'Unknown Vendor'; // Extract vendor name
    if (vendorId.isEmpty && kDebugMode) {
      print('Vendor ID is missing.');
    }
  }

  void _calculateReturnDate() {
    if (pickupDate != null) {
      switch (selectedPlan) {
        case '1 Month':
          returnDate = pickupDate!.add(Duration(days: 30));
          break;
        case '6 Month':
          returnDate = pickupDate!.add(Duration(days: 180));
          break;
        case '12 Month':
          returnDate = pickupDate!.add(Duration(days: 365));
          break;
      }
      returnDateController.text = returnDate!
          .toLocal()
          .toString()
          .split(' ')[0]; // Update return date field
    }
  }

  // Function to show Android-style date picker
  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: pickupDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        pickupDate = picked;
        pickupDateController.text = picked
            .toLocal()
            .toString()
            .split(' ')[0]; // Update pickup date field
        _calculateReturnDate();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final oneMonthPrice =
          num.tryParse(widget.car['1MonthPrice'].toString()) ?? 0;
      final sixMonthPrice =
          num.tryParse(widget.car['6MonthPrice'].toString()) ?? 0;
      final twelveMonthPrice =
          num.tryParse(widget.car['12MonthPrice'].toString()) ?? 0;

      print(widget.car);

      num selectedPrice = selectedPlan == '1 Month'
          ? oneMonthPrice
          : selectedPlan == '6 Month'
              ? sixMonthPrice
              : twelveMonthPrice;

      if (oneMonthPrice == 0 && sixMonthPrice == 0 && twelveMonthPrice == 0) {
        return CupertinoAlertDialog(
          title: Text('No Pricing Available'),
          content:
              Text('Car pricing details are missing. Please check back later.'),
          actions: [
            CupertinoDialogAction(
              child: Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      }

      return Scaffold(
        backgroundColor: CupertinoColors.systemGroupedBackground,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Close',
                            style: TextStyle(color: Colors.black)),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 200,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildImage(widget.car['frontImage']),
                      SizedBox(width: 8),
                      _buildImage(widget.car['backImage']),
                      SizedBox(width: 8),
                      _buildImage(widget.car['sideImage']),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.car['Model Name'] ?? 'Unknown Car',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16),
                          SizedBox(width: 4),
                          Text(
                              widget.car['Location'] ?? 'Currently Unavailabe'),
                          SizedBox(width: 16),
                          Icon(Icons.info, size: 16),
                          SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) =>
                                      CarDetailsScreen(car: widget.car),
                                ),
                              );
                            },
                            child: Text('More Info'),
                          ),
                          SizedBox(width: 4),
                          Row(
                            children: [
                              Icon(Icons.verified, size: 16),
                              SizedBox(width: 4),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (context) =>
                                          CarDetailsScreen(car: widget.car),
                                    ),
                                  );
                                },
                                child: Text(
                                  vendorName,
                                  // Now displaying extracted vendor name
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSpec('Color', widget.car['Color']),
                          _buildSpec('Power', widget.car['power']),
                          _buildSpec('Seats', widget.car['Seats']),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSpec('0-100 km/h', widget.car['Speed (0-100)']),
                          _buildSpec('Max Speed', widget.car['maxSpeed']),
                          _buildSpec('Drive', widget.car['drive']),
                        ],
                      ),
                      SizedBox(height: 24),
                      Text('Plans',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildSelectablePlanCard(
                              '1 Month', '\₹$oneMonthPrice'),
                          SizedBox(width: 16), // Spacing between cards
                          _buildSelectablePlanCard(
                              '6 Month', '\₹$sixMonthPrice'),
                          SizedBox(width: 16), // Spacing between cards
                          _buildSelectablePlanCard(
                              '12 Month', '\₹$twelveMonthPrice'),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pickup Date Field
                      TextField(
                        controller: pickupDateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Pickup Date',
                          suffixIcon: IconButton(
                            icon: Icon(Icons.calendar_today),
                            onPressed: () => _selectDate(context),
                          ),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Return Date Field (Read-only)
                      TextField(
                        controller: returnDateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Return Date (Auto-Calculated)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),

                // Add space between the date picker and the "Book Now" button
                SizedBox(height: 80), // Adjust this value as needed
              ],
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              if (pickupDate == null || returnDate == null) {
                showDialog(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    title: Text('Select Dates'),
                    content:
                        Text('Please select a pickup date before proceeding.'),
                    actions: [
                      CupertinoDialogAction(
                        child: Text('OK'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentScreen(
                    car: widget.car,
                    amount: selectedPrice,
                    vendorName: vendorName,
                    pickupDate: pickupDate!,
                    returnDate: returnDate!,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Book Now ₹$selectedPrice',
                style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ),
      );
    } catch (e) {
      return CupertinoAlertDialog(
        title: Text('Error'),
        content: Text('Failed to load car details. Please try again later.'),
        actions: [
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
    }
  }

  Widget _buildImage(String? imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        imageUrl ?? '',
        width: 300,
        height: 200,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildSpec(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: Colors.grey)),
        SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSelectablePlanCard(String title, String price) {
    bool isSelected = selectedPlan == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPlan = title;
          if (pickupDate != null) {
            _calculateReturnDate();
          }
        });
      },
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? Colors.black : Colors.grey),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.black : Colors.white,
        ),
        child: Column(
          children: [
            Text(title,
                style:
                    TextStyle(color: isSelected ? Colors.white : Colors.black)),
            SizedBox(height: 4),
            Text(price,
                style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
