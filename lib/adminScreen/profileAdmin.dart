import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:dnsc_events/colors/color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:dnsc_events/database/logout.dart';

class Profileadmin extends StatefulWidget {
  const Profileadmin({super.key});

  @override
  State<Profileadmin> createState() => _ProfileadminState();
}

class _ProfileadminState extends State<Profileadmin> {
  late DatabaseReference _databaseRef;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  User? _currentUser;
  String _userRole = 'student'; // Default role

  final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';

  @override
  void initState() {
    super.initState();
    _databaseRef = FirebaseDatabase.instance.ref();
    _currentUser = FirebaseAuth.instance.currentUser;
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // First check if user is in admins table
      final adminRef = _databaseRef.child('admins').child(_currentUser!.uid);
      final adminSnapshot = await adminRef.get();

      if (adminSnapshot.exists) {
        // User is an admin
        _userRole = 'admin';
        final adminData = Map<String, dynamic>.from(adminSnapshot.value as Map);
        setState(() {
          _userData = {
            'uid': _currentUser!.uid,
            'email': adminData['email'] ?? _currentUser!.email ?? '',
            'displayName':
                adminData['name'] ??
                _currentUser!.displayName ??
                _getNameFromEmail(_currentUser!.email),
            'photoURL':
                adminData['profileImage'] ??
                adminData['imageUrl'] ??
                _currentUser!.photoURL ??
                '',
            'role': 'admin',
          };
        });
      } else {
        // Check if user is in students table
        final studentRef = _databaseRef
            .child('students')
            .child(_currentUser!.uid);
        final studentSnapshot = await studentRef.get();

        if (studentSnapshot.exists) {
          // User is a student
          _userRole = 'student';
          final studentData = Map<String, dynamic>.from(
            studentSnapshot.value as Map,
          );
          setState(() {
            _userData = {
              'uid': _currentUser!.uid,
              'email': studentData['email'] ?? _currentUser!.email ?? '',
              'displayName':
                  studentData['name'] ??
                  _currentUser!.displayName ??
                  _getNameFromEmail(_currentUser!.email),
              'photoURL':
                  studentData['profileImage'] ??
                  studentData['imageUrl'] ??
                  _currentUser!.photoURL ??
                  '',
              'role': 'student',
            };
          });
        } else {
          // Fallback to old user_info table
          final userRef = _databaseRef
              .child('user_info')
              .child(_currentUser!.uid);
          final snapshot = await userRef.get();

          if (snapshot.exists) {
            final data = Map<String, dynamic>.from(snapshot.value as Map);
            _userRole = data['role']?.toString() ?? 'student';
            setState(() {
              _userData = data;
            });
          } else {
            // If user doesn't exist in any database, create from auth data
            _userRole = 'student'; // Default role
            setState(() {
              _userData = {
                'uid': _currentUser!.uid,
                'email': _currentUser!.email ?? '',
                'displayName':
                    _currentUser!.displayName ??
                    _getNameFromEmail(_currentUser!.email),
                'photoURL': _currentUser!.photoURL ?? '',
                'role': _userRole,
              };
            });
          }
        }
      }
    } catch (e) {
      print('❌ Error fetching user data: $e');
      // Fallback to auth data
      _userRole = 'student';
      setState(() {
        _userData = {
          'uid': _currentUser!.uid,
          'email': _currentUser!.email ?? '',
          'displayName': _currentUser!.displayName ?? 'User',
          'role': _userRole,
        };
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getNameFromEmail(String? email) {
    if (email == null || email.isEmpty) return 'User';

    final username = email.split('@').first;
    return username
        .replaceAll('.', ' ')
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : '',
        )
        .join(' ');
  }

  Widget _buildLoadingState() {
    return Center(child: CircularProgressIndicator(color: CustomColor.primary));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColor.background,
      body: _isLoading
          ? _buildLoadingState()
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header with profile picture
                  SizedBox(
                    height: 260,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade300),
                            ),
                            image: DecorationImage(
                              image: AssetImage('assets/image/dnscEvents.png'),
                            ),
                          ),
                        ),

