import 'dart:ui';
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
      navigationBar: CupertinoNavigationBar(
        middle: Text('Available Cars'),
        backgroundColor: CupertinoColors.systemBackground.withOpacity(0.8),
        border: null,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.systemGrey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CupertinoSlidingSegmentedControl<bool>(
                        thumbColor: CupertinoColors.activeBlue,
                        backgroundColor: CupertinoColors.systemGrey6,
                        children: {
                          false: Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            child: Text(
                              'All Cars',
                              style: TextStyle(
                                color: !showMyCars
                                    ? CupertinoColors.white
                                    : CupertinoColors.black,
                              ),
                            ),
                          ),
                          true: Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            child: Text(
                              'My Cars',
                              style: TextStyle(
                                color: showMyCars
                                    ? CupertinoColors.white
                                    : CupertinoColors.black,
                              ),
                            ),
                          ),
                        },
                        groupValue: showMyCars,
                        onValueChanged: (bool? value) {
                          setState(() {
                            showMyCars = value ?? false;
                          });
                        },
                      ),
                    ),
                  ),
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

                    return ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: carDocs.length,
                      itemBuilder: (context, index) {
                        var carData =
                            carDocs[index].data() as Map<String, dynamic>;
                        var isMyCar =
                            carDocs[index].reference.parent.parent?.id ==
                                currentUserId;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildCarCard(context, carData, isMyCar,
                              carDocs[index].reference),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarCard(BuildContext context, Map<String, dynamic> carData,
      bool isMyCar, DocumentReference carRef) {
    String rentalType = carData['rentalType'] ?? 'Weekly';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => CarDetailsScreen(car: carData),
          ),
        );
      },
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: CupertinoColors.systemBackground.withOpacity(0.7),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Image with Gradient
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image:
                          NetworkImage(carData['frontImage']?.toString() ?? ''),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Gradient Overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        CupertinoColors.black.withOpacity(0.7),
                      ],
                      stops: [0.5, 1.0],
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rental Type Badge
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: CupertinoColors.activeBlue.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          rentalType,
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Spacer(),
                      Text(
                        carData['Car Brand']?.toString() ?? 'Brand',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        carData['Model Name']?.toString() ?? 'Model',
                        style: TextStyle(
                          color: CupertinoColors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'per ${rentalType.toLowerCase()}',
                        style: TextStyle(
                          color: CupertinoColors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Edit/Delete Buttons for owner
                if (isMyCar)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Row(
                          children: [
                            _buildIconButton(
                              CupertinoIcons.pencil,
                              () {
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
                            ),
                            SizedBox(width: 8),
                            _buildIconButton(
                              CupertinoIcons.delete,
                              () => _showDeleteConfirmation(carRef),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: CupertinoColors.white,
          size: 20,
        ),
      ),
    );
  }
}
