import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pay/pay.dart';
import '../card_payment.dart';

class PaymentScreen extends StatelessWidget {
  final num amount;
  final String vendorName;
  final Map<String, dynamic> car;
  final DateTime pickupDate;
  final DateTime returnDate;

  const PaymentScreen({
    Key? key,
    required this.amount,
    required this.vendorName,
    required this.car,
    required this.pickupDate,
    required this.returnDate,
  }) : super(key: key);

  Future<void> _storeBookingData(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('Booking').add({
        'amount': amount,
        'vendorName': vendorName,
        'car': car,
        'pickupDate': pickupDate.toIso8601String(),
        'returnDate': returnDate.toIso8601String(),
        'status': 'Pending', // Default status before confirmation
        'createdAt': Timestamp.now(),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '₹$amount',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
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
                paymentConfiguration: PaymentConfiguration.fromJsonString('''
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
                  _storeBookingData(
                      context); // Ensure this runs when payment is successful
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
                        returnDate:
                            returnDate.toIso8601String(), // Call after payment
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
    );
  }
}
