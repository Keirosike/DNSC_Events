import 'package:auto_size_text/auto_size_text.dart';
import 'package:dnsc_events/colors/color.dart';
import 'package:flutter/material.dart';
import 'package:dnsc_events/widget/appbar.dart';
import 'package:dnsc_events/widget/bottomBar.dart';
import 'package:dnsc_events/admin.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:dnsc_events/widget/paginationUi.dart';

class Userlogged extends StatefulWidget {
  const Userlogged({super.key});

  @override
  State<Userlogged> createState() => _UserloggedState();
}

class _UserloggedState extends State<Userlogged> {
  bool isLoading = false;
  String _searchQuery = '';

  // Data
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filteredStudents = [];

  // Pagination (0-based page index)
  int _currentPage = 0;
  int _itemsPerPage = 5; // 5 items per page

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    setState(() {
      isLoading = true;
      _students = [];
      _filteredStudents = [];
      _currentPage = 0;
    });

    try {
      // Fetch all students from Realtime Database
      final studentsRef = FirebaseDatabase.instance.ref().child('students');
      final studentsSnapshot = await studentsRef.get();

      if (studentsSnapshot.exists) {
        // Convert DataSnapshot to Map
        Map<dynamic, dynamic> studentsData =
            studentsSnapshot.value as Map<dynamic, dynamic>;

        List<Map<String, dynamic>> studentsList = [];

        // Process each student
        studentsData.forEach((studentId, studentData) {
          if (studentData is Map) {
            // Get student info
            final Map<String, dynamic> studentInfo = {
              'uid': studentId.toString(),
              ...studentData,
            };

            // Format dates
            if (studentData['createdAt'] != null) {
              studentInfo['formattedCreatedAt'] = _formatTimestamp(
                studentData['createdAt'],
              );
            }

            if (studentData['lastLoginAt'] != null) {
              studentInfo['lastActive'] = _getTimeAgo(
                DateTime.fromMillisecondsSinceEpoch(studentData['lastLoginAt']),
              );
              studentInfo['isActive'] = _isUserActive(
                studentData['lastLoginAt'],
              );
            } else {
              studentInfo['lastActive'] = 'Never active';
              studentInfo['isActive'] = false;
            }

            studentsList.add(studentInfo);
          }
        });

        // Sort by active status (active students first), then by name
        studentsList.sort((a, b) {
          if (a['isActive'] && !b['isActive']) return -1;
          if (!a['isActive'] && b['isActive']) return 1;

          final nameA = (a['name'] ?? '').toString().toLowerCase();
          final nameB = (b['name'] ?? '').toString().toLowerCase();
          return nameA.compareTo(nameB);
        });

        setState(() {
          _students = studentsList;
          _filteredStudents = studentsList;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching students: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  bool _isUserActive(int lastLoginTimestamp) {
    final lastLoginDate = DateTime.fromMillisecondsSinceEpoch(
      lastLoginTimestamp,
    );
    final now = DateTime.now();
    final difference = now.difference(lastLoginDate);
    return difference.inHours < 1; // Active if last login was within 1 hour
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 30) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      if (timestamp is int) {
        return DateFormat(
          'MM-dd-yyyy',
        ).format(DateTime.fromMillisecondsSinceEpoch(timestamp));
      } else if (timestamp is String) {
        // Try to parse as date string
        return DateFormat('MM-dd-yyyy').format(DateTime.parse(timestamp));
      }
      return 'Unknown';
    } catch (e) {
      print('Error formatting timestamp: $e');
      return 'Unknown';
    }
  }

  void _searchStudents(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 0;

      if (query.isEmpty) {
        _filteredStudents = _students;
      } else {
        _filteredStudents = _students.where((student) {
          final name = (student['name'] ?? '').toString().toLowerCase();
          final email = (student['email'] ?? '').toString().toLowerCase();
          final studentId = (student['studentId'] ?? '')
              .toString()
              .toLowerCase();
          final lowerQuery = query.toLowerCase();

          return name.contains(lowerQuery) ||
              email.contains(lowerQuery) ||
              studentId.contains(lowerQuery);
        }).toList();
      }
    });
  }

  /// Get students for current page (0-based)
  List<Map<String, dynamic>> _getCurrentPageStudents() {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    if (startIndex >= _filteredStudents.length) {
      return [];
    }

    return _filteredStudents.sublist(
      startIndex,
      endIndex.clamp(0, _filteredStudents.length),
    );
  }

