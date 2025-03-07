import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class MyDocumentsScreen extends StatefulWidget {
  @override
  _MyDocumentsScreenState createState() => _MyDocumentsScreenState();
}

class _MyDocumentsScreenState extends State<MyDocumentsScreen> {
  final List<Map<String, dynamic>> documents = [
    {
      "title": "DL Front Side",
      "image": null,
      "url": null,
      "isUploading": false,
      "isUploaded": false
    },
    {
      "title": "DL Back Side",
      "image": null,
      "url": null,
      "isUploading": false,
      "isUploaded": false
    },
    {
      "title": "Pan Card",
      "image": null,
      "url": null,
      "isUploading": false,
      "isUploaded": false
    },
    {
      "title": "Aadhaar Card Front",
      "image": null,
      "url": null,
      "isUploading": false,
      "isUploaded": false
    },
    {
      "title": "Aadhaar Card Back",
      "image": null,
      "url": null,
      "isUploading": false,
      "isUploaded": false
    },
  ];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUploadedDocuments();
  }

  Future<void> _loadUploadedDocuments() async {
    try {
      // Fetch all documents data from Firestore
      final snapshot =
          await FirebaseFirestore.instance.collection("user_documents").get();
      for (var doc in snapshot.docs) {
        String title = doc["title"];
        String url = doc["url"];

        // Find the matching document in the list
        final index = documents.indexWhere((doc) => doc["title"] == title);
        if (index != -1) {
          setState(() {
            documents[index]["url"] = url;
            documents[index]["isUploaded"] = url != null &&
                url.isNotEmpty; // Ensure it's set to true if URL is present
          });
        }
      }
    } catch (e) {
      print("Error loading documents: $e");
    }
  }

  Future<void> _pickImage(int index) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      setState(() {
        documents[index]["image"] = imageFile;
        documents[index]["isUploading"] = true;
      });

      // Upload image to Cloudinary
      String? imageUrl = await uploadImageToCloudinary(imageFile);

      // Update state after upload
      setState(() {
        documents[index]["isUploading"] = false;
        if (imageUrl != null) {
          documents[index]["url"] = imageUrl;
          documents[index]["isUploaded"] = true; // Mark as uploaded
        }
      });

      // If upload was successful, submit data to Firestore
      if (imageUrl != null) {
        _submitData(index);
      }
    }
  }

  Future<String?> uploadImageToCloudinary(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/dageosse2/image/upload'),
      );
      request.fields['upload_preset'] = 'project-d';
      request.files
          .add(await http.MultipartFile.fromPath('file', imageFile.path));
      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonData = json.decode(responseData);
        return jsonData['secure_url'];
      } else {
        print("Cloudinary Upload Failed: ${response.reasonPhrase}");
        return null;
      }
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  Future<void> _submitData(int index) async {
    if (documents[index]["url"] != null) {
      try {
        // Add the document data to Firestore
        await FirebaseFirestore.instance.collection("user_documents").add({
          "title": documents[index]["title"],
          "url": documents[index]["url"],
          "timestamp": FieldValue.serverTimestamp(),
        });

        // Show a confirmation SnackBar after the image link is uploaded to Firestore
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text("${documents[index]["title"]} Uploaded Successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        // If there is an error, show an error SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Failed to upload ${documents[index]["title"]}. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
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
              isUploaded: documents[index]["isUploaded"],
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
  final bool isUploaded;
  final VoidCallback onUpload;

  const DocumentItem({
    required this.title,
    required this.image,
    required this.url,
    required this.isUploading,
    required this.isUploaded,
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
              offset: Offset(0, 3),
            )
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
                Text(
                  title,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                if (url != null) SizedBox(height: 8),
                if (url != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      url!,
                      width: 100,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
              ],
            ),
            isUploading
                ? CircularProgressIndicator()
                : Icon(
                    isUploaded
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                    color: isUploaded ? Colors.green : Colors.orange,
                  ),
          ],
        ),
      ),
    );
  }
}
