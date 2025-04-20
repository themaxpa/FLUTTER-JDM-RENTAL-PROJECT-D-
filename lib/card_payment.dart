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
  final String pickupTime;
  final String returnTime;

  const CardPaymentScreen({
    Key? key,
    required this.amount,
    required this.vendorName,
    required this.car,
    required this.pickupDate,
    required this.returnDate,
    required this.pickupTime,
    required this.returnTime,
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
  bool isCardValid = false;
  DocumentReference? bookingRef;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    cardNumberController.addListener(_validateCard);
  }

  @override
  void dispose() {
    cardNumberController.dispose();
    expiryDateController.dispose();
    cvvController.dispose();
    super.dispose();
  }

  void _validateCard() {
    setState(() {
      isCardValid = cardNumberController.text.length == 16 &&
          cvvController.text.length == 3 &&
          selectedExpiryDate != null;
    });
  }

  Future<void> _storeBooking(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showDialog(context, "Error", "User not logged in!");
      return;
    }

    setState(() => isLoading = true);

    try {
      // First store the booking
      bookingRef = await FirebaseFirestore.instance.collection("Booking").add({
        "userId": user.uid,
        "vendorName": widget.vendorName,
        "amount": widget.amount,
        "cardNumber": cardNumberController.text.trim(),
        "cvv": cvvController.text.trim(),
        "expiryDate": expiryDateController.text.trim(),
        "timestamp": FieldValue.serverTimestamp(),
        "carDetails": {...widget.car, "Status": "Pending"},
        "Status": 'Paid',
        "pickupDate": widget.pickupDate,
        "returnDate": widget.returnDate,
        "vendorId": widget.car["vendorId"],
      });

      // Verify car data exists before updating
      if (!widget.car.containsKey("carId") ||
          !widget.car.containsKey("vendorId")) {
        throw Exception("Missing carId or vendorId in car details");
      }

      //  update car status with proper error handling
      final carRef = FirebaseFirestore.instance
          .collection("vendors")
          .doc(widget.car["vendorId"])
          .collection("CarDetails")
          .doc(widget.car["carId"]);

      // First check if document exists
      final doc = await carRef.get();
      if (!doc.exists) {
        throw Exception("Car document does not exist");
      }

      // Then update the status
      await carRef.update({"Status": "unavailable"});

      // Only show success if everything completed
      await _showSuccessDialog(context);
    } on FirebaseException catch (e) {
      debugPrint("Firestore error: ${e.code} - ${e.message}");

      // Attempt to clean up if booking was created but car update failed
      try {
        if (bookingRef != null) {
          await bookingRef!.delete();
          debugPrint("Rolled back booking creation");
        }
      } catch (deleteError) {
        debugPrint("Failed to delete booking: $deleteError");
      }

      if (e.code == 'permission-denied') {
        _showDialog(context, "Permission Denied",
            "You don't have permission to update this car's status. Please contact support.");
      } else {
        _showDialog(context, "Error", "Payment Failed: ${e.message}");
      }
    } catch (e) {
      debugPrint("Payment failed error: ${e.toString()}");
      _showDialog(
          context, "Error", "An unexpected error occurred. Please try again.");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _showSuccessDialog(BuildContext context) async {
    try {
      await showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.checkmark_circle_fill,
                  color: CupertinoColors.activeGreen),
              SizedBox(width: 8),
              Text("Payment Successful"),
            ],
          ),
          content: Column(
            children: [
              SizedBox(height: 16),
              Text("Your booking has been confirmed"),
              SizedBox(height: 8),
              Text("Amount: ₹${widget.amount}",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              child: Text("Done"),
              onPressed: () {
                Navigator.of(context)
                  ..pop() // Pop the dialog
                  ..pop(); // Pop the payment screen
              },
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint("Error showing success dialog: $e");
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _showDialog(BuildContext context, String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text('Payment'),
            backgroundColor: CupertinoColors.systemBackground.withOpacity(0.8),
          ),
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Amount Display
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Material(
                          color: Colors.transparent,
                          child: Column(
                            children: [
                              Text(
                                "₹${widget.amount}",
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: CupertinoColors.black,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                widget.vendorName,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 32),

                      // Card Details Section
                      Container(
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  CupertinoColors.systemGrey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: cardNumberController,
                              placeholder: "Card Number",
                              keyboardType: TextInputType.number,
                              maxLength: 16,
                              prefix: Icon(CupertinoIcons.creditcard,
                                  color: CupertinoColors.systemGrey),
                            ),
                            Divider(height: 1),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: expiryDateController,
                                    placeholder: "MM/YY",
                                    readOnly: true,
                                    onTap: _showExpiryDatePicker,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 56,
                                  color: CupertinoColors.systemGrey5,
                                ),
                                Expanded(
                                  child: _buildTextField(
                                    controller: cvvController,
                                    placeholder: "CVV",
                                    obscureText: true,
                                    keyboardType: TextInputType.number,
                                    maxLength: 3,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 32),

                      // Pay Button
                      Container(
                        width: double.infinity,
                        height: 50,
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          color: isCardValid
                              ? CupertinoColors.activeBlue
                              : CupertinoColors.systemGrey3,
                          borderRadius: BorderRadius.circular(25),
                          onPressed: isCardValid && !isLoading
                              ? () => _validateAndPay(context)
                              : null,
                          child: isLoading
                              ? CupertinoActivityIndicator(
                                  color: CupertinoColors.white)
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(CupertinoIcons.lock_fill,
                                        size: 18, color: CupertinoColors.white),
                                    SizedBox(width: 8),
                                    Text(
                                      'Pay ₹${widget.amount}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    bool obscureText = false,
    TextInputType? keyboardType,
    int? maxLength,
    Widget? prefix,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLength: maxLength,
      prefix: prefix != null
          ? Padding(
              padding: EdgeInsets.only(left: 12),
              child: prefix,
            )
          : null,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        border: null,
      ),
      readOnly: readOnly,
      onTap: onTap,
      style: TextStyle(fontSize: 16),
      placeholderStyle: TextStyle(
        color: CupertinoColors.systemGrey,
        fontSize: 16,
      ),
    );
  }

  void _showExpiryDatePicker() {
    final now = DateTime.now();
    final initialDate = now.add(const Duration(milliseconds: 1));
    DateTime? tempSelectedDate = initialDate;

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Container(
            height: 300,
            color: CupertinoColors.systemBackground,
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    border: const Border(
                      bottom: BorderSide(
                        color: CupertinoColors.systemGrey5,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text("Cancel"),
                        onPressed: () => Navigator.pop(context),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text("Done"),
                        onPressed: () {
                          if (tempSelectedDate != null) {
                            setState(() {
                              selectedExpiryDate = tempSelectedDate;
                              expiryDateController.text = DateFormat('MM/yy')
                                  .format(selectedExpiryDate!);
                              _validateCard();
                            });
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: initialDate,
                    minimumDate: now,
                    maximumDate: now.add(const Duration(days: 3650)),
                    onDateTimeChanged: (DateTime date) {
                      tempSelectedDate = date;
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _validateAndPay(BuildContext context) {
    if (cardNumberController.text.trim().length != 16) {
      _showDialog(
          context, "Error", "Please enter a valid 16-digit card number");
      return;
    }

    if (cvvController.text.trim().length != 3) {
      _showDialog(context, "Error", "Please enter a valid 3-digit CVV");
      return;
    }

    if (selectedExpiryDate == null ||
        selectedExpiryDate!.isBefore(DateTime.now())) {
      _showDialog(context, "Error", "Please select a valid future expiry date");
      return;
    }

    _storeBooking(context);
  }
}
