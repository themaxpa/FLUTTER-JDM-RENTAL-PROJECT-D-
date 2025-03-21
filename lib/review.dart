import 'package:flutter/material.dart';

class ReviewScreen extends StatefulWidget {
  @override
  _ReviewScreenState createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _rating = 0; // Stores the user's rating (0 to 5)
  final TextEditingController _reviewController =
      TextEditingController(); // Controller for the review text

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leave a Review'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How would you rate our app?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            // Star rating widget
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1; // Update the rating
                    });
                  },
                );
              }),
            ),
            SizedBox(height: 20),
            Text(
              'Write your review:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            // Text field for the review
            TextField(
              controller: _reviewController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Tell us about your experience...',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            // Submit button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  _submitReview();
                },
                child: Text('Submit Review'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to handle review submission
  void _submitReview() {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a rating before submitting.')),
      );
      return;
    }

    String reviewText = _reviewController.text.trim();
    if (reviewText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please write a review before submitting.')),
      );
      return;
    }

    // Here, you can send the review data to your backend or save it locally
    print('Rating: $_rating');
    print('Review: $reviewText');

    // Show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Thank you for your review!')),
    );

    // Clear the form
    setState(() {
      _rating = 0;
      _reviewController.clear();
    });
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}
