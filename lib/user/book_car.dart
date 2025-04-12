import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../screen/payment_screen.dart';
import 'my_documents.dart';

class CarBookingScreen extends StatefulWidget {
  final Map<String, dynamic> car;
  final String? carId;
  final String? vendorId;

  const CarBookingScreen({
    Key? key,
    required this.car,
    this.carId,
    this.vendorId,
  }) : super(key: key);

  @override
  State<CarBookingScreen> createState() => _CarBookingScreenState();
}

class _CarBookingScreenState extends State<CarBookingScreen> {
  DateTime? pickupDate;
  String selectedPickupTime = '10AM';
  DateTime? returnDate;
  String selectedPlan = '1 Day';
  String vendorName = '';
  num selectedPrice = 0;
  bool _isVerifying = false;

  final TextEditingController pickupDateController = TextEditingController();
  final TextEditingController returnDateController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const List<String> requiredDocs = [
    'DLFrontSide',
    'DLBackSide',
    'PanCard',
    'AadhaarCardFront',
    'AadhaarCardBack',
  ];

  final List<String> pickupTimeOptions = ['10AM', '3PM', '5PM'];

  @override
  void initState() {
    super.initState();
    vendorName = widget.car['vendorName'] ?? 'Unknown Vendor';
    _calculatePrice();
  }

  @override
  void dispose() {
    pickupDateController.dispose();
    returnDateController.dispose();
    super.dispose();
  }

  void _calculatePrice() {
    final oneDay = num.tryParse(widget.car['1DayPrice'].toString()) ?? 0;
    final oneMonth = num.tryParse(widget.car['1MonthPrice'].toString()) ?? 0;
    final sixMonth = num.tryParse(widget.car['6MonthPrice'].toString()) ?? 0;

    setState(() {
      selectedPrice = selectedPlan == '1 Day'
          ? oneDay
          : selectedPlan == '1 Month'
              ? oneMonth
              : sixMonth;
    });
  }

