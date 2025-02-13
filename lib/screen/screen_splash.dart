import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'fullscreen.dart';

// const SAVE_KEY_NAME ='UserLoggedIn';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => FullScreenBackground()));
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background color
      body: Stack(children: [
        // Fullscreen Background Image
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/B.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Text in the Top Left Corner
        // Positioned(
        //   top: 50,
        //   left: 20,
        //   child: Text(
        //     'PROJECT D',
        //     style: TextStyle(
        //       color: Colors.white,
        //       fontSize: 24,
        //       fontWeight: FontWeight.bold,
        //       shadows: [
        //         Shadow(
        //           offset: Offset(2, 2),
        //           blurRadius: 4.0,
        //           color: Colors.black,
        //         ),
        //       ],
        //     ),
        //   ),
        // ),

        // Buttons at the Bottom (Stacked Vertically)
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 10,
                ), // Space between buttons
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Text(
                    'Developed by themaxpa',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
      ]),
    );
  }
}
