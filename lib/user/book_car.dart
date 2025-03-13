import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../screen/payment_screen.dart';
import 'more_car_details.dart';

class CarBookingScreen extends StatefulWidget {
  final Map<String, dynamic> car;

  const CarBookingScreen({Key? key, required this.car}) : super(key: key);

  @override
  _CarBookingScreenState createState() => _CarBookingScreenState();
}

class _CarBookingScreenState extends State<CarBookingScreen> {
  String selectedPlan = '1 Month';

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

      String priceSuffix = selectedPlan == '1 Month'
          ? '/1 month'
          : selectedPlan == '6 Month'
              ? '/6 months'
              : '/12 months';

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
                      child:
                          Text('Close', style: TextStyle(color: Colors.black)),
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
                        Text(widget.car['Car Brand'] ?? 'Unknown Brand'),
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
                        _buildSelectablePlanCard('1 Month', '\₹$oneMonthPrice'),
                        SizedBox(width: 16), // Spacing between cards
                        _buildSelectablePlanCard('6 Month', '\₹$sixMonthPrice'),
                        SizedBox(width: 16), // Spacing between cards
                        _buildSelectablePlanCard(
                            '12 Month', '\₹$twelveMonthPrice'),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PaymentScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Book Now \$$selectedPrice$priceSuffix',
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

  Widget _buildSelectablePlanCard(String title, String price,
      {num discount = 0}) {
    bool isSelected = selectedPlan == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPlan = title;
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
