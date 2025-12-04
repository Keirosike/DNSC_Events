import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:dnsc_events/colors/color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:dnsc_events/database/logout.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  late DatabaseReference _databaseRef;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  User? _currentUser;

  final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';

  @override
  void initState() {
    super.initState();
    _databaseRef = FirebaseDatabase.instance.ref();
    _currentUser = FirebaseAuth.instance.currentUser;
    _fetchUserData();
  }

  Future<void> _updateStudentId(String newStudentId) async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userRef = _databaseRef.child('user_info').child(_currentUser!.uid);

      // Update in Firebase
      await userRef.update({
        'studentId': newStudentId,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Update local state
      setState(() {
        _userData = {..._userData!, 'studentId': newStudentId};
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Student ID updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      print('✅ Student ID updated to: $newStudentId');
    } catch (e) {
      print('❌ Error updating student ID: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update Student ID. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUserData() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userRef = _databaseRef.child('user_info').child(_currentUser!.uid);
      final snapshot = await userRef.get();

      if (snapshot.exists) {
        setState(() {
          _userData = Map<String, dynamic>.from(snapshot.value as Map);
        });
      } else {
        // If user doesn't exist in database, create from auth data
        setState(() {
          _userData = {
            'uid': _currentUser!.uid,
            'email': _currentUser!.email ?? '',
            'displayName':
                _currentUser!.displayName ??
                _getNameFromEmail(_currentUser!.email),
            'photoURL': _currentUser!.photoURL ?? '',
            'studentId': _extractStudentId(_currentUser!.email),
            'role': 'student',
          };
        });
      }
    } catch (e) {
      print('❌ Error fetching user data: $e');
      // Fallback to auth data
      setState(() {
        _userData = {
          'uid': _currentUser!.uid,
          'email': _currentUser!.email ?? '',
          'displayName': _currentUser!.displayName ?? 'User',
          'studentId': _extractStudentId(_currentUser!.email),
        };
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _extractStudentId(String? email) {
    if (email == null || !email.contains('@dnsc.edu.ph')) {
      return 'Not available';
    }
    return email.split('@').first;
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

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigate to login screen
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      print('❌ Error logging out: $e');
    }
  }

  Widget _buildLoadingState() {
    return Center(child: CircularProgressIndicator(color: CustomColor.primary));
  }

  // Add this method to show edit dialog
  void _showEditDialog(BuildContext context) {
    final currentStudentId = _userData?['studentId']?.toString() ?? '';
    final TextEditingController studentIdController = TextEditingController(
      text: currentStudentId,
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        backgroundColor: Colors.white,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: CustomColor.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: CustomColor.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.badge_outlined,
                      color: CustomColor.primary,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Edit Student ID',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: CustomColor.primary,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Input field
              Text(
                'Student ID',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: studentIdController,
                decoration: InputDecoration(
                  hintText: 'Enter your student ID',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: CustomColor.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                style: TextStyle(fontSize: 16),
                maxLength: 20,
                autofocus: true,
              ),

              SizedBox(height: 4),

              // Note text
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CustomColor.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: CustomColor.primary.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: CustomColor.primary,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will update your student ID in your profile',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final newStudentId = studentIdController.text.trim();
                        if (newStudentId.isNotEmpty) {
                          await _updateStudentId(newStudentId);
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Please enter a valid Student ID'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CustomColor.primary,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Save Changes',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

                        // Edit Button
                        Positioned(
                          top: 210,
                          right: 10,
                          child: Container(
                            height: 28,
                            width: 92,
                            decoration: BoxDecoration(
                              color: CustomColor.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  _showEditDialog(context);
                                },
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Edit',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
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

                            // Student ID
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
                                      Icons.badge_outlined,
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
                                      'Student ID',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    Text(
                                      _userData?['studentId']?.toString() ??
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

                            // User Role (Optional - can be hidden)
                            SizedBox(height: 10),
                            if (_userData?['role'] != null)
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
                                        _userData?['role'] == 'admin'
                                            ? Icons
                                                  .admin_panel_settings_outlined
                                            : Icons.school_outlined,
                                        size: 20,
                                        color: CustomColor.primary,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 30),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Role',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                      Text(
                                        _userData?['role'] == 'admin'
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

                  // Logout Card
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
                            isAdmin: false,
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
