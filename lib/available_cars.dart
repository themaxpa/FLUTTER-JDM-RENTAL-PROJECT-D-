import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app/user/book_car.dart';

class AvailableCars extends StatelessWidget {
  const AvailableCars({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: buildAvailableCars(context),
    );
  }
}

Widget buildAvailableCars(BuildContext context) {
  return StreamBuilder<QuerySnapshot>(
    stream:
        FirebaseFirestore.instance.collectionGroup('CarDetails').snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CupertinoActivityIndicator());
      }

      if (snapshot.hasError) {
        return Center(
          child: Text(
            "Error: ${snapshot.error}",
            style: const TextStyle(color: Colors.red),
          ),
        );
      }

      final cars = snapshot.data?.docs ?? [];

      if (cars.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.car_detailed, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                "No cars available at the moment",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return PageView.builder(
        itemCount: cars.length,
        itemBuilder: (context, index) {
          final carData = cars[index].data() as Map<String, dynamic>;
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => CarBookingScreen(
                    car: carData,
                    carId: cars[index].id,
                    vendorId: carData['vendorId'],
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Stack(
                children: [
                  // Background Image with Gradient Overlay
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        Image.network(
                          carData['frontImage'] ?? '',
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[900],
                            child: const Icon(CupertinoIcons.car_detailed,
                                size: 100, color: Colors.white54),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                                Colors.black,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Car Brand Logo
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Row(
                      children: [
                        _buildBrandLogo(carData['Car Brand'] ?? ''),
                      ],
                    ),
                  ),

                  // Car Details
                  Positioned(
                    right: 16,
                    top: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildSpecItem('Mileage (upto)',
                            '${carData['mileage'] ?? '7.69'} kmpl'),
                        const SizedBox(height: 12),
                        _buildSpecItem('Engine (upto)',
                            '${carData['engine'] ?? '6498'} cc'),
                        const SizedBox(height: 12),
                        _buildSpecItem('BHP', '${carData['power'] ?? '770.0'}'),
                        const SizedBox(height: 12),
                        _buildSpecItem(
                            'Transmission', carData['Gearbox'] ?? 'Automatic'),
                        const SizedBox(height: 12),
                        _buildSpecItem('Seats', '${carData['Seats'] ?? '2'}'),
                        const SizedBox(height: 12),
                        _buildSpecItem('Boot Space',
                            '${carData['bootSpace'] ?? '110'}-liters'),
                      ],
                    ),
                  ),

                  // Bottom Content
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NEED A LUXURY CAR ?',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${carData['Car Brand']} ${carData['Model Name']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(index + 1).toString().padLeft(2, '0')}/0${cars.length}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 16,
                              ),
                            ),
                            CupertinoButton(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (context) => CarBookingScreen(
                                      car: carData,
                                      carId: cars[index].id,
                                      vendorId: carData['vendorId'],
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                'BOOK RIDE',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildSpecItem(String label, String value) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.5),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

Widget _buildBrandLogo(String brandName) {
  if (brandName.isEmpty) {
    return const Icon(
      CupertinoIcons.car_detailed,
      color: CupertinoColors.white,
      size: 40,
    );
  }

  // Construct the logo path using the format "Brand + Logo.png"
  final String logoPath =
      'assets/images/logo/${brandName.replaceAll(' ', '')}Logo.png';

  return Container(
    width: 80,
    height: 80,
    decoration: BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Image.asset(
        logoPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(
          CupertinoIcons.car_detailed,
          color: CupertinoColors.white,
          size: 40,
        ),
      ),
    ),
  );
}
