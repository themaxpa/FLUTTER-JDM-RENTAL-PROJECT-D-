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

  final FocusNode _cardNumberFocusNode = FocusNode();
  final FocusNode _expiryDateFocusNode = FocusNode();
  final FocusNode _cvvFocusNode = FocusNode();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Add listeners to validate card when fields change
    cardNumberController.addListener(_validateCard);
    cvvController.addListener(_validateCard);
    expiryDateController.addListener(_validateCard);
  }

  @override
  void dispose() {
    _cardNumberFocusNode.dispose();
    _expiryDateFocusNode.dispose();
    _cvvFocusNode.dispose();
    cardNumberController.dispose();
    expiryDateController.dispose();
    cvvController.dispose();
    super.dispose();
  }

  void _validateCard() {
    final isValid = cardNumberController.text.length == 16 &&
        cvvController.text.length == 3 &&
        selectedExpiryDate != null &&
        (selectedExpiryDate!.isAfter(DateTime.now()) ||
            DateFormat('MM/yy').format(selectedExpiryDate!) ==
                DateFormat('MM/yy').format(DateTime.now()));

    if (isCardValid != isValid) {
      setState(() {
        isCardValid = isValid;
      });
    }
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
        "cardLast4": cardNumberController.text.trim().substring(12),
        // Only store last 4 digits for security
        "timestamp": FieldValue.serverTimestamp(),
        "carDetails": {...widget.car, "Status": "unavailable"},
        "status": 'Paid',
        // Changed to lowercase to match Firestore conventions
        "pickupDate": widget.pickupDate,
        "returnDate": widget.returnDate,
        "pickupTime": widget.pickupTime,
        "returnTime": widget.returnTime,
        "vendorId": widget.car["vendorId"],
        "expiryDate": expiryDateController.text.trim(),
      });

      // Verify car data exists before updating
      if (!widget.car.containsKey("carId") ||
          !widget.car.containsKey("vendorId")) {
        throw Exception("Missing carId or vendorId in car details");
      }

      // Update car status
      final carRef = FirebaseFirestore.instance
          .collection("vendors")
          .doc(widget.car["vendorId"])
          .collection("CarDetails")
          .doc(widget.car["carId"]);

      await carRef.update({"Status": "unavailable"});

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

      _showDialog(
          context, "Error", "Payment Failed: ${e.message ?? 'Unknown error'}");
    } catch (e) {
      debugPrint("Payment failed error: $e");
      _showDialog(
          context, "Error", "An unexpected error occurred. Please try again.");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _showSuccessDialog(BuildContext context) async {
    return showCupertinoDialog(
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
            previousPageTitle: 'Back',
          ),
          SliverToBoxAdapter(
            child: SafeArea(
              top: false,
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
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                          color: CupertinoColors.systemBackground,
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
                              focusNode: _cardNumberFocusNode,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter card number';
                                }
                                if (value.length != 16) {
                                  return 'Card number must be 16 digits';
                                }
                                return null;
                              },
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
                                    focusNode: _expiryDateFocusNode,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please select expiry date';
                                      }
                                      return null;
                                    },
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
                                    focusNode: _cvvFocusNode,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter CVV';
                                      }
                                      if (value.length != 3) {
                                        return 'CVV must be 3 digits';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 32),

                      // Pay Button
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoButton(
                          color: isCardValid
                              ? CupertinoColors.systemBlue
                              : CupertinoColors.systemGrey3,
                          borderRadius: BorderRadius.circular(12),
                          onPressed: isCardValid && !isLoading
                              ? () => _storeBooking(context)
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
    FocusNode? focusNode,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: CupertinoTextFormFieldRow(
        controller: controller,
        focusNode: focusNode,
        placeholder: placeholder,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLength: maxLength,
        prefix: prefix,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
        ),
        readOnly: readOnly,
        onTap: onTap,
        style: TextStyle(fontSize: 16),
        placeholderStyle: TextStyle(
          color: CupertinoColors.systemGrey,
          fontSize: 16,
        ),
        validator: validator,
        onChanged: (value) => _validateCard(),
      ),
    );
  }

  void _showExpiryDatePicker() {
    final now = DateTime.now();
    final initialDate = DateTime(now.year, now.month + 1); // Next month

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
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
                        if (selectedExpiryDate != null) {
                          setState(() {
                            expiryDateController.text =
                                DateFormat('MM/yy').format(selectedExpiryDate!);
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
                  maximumDate: DateTime(now.year + 10),
                  onDateTimeChanged: (DateTime date) {
                    selectedExpiryDate = date;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
