import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart'; // Import the uuid package
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class AddCars extends StatefulWidget {
  const AddCars({super.key});

  @override
  State<AddCars> createState() => _AddCarsState();
}

class _AddCarsState extends State<AddCars> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Map<String, TextEditingController> _controllers = {};
  File? _frontImage;
  File? _backImage;
  File? _sideImage;
  File? _interiorImage1;
  File? _interiorImage2;
  File? _interiorImage3;
  bool _isLoading = false;
  String? _selectedBrand;
  String? _selectedCarType;
  String? _selectedDriveType;
  LatLng? _selectedLocation;
  final MapController _mapController = MapController();
  bool _isLoadingLocation = false;

  // List of car brands with their logos
  final List<Map<String, String>> _carBrands = [
    {'name': 'Toyota', 'logo': 'assets/images/logo/ToyotaLogo.png'},
    {'name': 'Nissan', 'logo': 'assets/images/logo/NissanLogo.png'},
    {'name': 'Subaru', 'logo': 'assets/images/logo/SubaruLogo.png'},
    {'name': 'Honda', 'logo': 'assets/images/logo/HondaLogo.png'},
    {'name': 'Mazda', 'logo': 'assets/images/logo/MazdaLogo.png'},
    {'name': 'Mitsubishi', 'logo': 'assets/images/logo/MitsubishiLogo.png'},
    {'name': 'Suzuki', 'logo': 'assets/images/logo/SuzukiLogo.png'},
    {'name': 'Mitsuoka', 'logo': 'assets/images/logo/MitsuokaLogo.png'},
    {'name': 'Isuzu', 'logo': 'assets/images/logo/IsuzuLogo.png'},
    {'name': 'Hino', 'logo': 'assets/images/logo/HinoLogo.png'},
  ];

  // List of car types with their icons
  final List<Map<String, dynamic>> _carTypes = [
    {
      'name': 'Hatchback',
      'icon': 'assets/images/car_types/hatchback.png',
      'description': 'Compact car with a rear door that opens upward',
    },
    {
      'name': 'Sedan',
      'icon': 'assets/images/car_types/sedan.png',
      'description': 'Passenger car with a three-box configuration',
    },
    {
      'name': 'SUV',
      'icon': 'assets/images/car_types/suv.png',
      'description': 'Sport Utility Vehicle with higher ground clearance',
    },
    {
      'name': 'Truck',
      'icon': 'assets/images/car_types/truck.png',
      'description': 'Large vehicle designed for transporting cargo',
    },
    {
      'name': 'Van',
      'icon': 'assets/images/car_types/van.png',
      'description': 'Box-shaped vehicle for transporting passengers or cargo',
    },
    {
      'name': 'Coupe',
      'icon': 'assets/images/car_types/coupe.png',
      'description': 'Two-door car with a fixed roof',
    },
    {
      'name': 'Convertible',
      'icon': 'assets/images/car_types/convertible.png',
      'description': 'Car with a roof that can be folded or removed',
    },
    {
      'name': 'Wagon',
      'icon': 'assets/images/car_types/wagon.png',
      'description': 'Estate car with extended cargo space',
    },
    {
      'name': 'Pickup',
      'icon': 'assets/images/car_types/pickup.png',
      'description': 'Truck with an open cargo area',
    },
  ];

  // Add this after the car types list
  final List<Map<String, dynamic>> _driveTypes = [
    {
      'name': 'Rear-Wheel Drive (RWD)',
      'icon': CupertinoIcons.car_detailed,
      'description': 'Power is delivered to the rear wheels only',
    },
    {
      'name': 'Front-Wheel Drive (FWD)',
      'icon': CupertinoIcons.car_detailed,
      'description': 'Power is delivered to the front wheels only',
    },
    {
      'name': 'Four-Wheel Drive (4WD)',
      'icon': CupertinoIcons.car_detailed,
      'description':
          'Power is delivered to all four wheels with a transfer case',
    },
    {
      'name': 'All-Wheel Drive (AWD)',
      'icon': CupertinoIcons.car_detailed,
      'description':
          'Power is delivered to all wheels with variable distribution',
    },
  ];

  // Animation controller for smooth transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeControllers();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    for (var field in [
      "Model Name",
      "description",
      "carType",
      "6MonthPrice",
      "1MonthPrice",
      "1DayPrice",
      "Color",
      "drive",
      "maxSpeed",
      "power",
      "Gearbox",
      "Seats",
      "Motor",
      "Speed (0-100)",
      "Location",
      "ELocation",
      "consumption"
    ]) {
      _controllers[field] = TextEditingController();
    }
  }

  void _resetForm() {
    setState(() {
      for (var controller in _controllers.values) {
        controller.clear();
      }
      _selectedBrand = null;
      _selectedCarType = null;
      _selectedDriveType = null;
      _selectedLocation = null;
      _frontImage = null;
      _backImage = null;
      _sideImage = null;
      _interiorImage1 = null;
      _interiorImage2 = null;
      _interiorImage3 = null;
      _mapController.move(const LatLng(35.6762, 139.6503), 13.0);
    });
  }

  Future<void> _pickImage(Function(File) setImage) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        setImage(File(pickedFile.path));
      });
    }
  }

  Future<String?> uploadImageToCloudinary(File imageFile) async {
    try {
      final url = "https://api.cloudinary.com/v1_1/dageosse2/image/upload";
      final request = http.MultipartRequest("POST", Uri.parse(url))
        ..fields['upload_preset'] = 'project-d'
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData);

      return jsonData['secure_url'];
    } catch (e) {
      _showErrorDialog("Image upload failed. Please try again.");
      return null;
    }
  }

  Future<void> _uploadCarDetails() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedBrand == null) {
      _showErrorDialog("Please select a car brand.");
      return;
    }

    if (_selectedLocation == null) {
      _showErrorDialog("Please select a car location on the map.");
      return;
    }

    for (var entry in _controllers.entries) {
      if (entry.value.text.trim().isEmpty) {
        _showErrorDialog("Please fill in all fields before uploading.");
        return;
      }
    }

    if (_frontImage == null || _backImage == null || _sideImage == null) {
      _showErrorDialog("Please upload all required images.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final vendorId = _auth.currentUser?.uid;
      if (vendorId == null) {
        _showErrorDialog("User not authenticated.");
        return;
      }

      // Fetch vendor details
      DocumentSnapshot vendorSnapshot =
          await _firestore.collection('vendors').doc(vendorId).get();

      if (!vendorSnapshot.exists) {
        _showErrorDialog("Vendor details not found.");
        return;
      }

      String vendorName = vendorSnapshot["name"] ?? "Unknown Vendor";
      String vendorLocation = vendorSnapshot["location"] ?? "Unknown Location";

      String? frontImageUrl = await uploadImageToCloudinary(_frontImage!);
      String? backImageUrl = await uploadImageToCloudinary(_backImage!);
      String? sideImageUrl = await uploadImageToCloudinary(_sideImage!);
      String? interiorImage1Url = _interiorImage1 != null
          ? await uploadImageToCloudinary(_interiorImage1!)
          : null;
      String? interiorImage2Url = _interiorImage2 != null
          ? await uploadImageToCloudinary(_interiorImage2!)
          : null;
      String? interiorImage3Url = _interiorImage3 != null
          ? await uploadImageToCloudinary(_interiorImage3!)
          : null;

      if (frontImageUrl == null ||
          backImageUrl == null ||
          sideImageUrl == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Generate a unique carId
      var uuid = Uuid();
      String carId = uuid.v4();

      // Create the car details document
      Map<String, dynamic> carDetails = {
        for (var entry in _controllers.entries) entry.key: entry.value.text,
        "Car Brand": _selectedBrand,
        "Car Type": _selectedCarType,
        "frontImage": frontImageUrl,
        "backImage": backImageUrl,
        "sideImage": sideImageUrl,
        "interiorImage1": interiorImage1Url,
        "interiorImage2": interiorImage2Url,
        "interiorImage3": interiorImage3Url,
        "vendorId": vendorId,
        "vendorName": vendorName,
        "vendorLocation": vendorLocation,
        "status": 'available',
        "createdAt": FieldValue.serverTimestamp(),
        "carId": carId,
        "ELocation":
            GeoPoint(_selectedLocation!.latitude, _selectedLocation!.longitude),
      };

      // Upload to Firestore
      await _firestore
          .collection('vendors')
          .doc(vendorId)
          .collection('CarDetails')
          .doc(carId)
          .set(carDetails);

      setState(() {
        _isLoading = false;
      });

      _resetForm();
      _showSuccessDialog("Car details uploaded successfully.");
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog("Error uploading car details. Please try again.");
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Success"),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showBrandSelector() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.systemGrey5,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text("Cancel"),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: const Text(
                      "Select Car Brand",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text("Done"),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Brand Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _carBrands.length,
                itemBuilder: (context, index) {
                  final brand = _carBrands[index];
                  final isSelected = _selectedBrand == brand['name'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedBrand = brand['name'];
                      });
                    },
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? CupertinoColors.activeBlue.withOpacity(0.1)
                              : CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? CupertinoColors.activeBlue
                                : CupertinoColors.systemGrey4,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              brand['logo']!,
                              height: 40,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                CupertinoIcons.car_detailed,
                                size: 40,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              brand['name']!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? CupertinoColors.activeBlue
                                    : CupertinoColors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCarTypeSelector() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.systemGrey5,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text("Cancel"),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: const Text(
                      "Select Car Type",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text("Done"),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Car Type List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _carTypes.length,
                itemBuilder: (context, index) {
                  final carType = _carTypes[index];
                  final isSelected = _selectedCarType == carType['name'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCarType = carType['name'];
                        _controllers['carType']?.text = carType['name'];
                      });
                      Navigator.pop(context);
                    },
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? CupertinoColors.activeBlue.withOpacity(0.1)
                              : CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? CupertinoColors.activeBlue
                                : CupertinoColors.systemGrey4,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? CupertinoColors.activeBlue
                                    : CupertinoColors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Image.asset(
                                carType['icon'],
                                height: 24,
                                width: 24,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                  CupertinoIcons.car_detailed,
                                  size: 24,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    carType['name'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? CupertinoColors.activeBlue
                                          : CupertinoColors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    carType['description'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          CupertinoColors.systemGrey.darkColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                CupertinoIcons.checkmark_circle_fill,
                                color: CupertinoColors.activeBlue,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDriveTypeSelector() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.systemGrey5,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text("Cancel"),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: const Text(
                      "Select Drive Type",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text("Done"),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Drive Type List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _driveTypes.length,
                itemBuilder: (context, index) {
                  final driveType = _driveTypes[index];
                  final isSelected = _selectedDriveType == driveType['name'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDriveType = driveType['name'];
                        _controllers['drive']?.text = driveType['name'];
                      });
                      Navigator.pop(context);
                    },
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? CupertinoColors.activeBlue.withOpacity(0.1)
                              : CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? CupertinoColors.activeBlue
                                : CupertinoColors.systemGrey4,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? CupertinoColors.activeBlue
                                    : CupertinoColors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                driveType['icon'],
                                color: isSelected
                                    ? CupertinoColors.white
                                    : CupertinoColors.activeBlue,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    driveType['name'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? CupertinoColors.activeBlue
                                          : CupertinoColors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    driveType['description'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          CupertinoColors.systemGrey.darkColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                CupertinoIcons.checkmark_circle_fill,
                                color: CupertinoColors.activeBlue,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: CupertinoColors.activeBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: CupertinoColors.darkBackgroundGray),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: controller,
            placeholder: "Enter $label",
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CupertinoColors.systemGrey4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.car_detailed,
                  color: CupertinoColors.activeBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Car Brand",
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: CupertinoColors.darkBackgroundGray),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _showBrandSelector,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CupertinoColors.systemGrey4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: Row(
                        children: [
                          if (_selectedBrand != null) ...[
                            Image.asset(
                              _carBrands.firstWhere((brand) =>
                                  brand['name'] == _selectedBrand)['logo']!,
                              height: 24,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                CupertinoIcons.car_detailed,
                                size: 24,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            _selectedBrand ?? "Select Car Brand",
                            style: TextStyle(
                              color: _selectedBrand == null
                                  ? CupertinoColors.systemGrey
                                  : CupertinoColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.chevron_down,
                    color: CupertinoColors.systemGrey,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarTypeField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.car_detailed,
                    color: CupertinoColors.activeBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "Car Type",
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: CupertinoColors.darkBackgroundGray),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showCarTypeSelector,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CupertinoColors.systemGrey4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (_selectedCarType != null) ...[
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: CupertinoColors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Image.asset(
                                _carTypes.firstWhere((type) =>
                                    type['name'] == _selectedCarType)['icon'],
                                height: 20,
                                width: 20,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                  CupertinoIcons.car_detailed,
                                  size: 20,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            _selectedCarType ?? "Select Car Type",
                            style: TextStyle(
                              color: _selectedCarType == null
                                  ? CupertinoColors.systemGrey
                                  : CupertinoColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.chevron_down,
                      color: CupertinoColors.systemGrey,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriveTypeField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.car_detailed,
                    color: CupertinoColors.activeBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "Drive Type",
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: CupertinoColors.darkBackgroundGray),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showDriveTypeSelector,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CupertinoColors.systemGrey4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (_selectedDriveType != null) ...[
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: CupertinoColors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _driveTypes.firstWhere((type) =>
                                    type['name'] == _selectedDriveType)['icon'],
                                size: 20,
                                color: CupertinoColors.activeBlue,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            _selectedDriveType ?? "Select Drive Type",
                            style: TextStyle(
                              color: _selectedDriveType == null
                                  ? CupertinoColors.systemGrey
                                  : CupertinoColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.chevron_down,
                      color: CupertinoColors.systemGrey,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(String label, File? image, Function(File) setImage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.camera,
                  color: CupertinoColors.activeBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: CupertinoColors.darkBackgroundGray),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _pickImage(setImage),
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CupertinoColors.systemGrey4),
              ),
              child: image == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            CupertinoIcons.camera,
                            size: 32,
                            color: CupertinoColors.systemGrey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Tap to select image",
                            style: TextStyle(
                              color: CupertinoColors.systemGrey.darkColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        image,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 120,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: CupertinoColors.activeBlue,
        ),
      ),
    );
  }

  Future<void> _showLocationPermissionDialog() {
    return showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text("Location Access Required"),
        content: const Text(
            "This app needs access to location services to show your current location on the map. Would you like to enable location services?"),
        actions: [
          CupertinoDialogAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: const Text("Enable"),
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
            },
          ),
        ],
      ),
    );
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // Test if location services are enabled.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _showLocationPermissionDialog();
        return Future.error('Location services are disabled.');
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          await _showLocationPermissionDialog();
          return Future.error('Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        await _showLocationPermissionDialog();
        return Future.error(
            'Location permissions are permanently denied, we cannot request permissions.');
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      _showErrorDialog('Error getting location: $e');
      return Future.error('Error getting location: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    if (_isLoadingLocation) return;

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final position = await _determinePosition();
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _controllers['ELocation']?.text =
            '${position.latitude},${position.longitude}';
      });

      // Animate to the new location
      _mapController.move(_selectedLocation!, 15.0);
    } catch (e) {
      if (e.toString().contains('Location services are disabled') ||
          e.toString().contains('Location permissions are denied')) {
        // Don't show error dialog as we already showed the permission dialog
        return;
      }
      _showErrorDialog('Error getting current location: $e');
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Widget _buildLocationPicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.location,
                  color: CupertinoColors.activeBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Car Location",
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: CupertinoColors.darkBackgroundGray),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CupertinoColors.systemGrey4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter:
                          _selectedLocation ?? const LatLng(35.6762, 139.6503),
                      initialZoom: 13.0,
                      onTap: (_, point) {
                        setState(() {
                          _selectedLocation = point;
                          _controllers['ELocation']?.text =
                              '${point.latitude},${point.longitude}';
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.app',
                        tileProvider: NetworkTileProvider(),
                      ),
                      if (_selectedLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _selectedLocation!,
                              child: const Icon(
                                CupertinoIcons.location_fill,
                                color: CupertinoColors.activeBlue,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: CupertinoButton(
                      padding: const EdgeInsets.all(8),
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(8),
                      child: _isLoadingLocation
                          ? const CupertinoActivityIndicator()
                          : const Icon(
                              CupertinoIcons.location_fill,
                              color: CupertinoColors.activeBlue,
                            ),
                      onPressed:
                          _isLoadingLocation ? null : _getCurrentLocation,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_selectedLocation != null) ...[
            const SizedBox(height: 8),
            Text(
              "Selected Location: ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}",
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      navigationBar: const CupertinoNavigationBar(
        middle: Text("Add New Car"),
        backgroundColor: CupertinoColors.systemBackground,
        border: null,
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator(radius: 12))
            : FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Material(
                      color: Colors.transparent,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Basic Information Section
                            _buildSectionHeader("Basic Information"),
                            _buildBrandDropdown(),
                            _buildTextField(
                                "Model Name",
                                _controllers["Model Name"]!,
                                CupertinoIcons.car_detailed),
                            _buildCarTypeField(),
                            _buildDriveTypeField(),
                            _buildTextField("Color", _controllers["Color"]!,
                                CupertinoIcons.paintbrush),
                            _buildTextField(
                                "description",
                                _controllers["description"]!,
                                CupertinoIcons.doc_text),

                            // Pricing Section
                            _buildSectionHeader("Pricing"),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                      "1Day",
                                      _controllers["1DayPrice"]!,
                                      CupertinoIcons.money_dollar),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildTextField(
                                      "1Month",
                                      _controllers["1MonthPrice"]!,
                                      CupertinoIcons.money_dollar),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildTextField(
                                      "6Month",
                                      _controllers["6MonthPrice"]!,
                                      CupertinoIcons.money_dollar),
                                ),
                              ],
                            ),

                            // Technical Specifications
                            _buildSectionHeader("Technical Specifications"),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                      "Gearbox",
                                      _controllers["Gearbox"]!,
                                      CupertinoIcons.gear),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildTextField(
                                      "Motor",
                                      _controllers["Motor"]!,
                                      CupertinoIcons.gear),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                      "power",
                                      _controllers["power"]!,
                                      CupertinoIcons.gauge),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildTextField(
                                      "maxSpeed",
                                      _controllers["maxSpeed"]!,
                                      CupertinoIcons.speedometer),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                      "Speed (0-100)",
                                      _controllers["Speed (0-100)"]!,
                                      CupertinoIcons.timer),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildTextField(
                                      "Seats",
                                      _controllers["Seats"]!,
                                      CupertinoIcons.person_2),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                      "consumption",
                                      _controllers["consumption"]!,
                                      CupertinoIcons.gauge),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildTextField(
                                      "Location",
                                      _controllers["Location"]!,
                                      CupertinoIcons.location),
                                ),
                              ],
                            ),

                            // Car Images Section
                            _buildSectionHeader("Car Images"),
                            _buildImagePicker("Car Front View", _frontImage,
                                (img) => _frontImage = img),
                            _buildImagePicker("Car Back View", _backImage,
                                (img) => _backImage = img),
                            _buildImagePicker("Car Side View", _sideImage,
                                (img) => _sideImage = img),

                            // Interior Images Section
                            _buildSectionHeader("Interior Images"),
                            _buildImagePicker(
                                "Interior View 1",
                                _interiorImage1,
                                (img) => _interiorImage1 = img),
                            _buildImagePicker(
                                "Interior View 2",
                                _interiorImage2,
                                (img) => _interiorImage2 = img),
                            _buildImagePicker(
                                "Interior View 3",
                                _interiorImage3,
                                (img) => _interiorImage3 = img),

                            _buildLocationPicker(),

                            const SizedBox(height: 24),

                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: CupertinoButton(
                                    color: CupertinoColors.systemGrey5,
                                    borderRadius: BorderRadius.circular(8),
                                    onPressed: _resetForm,
                                    child: const Text(
                                      "Reset",
                                      style: TextStyle(
                                        color:
                                            CupertinoColors.darkBackgroundGray,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: CupertinoButton(
                                    color: CupertinoColors.activeBlue,
                                    borderRadius: BorderRadius.circular(8),
                                    onPressed: _uploadCarDetails,
                                    child: const Text(
                                      "Upload",
                                      style: TextStyle(
                                        color: CupertinoColors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
