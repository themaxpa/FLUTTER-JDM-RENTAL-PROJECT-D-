import 'package:flutter/material.dart';
import 'package:pay/pay.dart';

class PaymentScreen extends StatelessWidget {
  final num amount;
  final String vendorName;
  final String companyName;

  const PaymentScreen({
    Key? key,
    required this.amount,
    required this.vendorName,
    required this.companyName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Print parameter data for debugging
    print(
        'Amount: $amount, Vendor Name: $vendorName, Company Name: $companyName');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '\₹$amount',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '$companyName\n$vendorName',
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
                      "merchantName": "My Dummy App"
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
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Payment Successful: $result")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Payment Failed: $e")),
                    );
                  }
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
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Credit Card Payment Selected")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: $e")),
                    );
                  }
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
