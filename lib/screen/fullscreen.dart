import 'package:flutter/material.dart';
import 'carousel.dart';
import 'login.dart';

class FullScreenBackground extends StatelessWidget {
  const FullScreenBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/fiat_0.png',
                      height: 80,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "PROJECT D",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildButtonSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
      child: Column(
        children: [
          _buildAnimatedButton(
            context,
            text: "LOGIN OR REGISTER",
            page: LoginScreen(),
          ),
          SizedBox(height: 10),
          _buildAnimatedButton(
            context,
            text: "DISCOVER APP BENEFITS",
            page: PageViewerScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedButton(BuildContext context,
      {required String text, required Widget page}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(_createSlideTransition(page));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Route _createSlideTransition(Widget page) {
    return PageRouteBuilder(
      transitionDuration: Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = Offset(1.0, 0.0);
        var end = Offset.zero;
        var curve = Curves.easeInOut;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }
}
