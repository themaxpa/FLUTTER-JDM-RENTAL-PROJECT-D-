import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pay/pay.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: Center(
        child: GooglePayButton(
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
                  "totalPrice": "0.01",
                  "currencyCode": "USD",
                  "countryCode": "US"
                }
              }
            }
            '''),
          paymentItems: const [
            PaymentItem(
              label: "Total",
              amount: "0.01",
              status: PaymentItemStatus.final_price,
            ),
          ],
          type: GooglePayButtonType.pay,
          onPaymentResult: (result) {
            // Handle the payment result
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Payment Result: $result"),
              ),
            );
          },
          margin: const EdgeInsets.only(top: 15.0),
          loadingIndicator: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}
