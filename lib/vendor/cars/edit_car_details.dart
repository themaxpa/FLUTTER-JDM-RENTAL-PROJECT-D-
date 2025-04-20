import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditCars extends StatefulWidget {
  final String? carId;
  final Map<String, dynamic>? initialData;

  const EditCars({this.carId, this.initialData, Key? key}) : super(key: key);

  @override
  State<EditCars> createState() => _EditCarsState();
}

class _EditCarsState extends State<EditCars> {
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

  String? _frontImageUrl;
  String? _backImageUrl;
  String? _sideImageUrl;
  String? _interiorImage1Url;
  String? _interiorImage2Url;
  String? _interiorImage3Url;

  final String cloudinaryUrl =
      'https://api.cloudinary.com/v1_1/dageosse2/image/upload';
  final String uploadPreset = 'project-d';

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _populateExistingData();
  }

  void _initializeControllers() {
    for (var field in [
      "Model Name",
      "Car Brand",
      "description",
      "carType",
      "1DayPrice",
      "6MonthPrice",
      "1MonthPrice",
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

  void _populateExistingData() {
    if (widget.initialData != null) {
      for (var key in _controllers.keys) {
        _controllers[key]?.text = widget.initialData![key] ?? '';
      }
      _frontImageUrl = widget.initialData!["frontImage"];
      _backImageUrl = widget.initialData!["backImage"];
      _sideImageUrl = widget.initialData!["sideImage"];
      _interiorImage1Url = widget.initialData!["interiorImage1"];
      _interiorImage2Url = widget.initialData!["interiorImage2"];
      _interiorImage3Url = widget.initialData!["interiorImage3"];
    }
  }

  Future<String?> _uploadImageToCloudinary(File image) async {
    final request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl))
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', image.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final data = json.decode(responseData);
      return data['secure_url'];
    } else {
      return null;
    }
  }

  Future<void> _pickImage(
      Function(File) setImage, Function(String) setUrl) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final url = await _uploadImageToCloudinary(file);
      if (url != null) {
        setState(() {
          setImage(file);
          setUrl(url);
        });
      }
    }
  }

  Future<void> _uploadCarDetails() async {
    if (!_formKey.currentState!.validate()) return;

    final vendorId = _auth.currentUser?.uid;
    if (vendorId == null) {
      _showErrorDialog("User not authenticated.");
      return;
    }

    try {
      Map<String, dynamic> carData = {
        for (var entry in _controllers.entries) entry.key: entry.value.text,
        "frontImage": _frontImageUrl,
        "backImage": _backImageUrl,
        "sideImage": _sideImageUrl,
        "interiorImage1": _interiorImage1Url,
        "interiorImage2": _interiorImage2Url,
        "interiorImage3": _interiorImage3Url,
        "updatedAt": FieldValue.serverTimestamp(),
      };

      if (widget.carId != null) {
        await _firestore
            .collection('vendors')
            .doc(vendorId)
            .collection('CarDetails')
            .doc(widget.carId)
            .update(carData);
        _showSuccessDialog("Car details updated successfully.");
      } else {
        carData['createdAt'] = FieldValue.serverTimestamp();
        await _firestore
            .collection('vendors')
            .doc(vendorId)
            .collection('CarDetails')
            .add(carData);
        _showSuccessDialog("Car details uploaded successfully.");
      }
    } catch (e) {
      _showErrorDialog("Error uploading car details. Please try again.");
    }
  }

  void _showSuccessDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text("Success"),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text("OK"),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text("OK"),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  }

  Widget _buildImageSection(String title, String? imageUrl, Function() onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(12),
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null
                  ? const Center(
                      child: Icon(
                        CupertinoIcons.camera,
                        size: 40,
                        color: CupertinoColors.systemGrey,
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.carId != null ? 'Edit Car Details' : 'Add New Car'),
        backgroundColor: CupertinoColors.systemBackground.withOpacity(0.8),
        border: null,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Information Section
                  Material(
                    color: Colors.transparent,
                    child: const Text(
                      'Basic Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBackground,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.systemGrey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CupertinoTextField(
                          controller: _controllers['Car Brand'],
                          placeholder: 'Car Brand',
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: CupertinoColors.systemGrey4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CupertinoTextField(
                          controller: _controllers['Model Name'],
                          placeholder: 'Model Name',
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: CupertinoColors.systemGrey4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CupertinoTextField(
                          controller: _controllers['description'],
                          placeholder: 'Description',
                          maxLines: 3,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: CupertinoColors.systemGrey4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Pricing Section
                  Material(
                    color: Colors.transparent,
                    child: const Text(
                      'Pricing',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBackground,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.systemGrey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CupertinoTextField(
                          controller: _controllers['1MonthPrice'],
                          placeholder: '1 Month Price',
                          keyboardType: TextInputType.number,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: CupertinoColors.systemGrey4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CupertinoTextField(
                          controller: _controllers['6MonthPrice'],
                          placeholder: '6 Months Price',
                          keyboardType: TextInputType.number,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: CupertinoColors.systemGrey4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CupertinoTextField(
                          controller: _controllers['1DayPrice'],
                          placeholder: '1 Day Price',
                          keyboardType: TextInputType.number,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: CupertinoColors.systemGrey4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Technical Specifications Section
                  Material(
                    color: Colors.transparent,
                    child: const Text(
                      'Technical Specifications',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBackground,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.systemGrey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CupertinoTextField(
                          controller: _controllers['carType'],
                          placeholder: 'Car Type',
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: CupertinoColors.systemGrey4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CupertinoTextField(
                          controller: _controllers['Color'],
                          placeholder: 'Color',
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: CupertinoColors.systemGrey4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CupertinoTextField(
                          controller: _controllers['drive'],
                          placeholder: 'Drive Type',
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: CupertinoColors.systemGrey4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CupertinoTextField(
                          controller: _controllers['Gearbox'],
                          placeholder: 'Gearbox',
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: CupertinoColors.systemGrey4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Performance Section
                  Material(
                    color: Colors.transparent,
                    child: const Text(
                      'Performance',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBackground,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.systemGrey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CupertinoTextField(
                          controller: _controllers['maxSpeed'],
                          placeholder: 'Max Speed',
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: CupertinoColors.systemGrey4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CupertinoTextField(
                          controller: _controllers['power'],
                          placeholder: 'Power (HP)',
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: CupertinoColors.systemGrey4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CupertinoTextField(
                          controller: _controllers['Motor'],
                          placeholder: 'Motor',
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: CupertinoColors.systemGrey4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CupertinoTextField(
                          controller: _controllers['consumption'],
                          placeholder: 'Fuel Consumption kmpl L/100km',
                          keyboardType: TextInputType.text,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: CupertinoColors.systemGrey4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CupertinoTextField(
                          controller: _controllers['Speed (0-100)'],
                          placeholder: '0-100 km/h Time',
                          keyboardType: TextInputType.text,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: CupertinoColors.systemGrey4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Images Section
                  Material(
                    color: Colors.transparent,
                    child: const Text(
                      'Car Images',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBackground,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.systemGrey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Column(
                        children: [
                          _buildImageSection(
                            'Front View',
                            _frontImageUrl,
                            () => _pickImage(
                              (file) => _frontImage = file,
                              (url) => _frontImageUrl = url,
                            ),
                          ),
                          _buildImageSection(
                            'Back View',
                            _backImageUrl,
                            () => _pickImage(
                              (file) => _backImage = file,
                              (url) => _backImageUrl = url,
                            ),
                          ),
                          _buildImageSection(
                            'Side View',
                            _sideImageUrl,
                            () => _pickImage(
                              (file) => _sideImage = file,
                              (url) => _sideImageUrl = url,
                            ),
                          ),
                          _buildImageSection(
                            'Other Image 1',
                            _interiorImage1Url,
                            () => _pickImage(
                              (file) => _interiorImage1 = file,
                              (url) => _interiorImage1Url = url,
                            ),
                          ),
                          _buildImageSection(
                            'Other Image 2',
                            _interiorImage2Url,
                            () => _pickImage(
                              (file) => _interiorImage2 = file,
                              (url) => _interiorImage2Url = url,
                            ),
                          ),
                          _buildImageSection(
                            'Other Image 3',
                            _interiorImage3Url,
                            () => _pickImage(
                              (file) => _interiorImage3 = file,
                              (url) => _interiorImage3Url = url,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      borderRadius: BorderRadius.circular(12),
                      child: Text(
                        widget.carId != null
                            ? 'Update Car Details'
                            : 'Add New Car',
                        style: const TextStyle(fontSize: 16),
                      ),
                      onPressed: _uploadCarDetails,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
