import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pay/pay.dart';

import '../card_payment.dart';

class PaymentScreen extends StatelessWidget {
  final num amount;
  final String vendorName;
  final Map<String, dynamic> car;
  final DateTime pickupDate;
  final String pickupTime;
  final String returnTime;
  final DateTime returnDate;

  const PaymentScreen({
    Key? key,
    required this.amount,
    required this.vendorName,
    required this.car,
    required this.pickupDate,
    required this.returnDate,
    required this.pickupTime,
    required this.returnTime,
  }) : super(key: key);

  // Helper function to format TimeOfDay to a string (e.g., "10:30 AM")
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _storeBookingData(BuildContext context) async {
    try {
      // Get current user ID
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await FirebaseFirestore.instance.collection('Booking').add({
        'amount': amount,
        'vendorName': vendorName,
        'car': car,
        'pickupDate': pickupDate.toIso8601String(),
        'returnDate': returnDate.toIso8601String(),
        'pickupTime': pickupTime,
        'returnTime': returnTime,
        'status': 'Pending',
        'createdAt': Timestamp.now(),
        'userId': user.uid, // Store user ID with the booking
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Booking Successful!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Booking Failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Material(
            color: Colors.transparent,
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '₹$amount',
                    style: const TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\n$vendorName',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const Divider(height: 40, thickness: 1),
                  const Text(
                    'Pay with',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 40, thickness: 1),
                  const SizedBox(height: 16),
                  GooglePayButton(
                    paymentConfiguration:
                        PaymentConfiguration.fromJsonString('''
                {
                  "provider": "google_pay",
                  "data": {
                    "environment": "TEST",
                    "apiVersion": 2,
                    "apiVersionMinor": 0,
                    "allowedPaymentMethods": [
                      {
              "type": "CARD",
              "parameters": {
                "allowedAuthMethods": ["PAN_ONLY", "CRYPTOGRAM_3DS"],
                "allowedCardNetworks": ["VISA", "MASTERCARD"]
              },
              "tokenizationSpecification": {
                "type": "PAYMENT_GATEWAY",
                "parameters": {
                  "gateway": "example",
                  "gatewayMerchantId": "exampleGatewayMerchantId"
                }
              }
                      }
                    ],
                    "merchantInfo": {
                      "merchantName": "$vendorName"
                    },
                    "transactionInfo": {
                      "totalPriceStatus": "FINAL",
                      "totalPrice": "$amount",
                      "currencyCode": "USD",
                      "countryCode": "US"
                    }
                  }
                }
                '''),
                    paymentItems: [
                      PaymentItem(
                        label: "Total",
                        amount: amount.toString(),
                        status: PaymentItemStatus.final_price,
                      ),
                    ],
                    type: GooglePayButtonType.pay,
                    onPaymentResult: (result) {
                      _storeBookingData(context);
                    },
                    margin: const EdgeInsets.only(top: 15.0),
                    loadingIndicator:
                        const Center(child: CircularProgressIndicator()),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      minimumSize: Size(width, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CardPaymentScreen(
                            car: car,
                            amount: amount,
                            vendorName: vendorName,
                            pickupDate: pickupDate.toIso8601String(),
                            returnDate: returnDate.toIso8601String(),
                            pickupTime: pickupTime,
                            returnTime: returnTime,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.credit_card, color: Colors.white),
                    label: const Text('Credit Card',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
