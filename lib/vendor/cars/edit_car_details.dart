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

  String? _frontImageUrl;
  String? _backImageUrl;
  String? _sideImageUrl;

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
      "12MonthPrice",
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
      "Location"
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Edit Car Details'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  for (var entry in _controllers.entries)
                    CupertinoTextField(
                      controller: entry.value,
                      placeholder: entry.key,
                    ),
                  const SizedBox(height: 20),
                  CupertinoButton.filled(
                    child: const Text('Update Front Image'),
                    onPressed: () => _pickImage((file) => _frontImage = file,
                        (url) => _frontImageUrl = url),
                  ),
                  CupertinoButton.filled(
                    child: const Text('Update Back Image'),
                    onPressed: () => _pickImage((file) => _backImage = file,
                        (url) => _backImageUrl = url),
                  ),
                  CupertinoButton.filled(
                    child: const Text('Update Side Image'),
                    onPressed: () => _pickImage((file) => _sideImage = file,
                        (url) => _sideImageUrl = url),
                  ),
                  const SizedBox(height: 20),
                  CupertinoButton.filled(
                    child: const Text('Submit'),
                    onPressed: _uploadCarDetails,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
