import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class CompanyDocumentsScreen extends StatefulWidget {
  @override
  _CompanyDocumentsScreenState createState() => _CompanyDocumentsScreenState();
}

class _CompanyDocumentsScreenState extends State<CompanyDocumentsScreen> {
  final List<Map<String, dynamic>> documents = [
    {
      "title": "CompanyRegistration",
      "image": null,
      "url": null,
      "isUploading": false,
      "isUploaded": false
    },
    {
      "title": "GSTCertificate",
      "image": null,
      "url": null,
      "isUploading": false,
      "isUploaded": false
    },
    {
      "title": "PANCard",
      "image": null,
      "url": null,
      "isUploading": false,
      "isUploaded": false
    },
    {
      "title": "BankAccountProof",
      "image": null,
      "url": null,
      "isUploading": false,
      "isUploaded": false
    },
    {
      "title": "TradeLicense",
      "image": null,
      "url": null,
      "isUploading": false,
      "isUploaded": false
    },
  ];

  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadUploadedDocuments();
  }

  Future<void> _loadUploadedDocuments() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      final snapshot = await _firestore
          .collection("vendors")
          .doc(user.uid)
          .collection("CompanyDetails")
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final index =
            documents.indexWhere((item) => item["title"] == data["title"]);
        if (index != -1 && data["url"] != null) {
          setState(() {
            documents[index]["url"] = data["url"];
            documents[index]["isUploaded"] = true;
          });
        }
      }
    } catch (e) {
      print("Error loading documents: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load company documents. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage(int index) async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      setState(() {
        documents[index]["image"] = File(pickedFile.path);
        documents[index]["isUploading"] = true;
      });

      final imageUrl = await uploadImageToCloudinary(File(pickedFile.path));
      if (imageUrl == null) throw Exception("Failed to upload image");

      await _submitData(index, imageUrl);

      setState(() {
        documents[index]["url"] = imageUrl;
        documents[index]["isUploaded"] = true;
        documents[index]["isUploading"] = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${documents[index]["title"]} uploaded successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Error uploading document: $e");
      setState(() {
        documents[index]["isUploading"] = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to upload document. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
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
      if (response.statusCode != 200) return null;

      var responseData = await response.stream.bytesToString();
      return json.decode(responseData)['secure_url'];
    } catch (e) {
      print("Error uploading to Cloudinary: $e");
      return null;
    }
  }

  Future<void> _submitData(int index, String imageUrl) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      await _firestore
          .collection("vendors")
          .doc(user.uid)
          .collection("CompanyDetails")
          .doc(documents[index]["title"])
          .set({
        "title": documents[index]["title"],
        "url": imageUrl,
        "timestamp": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error saving to Firestore: $e");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Company Documents',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.41,
          ),
        ),
        backgroundColor: CupertinoColors.systemBackground,
        border: null,
      ),
      child: SafeArea(
        child: _isLoading
            ? Center(child: CupertinoActivityIndicator(radius: 16))
            : ListView.builder(
                padding: EdgeInsets.only(top: 8),
                itemCount: documents.length,
                itemBuilder: (context, index) => _buildIOSDocumentItem(index),
              ),
      ),
    );
  }

  Widget _buildIOSDocumentItem(int index) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.2),
              blurRadius: 3,
              spreadRadius: 1,
              offset: Offset(0, 1),
            )
          ],
        ),
        child: CupertinoButton(
          padding: EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(10),
          onPressed: () => _pickImage(index),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tap to upload/view",
                      style: TextStyle(
                        color: CupertinoColors.secondaryLabel,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      documents[index]["title"],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.label,
                      ),
                    ),
                    if (documents[index]["url"] != null) SizedBox(height: 8),
                    if (documents[index]["url"] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          documents[index]["url"],
                          width: 100,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              if (documents[index]["isUploading"])
                CupertinoActivityIndicator(radius: 12)
              else
                Icon(
                  documents[index]["isUploaded"]
                      ? CupertinoIcons.checkmark_alt_circle_fill
                      : CupertinoIcons.checkmark_alt_circle,
                  color: documents[index]["isUploaded"]
                      ? CupertinoColors.systemGreen
                      : CupertinoColors.systemGrey,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
