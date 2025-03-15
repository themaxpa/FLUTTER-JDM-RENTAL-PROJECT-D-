import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CarDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> car;

  const CarDetailsScreen({Key? key, required this.car}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          car['Model Name'] ?? 'Car Details',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 16 : 20,
          ),
        ),
        backgroundColor: CupertinoColors.systemGrey6,
      ),
      child: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: screenHeight * 0.3,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        buildImageContainer(car['frontImage'], screenWidth),
                        buildImageContainer(car['backImage'], screenWidth),
                        buildImageContainer(car['sideImage'], screenWidth),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Material(
                    color: CupertinoColors.systemGroupedBackground,
                    child: Text(
                      'SPECIFICATIONS',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Material(
                      color: Colors.white,
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          buildInfoCard('Brand', car['Car Brand']),
                          buildInfoCard('Model', car['Model Name']),
                          buildInfoCard('Color', car['Color']),
                          buildInfoCard(
                              '1 Month Price', '\$${car['1MonthPrice'] ?? 0}'),
                          buildInfoCard(
                              '6 Month Price', '\$${car['6MonthPrice'] ?? 0}'),
                          buildInfoCard('12 Month Price',
                              '\$${car['12MonthPrice'] ?? 0}'),
                          buildInfoCard('Type', car['carType']),
                          buildInfoCard('Gearbox', car['Gearbox']),
                          buildInfoCard('Location', car['Location']),
                          buildInfoCard('Motor', car['Motor']),
                          buildInfoCard('Seats', car['Seats']),
                          buildInfoCard('Max Speed', car['maxSpeed']),
                          buildInfoCard('Drive', car['drive']),
                          buildInfoCard('Power', car['power']),
                          buildInfoCard('Speed (0-100)', car['Speed (0-100)']),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildImageContainer(String? imageUrl, double screenWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        height: screenWidth * 0.5,
        width: screenWidth * 0.7,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.network(
            imageUrl ?? '',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.broken_image,
              size: 100,
              color: Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInfoCard(String title, String? value) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value ?? 'Unknown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