  TimeOfDay _parseTimeString(String timeStr) {
    final time = timeStr.replaceAll(RegExp(r'[^0-9]'), '');
    final hour = int.parse(time);
    final isPM = timeStr.toUpperCase().contains('PM');

    return TimeOfDay(
      hour: isPM ? (hour == 12 ? 12 : hour + 12) : (hour == 12 ? 0 : hour),
      minute: 0,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: pickupDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        pickupDate = picked;
        pickupDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        _calculateReturnDate();
      });
    }
  }

  void _calculateReturnDate() {
    if (pickupDate != null) {
      setState(() {
        returnDate = selectedPlan == '1 Day'
            ? pickupDate!.add(const Duration(days: 1))
            : selectedPlan == '1 Month'
                ? pickupDate!.add(const Duration(days: 30))
                : pickupDate!.add(const Duration(days: 180));
        returnDateController.text =
            DateFormat('yyyy-MM-dd').format(returnDate!);
      });
    }
  }

  Future<bool> _verifyAllDocuments() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('User not logged in');
        return false;
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('MyDocuments')
          .get();

      debugPrint('Found ${snapshot.docs.length} documents in collection');

      final uploadedDocs = <String, String>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final title = data['title']?.toString() ?? '';
        final url = data['url']?.toString() ?? '';

        debugPrint(
            'Document: $title, URL: ${url.isNotEmpty ? "exists" : "empty"}');

        if (title.isNotEmpty) {
          uploadedDocs[title] = url;
        }
      }

      bool allDocumentsValid = true;
      for (var docTitle in requiredDocs) {
        if (!uploadedDocs.containsKey(docTitle)) {
          debugPrint('Missing document: $docTitle');
          allDocumentsValid = false;
        } else if (uploadedDocs[docTitle]!.isEmpty) {
          debugPrint('Empty URL for document: $docTitle');
          allDocumentsValid = false;
        }
      }

      if (allDocumentsValid) {
        debugPrint('All documents verified successfully!');
      } else {
        debugPrint('Some documents are missing or invalid');
      }

      return allDocumentsValid;
    } catch (e) {
      debugPrint('Document verification error: $e');
      return false;
    }
  }

  void _handleBookNow() async {
    if (pickupDate == null || returnDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select pickup and return dates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final hasAllDocuments = await _verifyAllDocuments();

      if (!hasAllDocuments) {
        final shouldUpload = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Documents Required'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Please upload all required documents:'),
                  const SizedBox(height: 16),
                  ...requiredDocs.map(
                    (doc) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('• $doc'),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('UPLOAD NOW'),
              ),
            ],
          ),
        );

        if (shouldUpload == true) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MyDocumentsScreen(),
            ),
          );
        }
        return;
      }

      if (widget.carId != null) {
        await _firestore
            .collection('vendors')
            .doc('carDetails')
            .collection('CarDetails')
            .doc(widget.carId)
            .update({
          'bookingDetails': {
            'userId': _auth.currentUser?.uid,
            'userName': _auth.currentUser?.displayName ?? 'Unknown User',
            'pickupDate': Timestamp.fromDate(pickupDate!),
            'pickupTime': selectedPickupTime,
            'returnDate': Timestamp.fromDate(returnDate!),
            'plan': selectedPlan,
            'price': selectedPrice,
            'bookingDate': FieldValue.serverTimestamp(),
            'status': 'pending',
          }
        });
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            car: widget.car,
            amount: selectedPrice,
            vendorName: vendorName,
            pickupDate: pickupDate!,
            pickupTime: _parseTimeString(selectedPickupTime),
            // Convert to TimeOfDay
            returnDate: returnDate!,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Widget _buildPlanCard(String title, String price) {
    final isSelected = selectedPlan == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPlan = title;
          _calculatePrice();
          if (pickupDate != null) _calculateReturnDate();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              price,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeOption(String time) {
    final isSelected = selectedPickupTime == time;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPickupTime = time;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey,
            width: 1.5,
          ),
        ),
        child: Text(
          time,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Your Car'),
        leading: IconButton(
          icon: Icon(isIOS ? Icons.arrow_back_ios : Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: isIOS ? 0 : null,
        scrolledUnderElevation: isIOS ? 0 : null,
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: mediaQuery.size.width > 600 ? 32 : 16,
          vertical: 16,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: mediaQuery.size.height -
                mediaQuery.padding.top -
                kToolbarHeight,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: mediaQuery.size.height * 0.25,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildCarImage(widget.car['frontImage']),
                    _buildCarImage(widget.car['backImage']),
                    _buildCarImage(widget.car['sideImage']),
                  ]
                      .map((widget) => Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: widget,
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.car['Model Name'] ?? 'Unknown Model',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 4),
                      Text(widget.car['Location'] ?? 'Location not specified'),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person, size: 16),
                      const SizedBox(width: 4),
                      Text(vendorName),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Specifications',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: mediaQuery.size.width > 600 ? 6 : 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: mediaQuery.size.width > 600 ? 1.5 : 1,
                mainAxisSpacing: 16,
                children: [
                  _buildSpecItem('Color', widget.car['Color']),
                  _buildSpecItem('Seats', widget.car['Seats']),
                  _buildSpecItem('Power', widget.car['power']),
                  _buildSpecItem('0-100 km/h', widget.car['Speed (0-100)']),
                  _buildSpecItem('Max Speed', widget.car['maxSpeed']),
                  _buildSpecItem('Drive', widget.car['drive']),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Select Rental Plan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPlanCard('1 Day', '₹${widget.car['1DayPrice']}'),
                    const SizedBox(width: 12),
                    _buildPlanCard('1 Month', '₹${widget.car['1MonthPrice']}'),
                    const SizedBox(width: 12),
                    _buildPlanCard('6 Month', '₹${widget.car['6MonthPrice']}'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Select Dates',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pickupDateController,
                decoration: InputDecoration(
                  labelText: 'Pickup Date',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Pickup Time',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: pickupTimeOptions
                    .map((time) => _buildTimeOption(time))
                    .toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: returnDateController,
                decoration: InputDecoration(
                  labelText: 'Return Date',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                readOnly: true,
              ),
              SizedBox(height: mediaQuery.size.height * 0.1),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: mediaQuery.size.width > 600 ? 32 : 16,
          vertical: 16,
        ),
        child: _isVerifying
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
                onPressed: _handleBookNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(
                  'Book Now ₹$selectedPrice',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
      ),
    );
  }

  Widget _buildCarImage(String? imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl ?? '',
        width: 300,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 300,
          height: 200,
          color: Colors.grey[200],
          child: const Icon(Icons.error_outline, color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildSpecItem(String title, String? value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          value ?? '-',
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
