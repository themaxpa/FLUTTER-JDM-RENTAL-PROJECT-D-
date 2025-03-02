import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UsersCardScreen extends StatefulWidget {
  @override
  _UsersCardScreenState createState() => _UsersCardScreenState();
}

class _UsersCardScreenState extends State<UsersCardScreen> {
  bool isAdminUser = false;

  @override
  void initState() {
    super.initState();
    checkAdmin();
  }

  void checkAdmin() async {
    bool admin = await isAdmin();
    setState(() {
      isAdminUser = admin;
    });
  }

  Future<bool> isAdmin() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return userDoc.exists && userDoc['role'] == 'admin';
  }

  void deleteUser(String userId) {
    FirebaseFirestore.instance.collection('users').doc(userId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Users List')),
      body: isAdminUser
          ? StreamBuilder(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No users found'));
                }

                var users = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    var user = users[index];

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(user['name'][0] ?? "?"), // First letter
                        ),
                        title: Text(user['name'] ?? 'N/A'),
                        subtitle: Text(user['email'] ?? 'N/A'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                // Navigate to edit screen
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                deleteUser(user.id);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            )
          : FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Center(child: Text('User data not found'));
                }

                var userData = snapshot.data!;
                return Center(
                  child: Card(
                    margin: EdgeInsets.all(16),
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            child: Text(
                              userData['name'][0] ?? "?",
                              style: TextStyle(fontSize: 24),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text("Name: ${userData['name'] ?? 'N/A'}",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text("Email: ${userData['email'] ?? 'N/A'}",
                              style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
