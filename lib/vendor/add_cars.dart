import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddCars extends StatefulWidget {
  const AddCars({super.key});

  @override
  State<AddCars> createState() => _AddCarsState();
}

class _AddCarsState extends State<AddCars> {
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Map<String, TextEditingController> _controllers = {};
  File? _frontImage;
  File? _backImage;
  File? _sideImage;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (var field in [
      "Model Name",
      "Car Brand",
      "12 Month Price",
      "6 Month Price",
      "1 Month Price",
      "Color",
      "Gearbox",
      "Seats",
      "Motor",
      "Speed (0-100)",
      "Location"
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

    // Validate all text fields
    for (var entry in _controllers.entries) {
      if (entry.value.text.trim().isEmpty) {
        _showErrorDialog("Please fill in all fields before uploading.");
        return;
      }
    }

    // Ensure all images are uploaded
    if (_frontImage == null || _backImage == null || _sideImage == null) {
      _showErrorDialog("Please upload all required images.");
      return;
    }

    try {
      final vendorId = _auth.currentUser?.uid;
      if (vendorId == null) {
        _showErrorDialog("User not authenticated.");
        return;
      }

      // Upload images to Cloudinary
      String? frontImageUrl = await uploadImageToCloudinary(_frontImage!);
      String? backImageUrl = await uploadImageToCloudinary(_backImage!);
      String? sideImageUrl = await uploadImageToCloudinary(_sideImage!);

      if (frontImageUrl == null ||
          backImageUrl == null ||
          sideImageUrl == null) {
        return;
      }

      // Upload car details to Firestore
      await _firestore
          .collection('vendors')
          .doc(vendorId)
          .collection('CarDetails')
          .add({
        for (var entry in _controllers.entries) entry.key: entry.value.text,
        "frontImage": frontImageUrl,
        "backImage": backImageUrl,
        "sideImage": sideImageUrl,
        "createdAt": FieldValue.serverTimestamp(),
      });

      _resetForm();
      _showSuccessDialog("Car details uploaded successfully.");
    } catch (e) {
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
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          CupertinoTextField(
            controller: controller,
            placeholder: "Enter $label",
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(8),
            ),
            onChanged: (value) {
              setState(() {});
            },
            onSubmitted: (value) {
              if (value.isEmpty) {
                _showErrorDialog("$label cannot be empty.");
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._controllers.entries
                    .map((entry) => _buildTextField(entry.key, entry.value)),
                _buildImagePicker(
                    "Car Front View", _frontImage, (img) => _frontImage = img),
                _buildImagePicker(
                    "Car Back View", _backImage, (img) => _backImage = img),
                _buildImagePicker(
                    "Car Side View", _sideImage, (img) => _sideImage = img),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        color: CupertinoColors.systemGrey5,
                        onPressed: _resetForm,
                        child: const Text("Reset",
                            style: TextStyle(color: CupertinoColors.black)),
                      ),
                    ),
                    Expanded(
                      child: CupertinoButton.filled(
                        onPressed: _uploadCarDetails,
                        child: const Text("Upload"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          CupertinoButton(
            child: image == null
                ? const Text("Pick Image")
                : Image.file(image, height: 100),
            onPressed: () => _pickImage(setImage),
          ),
        ],
      ),
    );
  }
}
