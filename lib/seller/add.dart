import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CreateAdScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          // ✅ Fix: Allows scrolling to prevent overflow
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: AssetImage("assets/images/ph2.jpg"),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: FloatingActionButton(
                        onPressed: () {},
                        mini: true,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.camera_alt, color: Colors.black),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                _buildInputField("BMW 116", "116d Sport Line"),
                _buildInputField("Final Price", "116d Sport Line"),
                _buildInputField("Power", "85 KW (116)"),
                _buildInputField("Mileage", "300.000 Km"),
                _buildInputField("First Registration", "10/01/2025"),
                SizedBox(height: 10),
                ExpansionTile(
                  collapsedBackgroundColor: Colors.grey[900],
                  title: Text("Vehicle Data",
                      style: TextStyle(color: Colors.white)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text("Additional vehicle details go here...",
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                // ✅ Fix: Add extra space to avoid bottom overflow
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.yellow,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            minimumSize: Size(double.infinity, 50),
          ),
          onPressed: () {},
          child: Text("Publish ad",
              style: TextStyle(color: Colors.black, fontSize: 18)),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey, fontSize: 14)),
          SizedBox(height: 5),
          Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(value,
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
