import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UsersCardScreen extends StatefulWidget {
  @override
  _UsersCardScreenState createState() => _UsersCardScreenState();
}

class _UsersCardScreenState extends State<UsersCardScreen> {
  bool isLoading = true;
  String selectedFilter = 'all';
  Map<String, bool> expandedCards = {};
  List<DocumentSnapshot> allUsers = [];
  List<DocumentSnapshot> displayedUsers = [];
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    fetchUsers();
    _updateBrightness();
    WidgetsBinding.instance.window.onPlatformBrightnessChanged = () {
      _updateBrightness();
    };
  }

  void _updateBrightness() {
    setState(() {
      _isDarkMode =
          WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
    });
  }

  Future<void> fetchUsers() async {
    try {
      QuerySnapshot usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      QuerySnapshot vendorsSnapshot =
          await FirebaseFirestore.instance.collection('vendors').get();

      List<DocumentSnapshot> combinedUsers = [
        ...usersSnapshot.docs,
        ...vendorsSnapshot.docs
      ];

      setState(() {
        allUsers = combinedUsers;
        displayedUsers = combinedUsers;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching users: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void filterUsers(String filter) {
    setState(() {
      selectedFilter = filter;
      if (filter == 'all') {
        displayedUsers = allUsers;
      } else if (filter == 'users') {
        displayedUsers = allUsers
            .where((user) => user.reference.parent.id == 'users')
            .toList();
      } else if (filter == 'vendors') {
        displayedUsers = allUsers
            .where((user) => user.reference.parent.id == 'vendors')
            .toList();
      }
    });
  }

  void toggleCardExpansion(String uid) {
    setState(() {
      expandedCards[uid] = !(expandedCards[uid] ?? false);
    });
  }

  Future<void> removeUser(String uid, String collection) async {
    await FirebaseFirestore.instance.collection(collection).doc(uid).delete();
    setState(() {
      allUsers.removeWhere((user) => user.id == uid);
      displayedUsers.removeWhere((user) => user.id == uid);
    });
  }

  void confirmDeleteUser(String uid, String collection) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text("Delete User"),
        content: Text("Are you sure you want to remove this user?"),
        actions: [
          CupertinoDialogAction(
            child: Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text("Remove"),
            onPressed: () {
              removeUser(uid, collection);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  dynamic getDocumentData(DocumentSnapshot doc, String field) {
    return doc.data() != null && (doc.data() as Map).containsKey(field)
        ? doc[field]
        : null;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double avatarSize = screenWidth * 0.15;
    double padding = screenWidth * 0.05;

    return CupertinoPageScaffold(
      backgroundColor: _isDarkMode
          ? CupertinoColors.black
          : CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'LoginInfo',
          style: TextStyle(
            color: _isDarkMode ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),
        backgroundColor: _isDarkMode
            ? CupertinoColors.darkBackgroundGray
            : CupertinoColors.systemBackground,
      ),
      child: SafeArea(
        child: Column(
          children: [
            Material(
              color: _isDarkMode
                  ? CupertinoColors.black
                  : CupertinoColors.systemGroupedBackground,
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: CupertinoSlidingSegmentedControl<String>(
                  groupValue: selectedFilter,
                  onValueChanged: (String? value) {
                    if (value != null) filterUsers(value);
                  },
                  backgroundColor: _isDarkMode
                      ? CupertinoColors.darkBackgroundGray
                      : CupertinoColors.systemGrey5,
                  thumbColor: _isDarkMode
                      ? CupertinoColors.darkBackgroundGray
                      : CupertinoColors.white,
                  children: {
                    'all': Text(
                      'All',
                      style: TextStyle(
                        color: _isDarkMode
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                      ),
                    ),
                    'users': Text(
                      'Users',
                      style: TextStyle(
                        color: _isDarkMode
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                      ),
                    ),
                    'vendors': Text(
                      'Vendors',
                      style: TextStyle(
                        color: _isDarkMode
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                      ),
                    ),
                  },
                ),
              ),
            ),
            Expanded(
              child: isLoading
                  ? Center(
                      child: CupertinoActivityIndicator(
                        color: _isDarkMode
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                      ),
                    )
                  : displayedUsers.isEmpty
                      ? Center(
                          child: Text(
                            'No users found',
                            style: TextStyle(
                              color: _isDarkMode
                                  ? CupertinoColors.white
                                  : CupertinoColors.black,
                            ),
                          ),
                        )
                      : CupertinoScrollbar(
                          child: ListView.builder(
                            itemCount: displayedUsers.length,
                            itemBuilder: (context, index) {
                              var user = displayedUsers[index];
                              String uid = user.id;
                              String name =
                                  getDocumentData(user, 'name') ?? 'N/A';
                              String email =
                                  getDocumentData(user, 'email') ?? 'N/A';
                              String? profileImage =
                                  getDocumentData(user, 'profileImage');
                              bool isExpanded = expandedCards[uid] ?? false;
                              String collection = user.reference.parent.id;

                              return GestureDetector(
                                onTap: () => toggleCardExpansion(uid),
                                child: Container(
                                  margin: EdgeInsets.symmetric(
                                      horizontal: padding, vertical: 8),
                                  padding: EdgeInsets.all(padding),
                                  decoration: BoxDecoration(
                                    color: _isDarkMode
                                        ? CupertinoColors.darkBackgroundGray
                                        : CupertinoColors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _isDarkMode
                                            ? CupertinoColors.black
                                                .withOpacity(0.3)
                                            : CupertinoColors.systemGrey2,
                                        blurRadius: 5,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          ClipOval(
                                            child: profileImage != null
                                                ? Image.network(
                                                    profileImage,
                                                    width: avatarSize,
                                                    height: avatarSize,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
                                                      return Image.asset(
                                                        'assets/images/img.jpg',
                                                        width: avatarSize,
                                                        height: avatarSize,
                                                        fit: BoxFit.cover,
                                                      );
                                                    },
                                                  )
                                                : Image.asset(
                                                    'assets/images/img.jpg',
                                                    width: avatarSize,
                                                    height: avatarSize,
                                                    fit: BoxFit.cover,
                                                  ),
                                          ),
                                          SizedBox(width: padding),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Material(
                                                  color: CupertinoColors
                                                      .transparent,
                                                  child: Text(
                                                    name,
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: _isDarkMode
                                                          ? CupertinoColors
                                                              .white
                                                          : CupertinoColors
                                                              .black,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Material(
                                                  color: CupertinoColors
                                                      .transparent,
                                                  child: Text(
                                                    email,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: _isDarkMode
                                                          ? CupertinoColors
                                                              .systemGrey
                                                          : CupertinoColors
                                                              .systemGrey,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isExpanded)
                                            CupertinoButton(
                                              padding: EdgeInsets.zero,
                                              child: Icon(
                                                CupertinoIcons.trash,
                                                color:
                                                    CupertinoColors.systemRed,
                                              ),
                                              onPressed: () =>
                                                  confirmDeleteUser(
                                                      uid, collection),
                                            ),
                                          Icon(
                                            isExpanded
                                                ? CupertinoIcons.chevron_up
                                                : CupertinoIcons.chevron_down,
                                            color: _isDarkMode
                                                ? CupertinoColors.white
                                                : CupertinoColors.systemGrey,
                                          ),
                                        ],
                                      ),
                                      if (isExpanded) ...[
                                        SizedBox(height: 10),
                                        Divider(
                                          color: _isDarkMode
                                              ? CupertinoColors.systemGrey6
                                              : CupertinoColors.systemGrey3,
                                        ),
                                        SizedBox(height: 5),
                                        Material(
                                          color: CupertinoColors.transparent,
                                          child: Text(
                                            "Phone: ${getDocumentData(user, 'phone') ?? 'N/A'}",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: _isDarkMode
                                                  ? CupertinoColors.activeBlue
                                                      .withOpacity(0.8)
                                                  : CupertinoColors.activeBlue,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Material(
                                          color: CupertinoColors.transparent,
                                          child: Text(
                                            "Location: ${getDocumentData(user, 'location') ?? 'N/A'}",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: _isDarkMode
                                                  ? CupertinoColors.activeBlue
                                                      .withOpacity(0.8)
                                                  : CupertinoColors.activeBlue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
