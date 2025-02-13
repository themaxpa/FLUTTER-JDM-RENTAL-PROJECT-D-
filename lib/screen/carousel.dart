import 'package:flutter/material.dart';
import 'fullscreen.dart';
import 'login.dart';

class PageViewerScreen extends StatelessWidget {
  final List<PageData> pages = [
    PageData(
      image: 'assets/images/ph12.jpg',
      title: 'Always in Control',
      description:
          'Control your car remotely, check current vehicle status and manage charging services at your fingertips with the 7000RPM app.',
    ),
    PageData(
      image: 'assets/images/ph12.jpg',
      title: 'Easy route planning',
      description:
          'Plan your next trip,save POIs and send destination to your vehicle.',
    ),
    PageData(
      image: 'assets/images/loginBG.png',
      title: 'A more personal experience',
      description:
          'Synchronize your personal settings and enjoy a more personal interaction with JDM and your JDm service center',
    ),
    PageData(
      image: 'assets/images/ph2.jpg',
      title: 'App demo',
      description:
          'try the JDM functionality even without owning a JDM vehicle yet.',
    ),
    PageData(
      image: 'assets/images/ph2.jpg',
      title: 'Easy login',
      description:
          'Login to active your driver profile with a simple QR code scan.',
    ),
  ];

  PageViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF20232B),
        centerTitle: true,
        title: Text(
          'App Benefits',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              itemCount: pages.length,
              itemBuilder: (context, index) {
                return Container(
                  color: Color(0xFF20232B),
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Image.asset(
                          pages[index].image,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        ' ${index + 1} of 5 \n ${pages[index].title}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        pages[index].description,
                        style: TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            color: Color(0xFF20232B),
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) {
                            return LoginScreen();
                          },
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                    ),
                    child: Text(
                      'LOGIN OR REGISTER',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) {
                            return FullScreenBackground();
                          },
                        ),
                      );
                    },
                    child: Text(
                      'CLOSE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PageData {
  final String image;
  final String title;
  final String description;

  PageData({
    required this.image,
    required this.title,
    required this.description,
  });
}
