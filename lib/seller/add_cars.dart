import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class AddCars extends StatefulWidget {
  const AddCars({super.key});

  @override
  State<AddCars> createState() => _AddCarsState();
}

class _AddCarsState extends State<AddCars> {
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
      "Model Name ",
      "Car Brand ",
      "12 Month Price ",
      "6 Month Price ",
      "1 Month Price ",
      "Color ",
      "Gearbox ",
      "Seats ",
      "Motor ",
      "Speed (0-100) ",
      "Location "
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

  Future<void> _uploadCarDetails() async {
    try {
      // Upload the car details to Firestore under the "vendors" collection.
      // In a real app you would replace 'vendorID' with the logged-in vendor's UID.
      await _firestore
          .collection('vendors')
          .doc('vendorID')
          .collection('CarDetails')
          .add({
        for (var entry in _controllers.entries) entry.key: entry.value.text,
        "frontImage": _frontImage?.path ?? "",
        "backImage": _backImage?.path ?? "",
        "sideImage": _sideImage?.path ?? "",
      });
      _resetForm();
      print("Car details uploaded successfully");
    } catch (e) {
      print("Error uploading car details: $e");
    }
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
                const SizedBox(height: 16),
                _buildImagePicker(
                    "Car Front View", _frontImage, (img) => _frontImage = img),
                _buildImagePicker(
                    "Car Back View", _backImage, (img) => _backImage = img),
                _buildImagePicker(
                    "Car Side View", _sideImage, (img) => _sideImage = img),
                const SizedBox(height: 24),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: CupertinoButton.filled(
                        onPressed: _uploadCarDetails,
                        child: const Text("Next Step"),
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
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _pickImage(setImage),
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
              ),
              child: image == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.cloud_upload,
                            size: 40, color: CupertinoColors.systemGrey),
                        CupertinoButton(
                          onPressed: () => _pickImage(setImage),
                          child: const Text("Click to browse",
                              style:
                                  TextStyle(color: CupertinoColors.activeBlue)),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(image, fit: BoxFit.cover),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