                        // Profile Picture
                        Positioned(
                          top: 150,
                          left: 10,
                          child: Container(
                            height: 96,
                            width: 96,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              color: Colors.black,
                              image:
                                  _userData?['photoURL'] != null &&
                                      (_userData!['photoURL'] as String)
                                          .isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(
                                        _userData!['photoURL'],
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child:
                                _userData?['photoURL'] == null ||
                                    (_userData!['photoURL'] as String).isEmpty
                                ? Center(
                                    child: Text(
                                      _userData?['displayName']
                                              ?.toString()
                                              .split(' ')
                                              .map((n) => n[0])
                                              .take(2)
                                              .join()
                                              .toUpperCase() ??
                                          'U',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Personal Information Card
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          width: 1,
                          color: Colors.grey.shade300,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: 10,
                          bottom: 10,
                          left: 20,
                          right: 20,
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Personal Information',
                                  style: TextStyle(
                                    fontFamily: 'InterExtra',
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 15),

                            // Full Name
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(top: 5),
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: CustomColor.primary
                                        .withOpacity(0.1),
                                    child: Icon(
                                      Icons.person_outline,
                                      size: 20,
                                      color: CustomColor.primary,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 30),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Full Name',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    Text(
                                      _userData?['displayName']?.toString() ??
                                          'Not available',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 10),

                            // Email
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(top: 5),
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: CustomColor.primary
                                        .withOpacity(0.1),
                                    child: Icon(
                                      Icons.email_outlined,
                                      size: 20,
                                      color: CustomColor.primary,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 30),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Email',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                      AutoSizeText(
                                        _userData?['email']?.toString() ??
                                            'Not available',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        minFontSize: 10,
                                        maxFontSize: 16,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // User Role (UPDATED LOGIC - checks both new and old tables)
                            SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(top: 5),
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: CustomColor.primary
                                        .withOpacity(0.1),
                                    child: Icon(
                                      _userRole == 'admin'
                                          ? Icons.admin_panel_settings_outlined
                                          : Icons.school_outlined,
                                      size: 20,
                                      color: CustomColor.primary,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 30),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Role',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    Text(
                                      _userRole == 'admin'
                                          ? 'Administrator'
                                          : 'Student',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 10),

                  // Account Settings Card (same as before)
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          width: 1,
                          color: Colors.grey.shade300,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: 15,
                          bottom: 15,
                          left: 20,
                          right: 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account Settings',
                              style: TextStyle(
                                fontFamily: 'InterExtra',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 15),

                            // Notification Settings
                            InkWell(
                              onTap: () {
                                // Navigate to notification settings
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: CustomColor.primary.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Icon(
                                        Icons.notifications_outlined,
                                        color: CustomColor.primary,
                                        size: 20,
                                      ),
                                    ),
                                    SizedBox(width: 15),
                                    Expanded(
                                      child: Text(
                                        'Notification Settings',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey.shade400,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            Divider(height: 0, color: Colors.grey.shade200),

                            // Privacy & Security
                            InkWell(
                              onTap: () {
                                // Navigate to privacy settings
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: CustomColor.primary.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Icon(
                                        Icons.lock_outline,
                                        color: CustomColor.primary,
                                        size: 20,
                                      ),
                                    ),
                                    SizedBox(width: 15),
                                    Expanded(
                                      child: Text(
                                        'Privacy & Security',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey.shade400,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            Divider(height: 0, color: Colors.grey.shade200),

                            // Help & Support
                            InkWell(
                              onTap: () {
                                // Navigate to help center
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: CustomColor.primary.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Icon(
                                        Icons.help_outline,
                                        color: CustomColor.primary,
                                        size: 20,
                                      ),
                                    ),
                                    SizedBox(width: 15),
                                    Expanded(
                                      child: Text(
                                        'Help & Support',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey.shade400,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            Divider(height: 0, color: Colors.grey.shade200),

                            // About
                            InkWell(
                              onTap: () {
                                // Navigate to about page
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: CustomColor.primary.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Icon(
                                        Icons.info_outline,
                                        color: CustomColor.primary,
                                        size: 20,
                                      ),
                                    ),
                                    SizedBox(width: 15),
                                    Expanded(
                                      child: Text(
                                        'About DNSC Events',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey.shade400,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 10),

                  // Logout Card - UPDATED with correct role
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          width: 1,
                          color: Colors.grey.shade300,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => LogoutDialog.show(
                            context: context,
                            isAdmin: _userRole == 'admin', // Pass correct role
                            userEmail: userEmail,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: 15,
                              bottom: 15,
                              left: 20,
                              right: 20,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    Icons.logout_outlined,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                ),
                                SizedBox(width: 15),
                                Expanded(
                                  child: Text(
                                    'Logout',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey.shade400,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}
