import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AllCarsScreen extends StatefulWidget {
  const AllCarsScreen({Key? key}) : super(key: key);

  @override
  State<AllCarsScreen> createState() => _AllCarsScreenState();
}

class _AllCarsScreenState extends State<AllCarsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _showExpensiveCarsOnly = false;
  String? _expandedCarId;

  Future<void> _deleteCar(
      BuildContext context, DocumentReference carRef) async {
    try {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Delete Car'),
          content: const Text('Are you sure you want to delete this car?'),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            CupertinoDialogAction(
              child: const Text('Delete',
                  style: TextStyle(color: CupertinoColors.destructiveRed)),
              onPressed: () async {
                try {
                  await carRef.delete();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    _showSnackBar(context, 'Car deleted successfully');
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    _showSnackBar(
                        context, 'Failed to delete car: ${e.toString()}');
                  }
                }
              },
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Error showing delete dialog: ${e.toString()}');
      }
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('All Cars'),
        trailing: CupertinoSwitch(
          value: _showExpensiveCarsOnly,
          onChanged: (value) {
            setState(() {
              _showExpensiveCarsOnly = value;
            });
          },
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
              ),
            ),
            Expanded(child: _buildVendorsStream()),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorsStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('vendors').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CupertinoActivityIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorWidget('Failed to load vendors: ${snapshot.error}');
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No vendors available');
        }

        return _buildVendorsList(snapshot.data!.docs);
      },
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.exclamationmark_triangle, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: CupertinoColors.destructiveRed),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.car_detailed, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: CupertinoColors.secondaryLabel),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorsList(List<QueryDocumentSnapshot> vendorDocs) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: vendorDocs.length,
      itemBuilder: (context, vendorIndex) {
        final vendorRef = vendorDocs[vendorIndex].reference;
        return _buildVendorCarsStream(vendorRef);
      },
    );
  }

  Widget _buildVendorCarsStream(DocumentReference vendorRef) {
    return StreamBuilder<QuerySnapshot>(
      stream: vendorRef.collection('CarDetails').snapshots(),
      builder: (context, carSnapshot) {
        if (carSnapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (carSnapshot.hasError) {
          if (kDebugMode) {
            print('Error loading cars: ${carSnapshot.error}');
          }
          return const SizedBox.shrink();
        }

        if (!carSnapshot.hasData || carSnapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        // Filter cars based on price if toggle is on
        final cars = carSnapshot.data!.docs.where((carDoc) {
          if (!_showExpensiveCarsOnly) return true;
          final carData = carDoc.data() as Map<String, dynamic>;
          final price =
              double.tryParse(carData['1DayPrice']?.toString() ?? '0') ?? 0;
          return price > 2000; // Adjust this threshold as needed
        }).toList();

        return _buildCarsList(cars);
      },
    );
  }

  Widget _buildCarsList(List<QueryDocumentSnapshot> carDocs) {
    return Column(
      children: carDocs.map((carDoc) {
        try {
          final carData = carDoc.data() as Map<String, dynamic>;
          return _buildCarCard(carDoc.reference, carData);
        } catch (e) {
          if (kDebugMode) {
            print('Error building car tile: $e');
          }
          return const SizedBox.shrink();
        }
      }).toList(),
    );
  }

  Widget _buildCarCard(DocumentReference carRef, Map<String, dynamic> carData) {
    final isExpanded = _expandedCarId == carRef.id;
    final price = carData['Price']?.toString() ?? 'N/A';
    final imageUrl = carData['frontImage']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _expandedCarId = isExpanded ? null : carRef.id;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Material(
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      carData['Model Name']?.toString() ?? 'Unknown Model',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    _buildDeleteButton(carRef),
                  ],
                ),
                const SizedBox(height: 12),
                if (imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 150,
                          color: CupertinoColors.lightBackgroundGray,
                          child:
                              const Icon(CupertinoIcons.car_detailed, size: 40),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      carData['Car Brand']?.toString() ?? 'Unknown Brand',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      'AED $price / Day',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'in process...',
                  style: TextStyle(color: Colors.orange),
                ),
                if (isExpanded) ...[
                  const SizedBox(height: 16),
                  _buildDetailRow('Description', carData['description']),
                  _buildDetailRow('Car Type', carData['carType']),
                  _buildDetailRow('6 Month Price', carData['6MonthPrice']),
                  _buildDetailRow('1 Month Price', carData['1MonthPrice']),
                  _buildDetailRow('1 Day Price', carData['1DayPrice']),
                  _buildDetailRow('Color', carData['Color']),
                  _buildDetailRow('Drive', carData['drive']),
                  _buildDetailRow('Max Speed', carData['maxSpeed']),
                  _buildDetailRow('Power', carData['power']),
                  _buildDetailRow('Gearbox', carData['Gearbox']),
                  _buildDetailRow('Seats', carData['Seats']),
                  _buildDetailRow('Motor', carData['Motor']),
                  _buildDetailRow('Speed (0-100)', carData['Speed (0-100)']),
                  _buildDetailRow('Location', carData['Location']),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: const TextStyle(color: CupertinoColors.label),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(DocumentReference carRef) {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () => _deleteCar(context, carRef),
          child: const Icon(
            CupertinoIcons.delete,
            color: CupertinoColors.destructiveRed,
          ),
        );
      },
    );
  }
}
