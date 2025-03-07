import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UsersCardScreen extends StatefulWidget {
  @override
  _UsersCardScreenState createState() => _UsersCardScreenState();
}

class _UsersCardScreenState extends State<UsersCardScreen> {
  bool isAdminUser = false;
  bool isLoading = true;
  String selectedFilter = 'all';
  Map<String, bool> expandedCards = {};

  @override
  void initState() {
    super.initState();
    checkAdmin();
  }

  void checkAdmin() async {
    bool admin = await isAdmin();
    setState(() {
      isAdminUser = admin;
      isLoading = false;
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

  void toggleCardExpansion(String uid) {
    setState(() {
      expandedCards[uid] = !(expandedCards[uid] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text('Users List')),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: isLoading
                  ? Center(child: CupertinoActivityIndicator())
                  : StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .snapshots(),
                      builder:
                          (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CupertinoActivityIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(child: Text('No users found'));
                        }

                        var users = snapshot.data!.docs.where((user) {
                          String role = user['role'] ?? 'user';
                          return role != 'admin' &&
                              (selectedFilter == 'all' ||
                                  (selectedFilter == 'user' &&
                                      role == 'user') ||
                                  (selectedFilter == 'seller' &&
                                      role == 'seller'));
                        }).toList();

                        if (users.isEmpty) {
                          return Center(
                              child: Text('No users found in this category'));
                        }

                        return CupertinoScrollbar(
                          child: ListView.builder(
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              var user = users[index];
                              String uid = user.id;
                              String name = user['name'] ?? 'N/A';
                              String email = user['email'] ?? 'N/A';
                              String role = user['role'] ?? 'user';
                              String phone = user['phone'] ?? 'N/A';
                              String location = user['location'] ?? 'N/A';
                              String? profileImage = user['profileImage'];
                              bool isExpanded = expandedCards[uid] ?? false;

                              return GestureDetector(
                                onTap: () => toggleCardExpansion(uid),
                                child: Container(
                                  margin: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.04,
                                      vertical: screenHeight * 0.01),
                                  padding: EdgeInsets.all(screenWidth * 0.03),
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.systemGrey5,
                                    borderRadius: BorderRadius.circular(
                                        screenWidth * 0.03),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: screenWidth * 0.07,
                                            backgroundColor:
                                                CupertinoColors.systemGrey4,
                                            backgroundImage:
                                                profileImage != null
                                                    ? NetworkImage(profileImage)
                                                    : null,
                                            child: profileImage == null
                                                ? Material(
                                                    color: CupertinoColors
                                                        .systemGrey5,
                                                    child: Text(
                                                      name[0].toUpperCase(),
                                                      style: TextStyle(
                                                          fontSize:
                                                              screenWidth *
                                                                  0.06,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: CupertinoColors
                                                              .white),
                                                    ),
                                                  )
                                                : null,
                                          ),
                                          SizedBox(width: screenWidth * 0.03),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Material(
                                                color:
                                                    CupertinoColors.systemGrey5,
                                                child: Text(name,
                                                    style: TextStyle(
                                                        fontSize:
                                                            screenWidth * 0.045,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              ),
                                              Material(
                                                color:
                                                    CupertinoColors.systemGrey5,
                                                child: Text(email,
                                                    style: TextStyle(
                                                        fontSize: screenWidth *
                                                            0.035)),
                                              ),
                                            ],
                                          ),
                                          Spacer(),
                                          Icon(
                                            isExpanded
                                                ? CupertinoIcons.chevron_up
                                                : CupertinoIcons.chevron_down,
                                            color: CupertinoColors.systemGrey,
                                            size: screenWidth * 0.05,
                                          ),
                                        ],
                                      ),
                                      if (isExpanded) ...[
                                        SizedBox(height: screenHeight * 0.01),
                                        Material(
                                          color: CupertinoColors.systemGrey5,
                                          child: Text("Phone: $phone",
                                              style: TextStyle(
                                                  fontSize:
                                                      screenWidth * 0.04)),
                                        ),
                                        Material(
                                          color: CupertinoColors.systemGrey5,
                                          child: Text("Location: $location",
                                              style: TextStyle(
                                                  fontSize:
                                                      screenWidth * 0.04)),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: screenHeight * 0.02),
              child: CupertinoSlidingSegmentedControl<String>(
                groupValue: selectedFilter,
                onValueChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      selectedFilter = value;
                    });
                  }
                },
                children: {
                  'all': Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Material(
                      color: Colors.transparent,
                      child: Text('All',
                          style: TextStyle(color: CupertinoColors.black)),
                    ),
                  ),
                  'user': Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Material(
                      color: Colors.transparent,
                      child: Text('Users',
                          style: TextStyle(color: CupertinoColors.black)),
                    ),
                  ),
                  'seller': Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Material(
                      color: Colors.transparent,
                      child: Text('Sellers',
                          style: TextStyle(color: CupertinoColors.black)),
                    ),
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
