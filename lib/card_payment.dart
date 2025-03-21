import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CardPaymentScreen extends StatefulWidget {
  final num amount;
  final String vendorName;
  final String pickupDate;
  final String returnDate;
  final Map<String, dynamic> car;

  const CardPaymentScreen({
    Key? key,
    required this.amount,
    required this.vendorName,
    required this.car,
    required this.pickupDate,
    required this.returnDate,
  }) : super(key: key);

  @override
  _CardPaymentScreenState createState() => _CardPaymentScreenState();
}

class _CardPaymentScreenState extends State<CardPaymentScreen> {
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();
  bool isLoading = false;
  DateTime? selectedExpiryDate;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> _storeBooking(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showDialog(context, "Error", "User not logged in!");
      return;
    }

    setState(() => isLoading = true);

    try {
      // Store booking details in Firestore
      await FirebaseFirestore.instance.collection("Booking").add({
        "userId": user.uid,
        "vendorName": widget.vendorName,
        "amount": widget.amount,
        "cardNumber": cardNumberController.text.trim(),
        "cvv": cvvController.text.trim(),
        "expiryDate": expiryDateController.text.trim(),
        "timestamp": FieldValue.serverTimestamp(),
        "carDetails": widget.car,
        "Status": 'Paid',
        "pickupDate": widget.pickupDate,
        "returnDate": widget.returnDate,
      });

      // Update car status to "Pending" in Firestore
      if (widget.car.containsKey("carId") &&
          widget.car.containsKey("vendorId")) {
        String carId = widget.car["carId"];
        String vendorId = widget.car["vendorId"];

        // Update the car status to "Pending"
        await FirebaseFirestore.instance
            .collection("vendors")
            .doc(vendorId)
            .collection("CarDetails")
            .doc(carId)
            .update({"Status": "Pending"});
      }

      _showDialog(
        context,
        "Success",
        "Payment Successful & Booking Confirmed",
        onConfirm: () {
          Navigator.pop(context); // Close the success dialog
          Navigator.pop(context); // Return to the previous screen
        },
      );
    } catch (e) {
      _showDialog(context, "Error", "Payment Failed: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showDialog(BuildContext context, String title, String message,
      {VoidCallback? onConfirm}) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text("OK"),
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              if (onConfirm != null) onConfirm();
            },
          ),
        ],
      ),
    );
  }

  void _showExpiryDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            // Done and Cancel Buttons
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: CupertinoColors.systemGrey5.resolveFrom(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: Text("Cancel"),
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop();
                    },
                  ),
                  CupertinoButton(
                    child: Text("Done"),
                    onPressed: () {
                      setState(() {
                        if (selectedExpiryDate != null) {
                          expiryDateController.text =
                              DateFormat('MM/yy').format(selectedExpiryDate!);
                        }
                      });
                      Navigator.of(context, rootNavigator: true).pop();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                minimumDate: DateTime.now(),
                maximumDate: DateTime(DateTime.now().year + 10),
                onDateTimeChanged: (DateTime date) {
                  selectedExpiryDate = date;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(middle: Text("Card Payment")),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Vendor: ${widget.vendorName}",
                    style: TextStyle(fontSize: 18)),
                Text("Amount: ₹${widget.amount}",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                CupertinoTextField(
                  controller: cardNumberController,
                  placeholder: "Card Number",
                  keyboardType: TextInputType.number,
                  padding: EdgeInsets.all(12),
                  maxLength: 16,
                  decoration: BoxDecoration(
                    border: Border.all(color: CupertinoColors.systemGrey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: _showExpiryDatePicker,
                  child: AbsorbPointer(
                    child: CupertinoTextField(
                      controller: expiryDateController,
                      placeholder: "Expiry Date (MM/YY)",
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: CupertinoColors.systemGrey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                CupertinoTextField(
                  controller: cvvController,
                  placeholder: "CVV",
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  padding: EdgeInsets.all(12),
                  maxLength: 3,
                  decoration: BoxDecoration(
                    border: Border.all(color: CupertinoColors.systemGrey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed:
                        isLoading ? null : () => _validateAndPay(context),
                    child: isLoading
                        ? CupertinoActivityIndicator()
                        : Text("Pay Now"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _validateAndPay(BuildContext context) {
    if (cardNumberController.text.trim().length != 16) {
      _showDialog(context, "Error", "Enter a valid 16-digit card number.");
      return;
    }

    if (cvvController.text.trim().length != 3) {
      _showDialog(context, "Error", "Enter a valid 3-digit CVV.");
      return;
    }

    if (selectedExpiryDate == null ||
        selectedExpiryDate!.isBefore(DateTime.now())) {
      _showDialog(context, "Error", "Select a valid expiry date.");
      return;
    }

    _storeBooking(context);
  }
}
