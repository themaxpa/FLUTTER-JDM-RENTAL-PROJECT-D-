import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class MyDocumentsScreen extends StatefulWidget {
  @override
  _MyDocumentsScreenState createState() => _MyDocumentsScreenState();
}

class _MyDocumentsScreenState extends State<MyDocumentsScreen> {
  Future<String?> uploadImageToCloudinary(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/dageosse2/image/upload'),
      );
      request.fields['upload_preset'] =
          'project-d'; // Your Cloudinary upload preset
      request.files
          .add(await http.MultipartFile.fromPath('file', imageFile.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonData = json.decode(responseData);
        return jsonData['secure_url']; // Returns the uploaded image URL
      } else {
        print("Cloudinary Upload Failed: ${response.reasonPhrase}");
        return null;
      }
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  final ImagePicker _picker = ImagePicker();
  final List<Map<String, dynamic>> documents = [
    {
      "title": "DL Front Side",
      "image": null,
      "url": null,
      "isUploading": false
    },
    {"title": "DL Back Side", "image": null, "url": null, "isUploading": false},
    {"title": "Pan Card", "image": null, "url": null, "isUploading": false},
    {
      "title": "Aadhaar Card Front",
      "image": null,
      "url": null,
      "isUploading": false
    },
    {
      "title": "Aadhaar Card Back",
      "image": null,
      "url": null,
      "isUploading": false
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchUploadedDocuments(); // Load existing documents on startup
  }

  Future<void> _fetchUploadedDocuments() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String userId = user.uid;
    final snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("MyDocuments")
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final title = data["title"];
      final url = data["url"];

      // Find the matching document in the list and update its URL
      for (var document in documents) {
        if (document["title"] == title) {
          setState(() {
            document["url"] = url;
          });
        }
      }
    }
  }

  Future<void> _pickImage(int index) async {
    final ImageSource? source = await _showImageSourceDialog();
    if (source == null) return;

    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      setState(() {
        documents[index]["image"] = imageFile;
        documents[index]["isUploading"] = true;
      });

      String? imageUrl = await uploadImageToCloudinary(imageFile);
      setState(() {
        documents[index]["isUploading"] = false;
        if (imageUrl != null) {
          documents[index]["url"] = imageUrl;
          _submitData(index);
        }
      });
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return await showCupertinoModalPopup<ImageSource>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text("Select Image Source"),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: Text("Camera"),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: Text("Gallery"),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel",
              style: TextStyle(color: CupertinoColors.destructiveRed)),
        ),
      ),
    );
  }

  Future<void> _submitData(int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("User not authenticated."),
            backgroundColor: Colors.red),
      );
      return;
    }

    final String userId = user.uid;

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("MyDocuments")
          .doc(documents[index]["title"]) // Save with title as doc ID
          .set({
        "title": documents[index]["title"],
        "url": documents[index]["url"],
        "timestamp": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text("${documents[index]["title"]} Uploaded Successfully!"),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      print("Error saving document: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Failed to save document."),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF1F4F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text("My Documents",
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: documents.length,
          itemBuilder: (context, index) {
            return DocumentItem(
              title: documents[index]["title"],
              image: documents[index]["image"],
              url: documents[index]["url"],
              isUploading: documents[index]["isUploading"],
              onUpload: () => _pickImage(index),
            );
          },
        ),
      ),
    );
  }
}

class DocumentItem extends StatelessWidget {
  final String title;
  final File? image;
  final String? url;
  final bool isUploading;
  final VoidCallback onUpload;

  const DocumentItem({
    required this.title,
    required this.image,
    required this.url,
    required this.isUploading,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onUpload,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 5,
                spreadRadius: 1,
                offset: Offset(0, 3))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Tap to upload/view",
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
                SizedBox(height: 4),
                Text(title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
                if (url != null) SizedBox(height: 8),
                if (url != null)
                  ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(url!,
                          width: 100, height: 60, fit: BoxFit.cover)),
              ],
            ),
            isUploading
                ? CircularProgressIndicator()
                : Icon(Icons.check_circle,
                    color: url != null ? Colors.green : Colors.orange),
          ],
        ),
      ),
    );
  }
}
