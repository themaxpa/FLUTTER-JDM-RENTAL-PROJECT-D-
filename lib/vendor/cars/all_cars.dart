import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'more_car_details.dart';
import 'edit_car_details.dart';

class CreateAdScreen extends StatefulWidget {
  @override
  _CreateAdScreenState createState() => _CreateAdScreenState();
}

class _CreateAdScreenState extends State<CreateAdScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  bool showMyCars = false;

  void _deleteCar(DocumentReference carRef) async {
    await carRef.delete();
    Navigator.of(context).pop();
  }

  void _showDeleteConfirmation(DocumentReference carRef) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Delete Car'),
        content: Text('Are you sure you want to delete this car?'),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            child: Text('Delete',
                style: TextStyle(color: CupertinoColors.destructiveRed)),
            onPressed: () => _deleteCar(carRef),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CupertinoSlidingSegmentedControl<bool>(
              thumbColor: CupertinoColors.activeBlue,
              backgroundColor: CupertinoColors.systemGrey5,
              children: {
                false: Text('All',
                    style: TextStyle(
                        color: !showMyCars
                            ? CupertinoColors.white
                            : CupertinoColors.black)),
                true: Text('My Cars',
                    style: TextStyle(
                        color: showMyCars
                            ? CupertinoColors.white
                            : CupertinoColors.black)),
              },
              groupValue: showMyCars,
              onValueChanged: (bool? value) {
                setState(() {
                  showMyCars = value ?? false;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collectionGroup('CarDetails').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CupertinoActivityIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No car listings available."));
                }

                var carDocs = snapshot.data!.docs.where((doc) {
                  if (!showMyCars) return true;
                  return doc.reference.parent.parent?.id == currentUserId;
                }).toList();

                return GridView.builder(
                  padding: EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: carDocs.length,
                  itemBuilder: (context, index) {
                    var carData = carDocs[index].data() as Map<String, dynamic>;
                    var isMyCar = carDocs[index].reference.parent.parent?.id ==
                        currentUserId;
                    return _buildCarCard(
                        context, carData, isMyCar, carDocs[index].reference);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarCard(BuildContext context, Map<String, dynamic> carData,
      bool isMyCar, DocumentReference carRef) {
    String priceText = 'Price not available';
    if (carData['1MonthPrice'] != null) {
      priceText = '₹ ${carData['1MonthPrice'].toString()}';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
              builder: (context) => CarDetailsScreen(car: carData)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: CupertinoColors.white,
          boxShadow: [
            BoxShadow(
                color: CupertinoColors.systemGrey.withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    carData['frontImage']?.toString() ?? '',
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                if (isMyCar)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) => EditCars(
                                  carId: carRef.id,
                                  initialData: carData,
                                ),
                              ),
                            );
                          },
                          child: Icon(
                            CupertinoIcons.pencil,
                            color: CupertinoColors.activeBlue,
                          ),
                        ),
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showDeleteConfirmation(carRef),
                          child: Icon(CupertinoIcons.delete,
                              color: CupertinoColors.destructiveRed),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(carData['Model Name']?.toString() ?? 'Model',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(carData['Car Brand']?.toString() ?? 'Brand',
                      style: TextStyle(color: CupertinoColors.systemGrey)),
                  SizedBox(height: 4),
                  Text(priceText,
                      style: TextStyle(color: CupertinoColors.systemGrey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
