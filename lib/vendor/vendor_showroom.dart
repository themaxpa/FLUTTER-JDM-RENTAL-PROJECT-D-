import 'package:flutter/material.dart';
import 'package:flutter_social_button/flutter_social_button.dart';

class SellerShowroom extends StatelessWidget {
  const SellerShowroom({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40),
              _buildTopBar(),
              SizedBox(height: 20),
              _buildMainCard(),
              SizedBox(height: 20),
              _buildModerationSection(),
              SizedBox(height: 20),
              _buildReviewsSection(),
              SizedBox(height: 20),
              _buildSocialLinks(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Icon(Icons.star, color: Colors.white),
                SizedBox(width: 10),
                Text("Home",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                SizedBox(width: 20),
                Text("About",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                SizedBox(width: 20),
                Text("Contacts",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Supplier center",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 5),
          Text("With artificial intelligence technology"),
          SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child:
                Image.asset('assets/images/ToyotaLogo.png', fit: BoxFit.cover),
          ),
        ],
      ),
    );
  }

  Widget _buildModerationSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.shield, color: Colors.white),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Manual moderation\nDon't worry about security, moderators check every transaction. Everything is transparent",
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.white),
              SizedBox(width: 10),
              Text("Reviews", style: TextStyle(color: Colors.white)),
            ],
          ),
          Text("4.8/5", style: TextStyle(color: Colors.white, fontSize: 20)),
        ],
      ),
    );
  }

  Widget _buildSocialLinks() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Text("INSTAGRAM", style: TextStyle(color: Colors.white)),
          SizedBox(width: 10),
          Text("//", style: TextStyle(color: Colors.white)),
          SizedBox(width: 10),
          Text("FACEBOOK", style: TextStyle(color: Colors.white)),
          SizedBox(width: 10),
          Text("//", style: TextStyle(color: Colors.white)),
          SizedBox(width: 10),
          Text("TWITTER", style: TextStyle(color: Colors.white)),
          SizedBox(width: 10),
          Text("//", style: TextStyle(color: Colors.white)),
          SizedBox(width: 10),
          Text("TELEGRAM", style: TextStyle(color: Colors.white)),
          SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text("Go to suppliers"),
          )
        ],
      ),
    );
  }
}
