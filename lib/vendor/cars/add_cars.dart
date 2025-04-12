import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart'; // Import the uuid package

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
  bool _isLoading = false;

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
      "Car Brand",
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
      _frontImage = null;
      _backImage = null;
      _sideImage = null;
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

      // Upload car details to Firestore
      await _firestore
          .collection('vendors')
          .doc(vendorId)
          .collection('CarDetails')
          .doc(carId) // Use carId as the document ID
          .set({
        for (var entry in _controllers.entries) entry.key: entry.value.text,
        "frontImage": frontImageUrl,
        "backImage": backImageUrl,
        "sideImage": sideImageUrl,
        "vendorId": vendorId,
        "vendorName": vendorName,
        "vendorLocation": vendorLocation,
        "Status": 'approved',
        "status": 'available',
        "createdAt": FieldValue.serverTimestamp(),
        "carId": carId, // Store the carId in the document
      });

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

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: CupertinoColors.darkBackgroundGray),
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

  Widget _buildImagePicker(String label, File? image, Function(File) setImage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: CupertinoColors.darkBackgroundGray),
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Basic Information Section
                          _buildSectionHeader("Basic Information"),
                          _buildTextField(
                              "Car Brand", _controllers["Car Brand"]!),
                          _buildTextField(
                              "Model Name", _controllers["Model Name"]!),
                          _buildTextField("carType", _controllers["carType"]!),
                          _buildTextField("Color", _controllers["Color"]!),
                          _buildTextField(
                              "description", _controllers["description"]!),

                          // Pricing Section
                          _buildSectionHeader("Pricing"),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                    "1DayPrice", _controllers["1DayPrice"]!),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildTextField("1MonthPrice",
                                    _controllers["1MonthPrice"]!),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildTextField("6MonthPrice",
                                    _controllers["6MonthPrice"]!),
                              ),
                            ],
                          ),

                          // Technical Specifications
                          _buildSectionHeader("Technical Specifications"),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                    "drive", _controllers["drive"]!),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildTextField(
                                    "Gearbox", _controllers["Gearbox"]!),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                    "Motor", _controllers["Motor"]!),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildTextField(
                                    "power", _controllers["power"]!),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                    "maxSpeed", _controllers["maxSpeed"]!),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildTextField("Speed (0-100)",
                                    _controllers["Speed (0-100)"]!),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                    "Seats", _controllers["Seats"]!),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildTextField("consumption",
                                    _controllers["consumption"]!),
                              ),
                            ],
                          ),
                          _buildTextField(
                              "Location", _controllers["Location"]!),

                          // Car Images Section
                          _buildSectionHeader("Car Images"),
                          _buildImagePicker("Car Front View", _frontImage,
                              (img) => _frontImage = img),
                          _buildImagePicker("Car Back View", _backImage,
                              (img) => _backImage = img),
                          _buildImagePicker("Car Side View", _sideImage,
                              (img) => _sideImage = img),

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
                                      color: CupertinoColors.darkBackgroundGray,
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
    );
  }
}
