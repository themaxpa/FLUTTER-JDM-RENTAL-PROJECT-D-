import 'package:flutter/material.dart';

class AddCars extends StatelessWidget {
  const AddCars({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
          child: Text('Cars',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold))),
    );
  }
}