  void _nextPage() {
    final totalPages = (_filteredStudents.length / _itemsPerPage).ceil();
    if (_currentPage < totalPages - 1) {
      setState(() {
        _currentPage++;
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _goToPage(int page) {
    final totalPages = (_filteredStudents.length / _itemsPerPage).ceil();
    if (page >= 0 && page < totalPages) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  void _onBottomBarTap(int index) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => Admin(initialIndex: index)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentStudents = _getCurrentPageStudents();

    return Scaffold(
      backgroundColor: CustomColor.background,
      appBar: Appbaradmin(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 5),
                  child: Text(
                    'Students',
                    style: TextStyle(
                      fontSize: 24,
                      fontFamily: 'InterExtra',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Search Box
            Container(
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 1),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Icon(Icons.search_outlined, color: Colors.grey.shade400),
                  const SizedBox(width: 5),
                  Expanded(
                    child: TextField(
                      onChanged: _searchStudents,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        isCollapsed: true,
                        hintText: "Search Students",
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // You can add filter functionality here later
                    },
                    child: Icon(Icons.filter_list, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Students Count
            Row(
              children: [
                Text(
                  '${_filteredStudents.length} ${_filteredStudents.length == 1 ? 'student' : 'students'} found',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (isLoading)
              Center(
                child: CircularProgressIndicator(color: CustomColor.primary),
              )
            else if (_filteredStudents.isEmpty)
              // Empty State Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 60,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _searchQuery.isEmpty ? 'No Students Found' : 'No Results',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'InterExtra',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _searchQuery.isEmpty
                          ? 'No students have registered yet'
                          : 'No students match your search',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: CustomColor.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextButton(
                        onPressed: _fetchStudents,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Refresh',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              // Student List with Pagination
              Column(
                children: [
                  // Student Cards (5 per page)
                  ...currentStudents.map(
                    (student) => _buildStudentCard(context, student),
                  ),

                  // 🔁 Reusable Pagination Controls
                  PaginationControls(
                    currentPage: _currentPage, // 0-based
                    totalItems: _filteredStudents.length,
                    itemsPerPage: _itemsPerPage,
                    itemLabel: 'students',
                    primaryColor: CustomColor.primary,
                    onPrevious: _previousPage,
                    onNext: _nextPage,
                    onPageSelected: _goToPage,

                    // Optional: allow changing page size (UI can be added in the widget later)
                    itemsPerPageOptions: const [5, 10, 20],
                    onItemsPerPageChanged: (newSize) {
                      setState(() {
                        _itemsPerPage = newSize;
                        _currentPage = 0;
                      });
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomBarAdmin(
        selectedIndex: -1,
        tapItem: _onBottomBarTap,
      ),
      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchStudents,
        backgroundColor: CustomColor.primary,
        child: const Icon(Icons.refresh, color: Colors.white),
        mini: true,
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, Map<String, dynamic> student) {
    final String displayName = student['name']?.toString() ?? 'Unknown Student';
    final String email = student['email']?.toString() ?? 'No email';
    final String? imageUrl =
        student['profileImage']?.toString() ??
        student['imageUrl']?.toString() ??
        student['photoURL']?.toString();
    final String accountCreated =
        student['formattedCreatedAt']?.toString() ??
        _formatTimestamp(student['createdAt']) ??
        'Unknown';
    final String lastActive =
        student['lastActive']?.toString() ?? 'Never active';
    final bool isActive = student['isActive'] == true;
    final String? studentId = student['studentId']?.toString() ?? 'N/A';
    final String status = student['status']?.toString() ?? 'offline';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      height: 99,
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade900 : Colors.grey.shade800,
        borderRadius: const BorderRadius.horizontal(
          left: Radius.circular(12),
          right: Radius.circular(12),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            spreadRadius: 1,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 5),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                // Student Avatar Container
                Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: CustomColor.primary.withOpacity(0.1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: CustomColor.primary,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  Icons.person,
                                  size: 30,
                                  color: CustomColor.primary,
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Icon(
                              Icons.person,
                              size: 30,
                              color: CustomColor.primary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: AutoSizeText(
                                    displayName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxFontSize: 16,
                                    maxLines: 1,
                                    minFontSize: 10,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            AutoSizeText(
                              email,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxFontSize: 12,
                              minFontSize: 8,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Account Created',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Last Active',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    accountCreated,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    lastActive,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isActive
                                          ? Colors.green.shade800
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
