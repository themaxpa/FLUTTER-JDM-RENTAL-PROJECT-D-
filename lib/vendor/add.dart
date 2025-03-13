import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateAdScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Car Listings")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collectionGroup('CarDetails').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("Firestore Error: ${snapshot.error}");
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No car listings available."));
          }

          var carDocs = snapshot.data!.docs;

          return ListView.separated(
            padding: EdgeInsets.all(16),
            itemCount: carDocs.length,
            separatorBuilder: (_, __) => SizedBox(height: 16),
            itemBuilder: (context, index) {
              var carData = carDocs[index].data() as Map<String, dynamic>;
              return _buildCarCard(carData);
            },
          );
        },
      ),
    );
  }

  Widget _buildCarCard(Map<String, dynamic> carData) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCarImages(carData),
            SizedBox(height: 10),
            _buildCarDetails(carData),
          ],
        ),
      ),
    );
  }

  Widget _buildCarImages(Map<String, dynamic> carData) {
    List<String?> images = [
      carData['frontImage'],
      carData['sideImage'],
      carData['backImage']
    ];

    if (images.every((img) => img == null)) return SizedBox(); // No images case

    return Row(
      children: images.map((imageUrl) => _buildCarImage(imageUrl)).toList(),
    );
  }

  Widget _buildCarDetails(Map<String, dynamic> carData) {
    List<Map<String, dynamic>> details = [
      {"label": "Model Name", "value": carData["Model Name"]},
      {"label": "Car Brand", "value": carData["Car Brand"]},
      {"label": "Color", "value": carData["Color"]},
      {"label": "Seats", "value": carData["Seats"]},
      {"label": "Gearbox", "value": carData["Gearbox"]},
      {"label": "Motor", "value": carData["Motor"]},
      {"label": "Speed (0-100)", "value": carData["Speed (0-100)"]},
      {"label": "Location", "value": carData["Location"]},
      {"label": "1 Month Price", "value": carData["1 Month Price"]},
      {"label": "6 Month Price", "value": carData["6 Month Price"]},
      {"label": "12 Month Price", "value": carData["12 Month Price"]},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: details
          .map((detail) => _buildCarDetail(detail["label"], detail["value"]))
          .toList(),
    );
  }

  Widget _buildCarDetail(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text("$label: ", style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value?.toString() ?? "N/A")),
        ],
      ),
    );
  }

  Widget _buildCarImage(String? imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: imageUrl != null
          ? Image.network(imageUrl, width: 100, height: 70, fit: BoxFit.cover)
          : Container(
              width: 100,
              height: 70,
              color: Colors.grey[300],
              child: Icon(Icons.image, color: Colors.grey[600]),
            ),
    );
  }
}
