import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class CarDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> car;

  const CarDetailsScreen({Key? key, required this.car}) : super(key: key);

  @override
  State<CarDetailsScreen> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreen> {
  int _currentImageIndex = 0;
  Timer? _timer;
  final List<String> _imageUrls = [];

  @override
  void initState() {
    super.initState();
    _initializeImages();
    _startImageTimer();
  }

  void _initializeImages() {
    if (widget.car['frontImage'] != null) {
      _imageUrls.add(widget.car['frontImage']);
    }
    if (widget.car['backImage'] != null) {
      _imageUrls.add(widget.car['backImage']);
    }
    if (widget.car['sideImage'] != null) {
      _imageUrls.add(widget.car['sideImage']);
    }
  }

  void _startImageTimer() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_imageUrls.isNotEmpty) {
        setState(() {
          _currentImageIndex = (_currentImageIndex + 1) % _imageUrls.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topHeight =
        screenHeight * 0.45; // 45% of screen height for top section

    return CupertinoPageScaffold(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          // Background Image Carousel
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topHeight,
            child: Stack(
              children: [
                // Image with BoxFit.cover to fill the space
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  child: _imageUrls.isNotEmpty
                      ? Image.network(
                          _imageUrls[_currentImageIndex],
                          key: ValueKey<int>(_currentImageIndex),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: Colors.grey[900],
                            child: const Icon(
                              CupertinoIcons.car_fill,
                              size: 100,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey[900],
                          child: const Icon(
                            CupertinoIcons.car_fill,
                            size: 100,
                            color: Colors.grey,
                          ),
                        ),
                ),
                // Dark gradient overlay at the bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: topHeight * 0.4,
                  // 40% of the image height
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                          Colors.black.withOpacity(0.9),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          CustomScrollView(
            slivers: [
              // Top Section with Navigation and Image Indicators
              SliverToBoxAdapter(
                child: Container(
                  height: topHeight,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 16,
                    right: 16,
                  ),
                  child: Column(
                    children: [
                      // Navigation Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.back,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Image Indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _imageUrls.asMap().entries.map((entry) {
                          return Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == entry.key
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              // Car Details Section
              SliverToBoxAdapter(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Brand name and logo row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.car['Car Brand'] ?? 'Brand',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    widget.car['Model Name'] ?? 'Model',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              // Brand logo positioned at the end
                              SizedBox(
                                width: 60,
                                height: 60,
                                child: _buildBrandLogo(
                                    widget.car['Car Brand'] ?? ''),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Price information
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '₹${widget.car['1MonthPrice'] ?? '0'}',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                TextSpan(
                                  text: ' per month',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Specifications list
                          _buildSpecificationItem(
                            'Maximum Power',
                            '${widget.car['power'] ?? '0'} hp',
                            Icons.speed,
                          ),
                          _buildSpecificationItem(
                            'Top Speed',
                            '${widget.car['maxSpeed'] ?? '0'} mph',
                            Icons.speed_outlined,
                          ),
                          _buildSpecificationItem(
                            'Consumption',
                            '${widget.car['consumption'] ?? '0'} L/100km',
                            Icons.local_gas_station,
                          ),
                          _buildSpecificationItem(
                            'Acceleration\n0-100 Km/H',
                            '${widget.car['Speed (0-100)'] ?? '0'} sec',
                            Icons.timer,
                          ),
                          _buildSpecificationItem(
                            'Body Type',
                            widget.car['carType'] ?? '-',
                            Icons.car_rental,
                          ),
                          _buildSpecificationItem(
                            'Gearbox',
                            widget.car['Gearbox'] ?? '-',
                            Icons.settings,
                          ),
                          _buildSpecificationItem(
                            'Seats',
                            '${widget.car['Seats'] ?? '0'} seats',
                            Icons.event_seat,
                          ),
                          _buildSpecificationItem(
                            'Drive Type',
                            widget.car['drive'] ?? '-',
                            Icons.drive_eta,
                          ),
                          _buildSpecificationItem(
                            'Motor',
                            widget.car['Motor'] ?? '-',
                            Icons.engineering,
                          ),
                          _buildSpecificationItem(
                            'Color',
                            widget.car['Color'] ?? '-',
                            Icons.palette,
                          ),
                          _buildSpecificationItem(
                            'Location',
                            widget.car['Location'] ?? '-',
                            Icons.location_on,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificationItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.black,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandLogo(String brandName) {
    // Map of brand names to their logo asset paths
    final Map<String, String> brandLogos = {
      'Toyota': 'assets/images/logo/ToyotaLogo.png',
      'Nissan': 'assets/images/logo/NissanLogo.png',
      'Subaru': 'assets/images/logo/SubaruLogo.png',
      'Bugatti': 'assets/brands/bugatti.png',
      'Cadillac': 'assets/brands/cadillac.png',
      'Ferrari': 'assets/brands/ferrari.png',
      'Lamborghini': 'assets/brands/lamborghini.png',
      'Mercedes': 'assets/brands/mercedes.png',
      'Porsche': 'assets/brands/porsche.png',
      'Rolls Royce': 'assets/brands/rolls-royce.png',
      // Add more brands as needed
    };

    // Get the logo path for the brand, or use a default icon if not found
    final String? logoPath = brandLogos[brandName];

    if (logoPath != null) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset(
          logoPath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(
            CupertinoIcons.car_detailed,
            color: Colors.grey,
          ),
        ),
      );
    } else {
      // Default icon if no logo is found
      return const Icon(
        CupertinoIcons.car_detailed,
        color: Colors.grey,
      );
    }
  }
}
