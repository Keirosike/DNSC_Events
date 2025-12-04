import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class UserDatabaseService {
  static final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

  // -----------------------------
  // DATE HELPERS
  // -----------------------------
  static Map<String, String> _formatDateDetails(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];

    return {
      'fullDate': '${months[date.month - 1]} ${date.day}, ${date.year}',
      'monthName': months[date.month - 1],
      'month': date.month.toString().padLeft(2, '0'),
      'day': date.day.toString().padLeft(2, '0'),
      'year': date.year.toString(),
      'weekday': days[date.weekday - 1],
      'shortDate':
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'time':
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}',
      'dateTime':
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}',
    };
  }

  static String _getNameFromEmail(String? email) {
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

  // -----------------------------
  // STUDENT LOGIC
  // -----------------------------
  static Future<void> saveStudentInfo(User user) async {
    try {
      final userEmail = user.email ?? '';
      final studentsRef = _databaseRef.child('students').child(user.uid);

      print('🎓 Saving student info for: $userEmail');

      // Extract student ID
      String studentId = '';
      if (userEmail.endsWith('@dnsc.edu.ph')) {
        studentId = userEmail.split('@').first;
      } else {
        studentId = 'N/A';
      }

      final now = DateTime.now();
      final timestamp = now.millisecondsSinceEpoch;
      final dateDetails = _formatDateDetails(now);

      final snapshot = await studentsRef.get();
      final bool isNewStudent = !snapshot.exists;

      final studentData = {
        'uid': user.uid,
        'email': userEmail,
        'name': user.displayName ?? _getNameFromEmail(user.email),
        'profileImage': user.photoURL ?? '',
        'studentId': studentId,
        'role': 'student',
        'status': 'active',

        // Creation date info (only set for new students)
        'createdAt': snapshot.exists
            ? snapshot.child('createdAt').value
            : timestamp,
        'createdDate': snapshot.exists
            ? snapshot.child('createdDate').value
            : dateDetails['shortDate'],
        'createdFullDate': snapshot.exists
            ? snapshot.child('createdFullDate').value
            : dateDetails['fullDate'],

        // Update info (always updated)
        'updatedAt': timestamp,
        'updatedDate': dateDetails['shortDate'],

        // Login info (always updated)
        'lastLoginAt': timestamp,
        'lastLoginDate': dateDetails['shortDate'],
        'lastLoginTime': dateDetails['time'],

        // Login statistics
        'totalLogins': snapshot.exists
            ? (snapshot.child('totalLogins').value as int? ?? 0) + 1
            : 1,
      };

      if (!snapshot.exists) {
        // New student
        await studentsRef.set(studentData);
        print('✅ New student recorded in students table');

        // ➕ Increment admins -> summary -> active_users (INT ONLY, FIRST TIME LOGIN)
        await _incrementActiveUsersCount();
      } else {
        // Existing student - update login info
        final updateData = {
          'updatedAt': timestamp,
          'updatedDate': dateDetails['shortDate'],
          'lastLoginAt': timestamp,
          'lastLoginDate': dateDetails['shortDate'],
          'lastLoginTime': dateDetails['time'],
          'status': 'active',
          'totalLogins': (snapshot.child('totalLogins').value as int? ?? 0) + 1,
        };

        await studentsRef.update(updateData);
        print('✅ Student login updated');
      }

      // Record student login history
      await _recordStudentLoginHistory(user.uid, userEmail, 'login');

      print('✅ Student info saved successfully');
    } catch (e) {
      print('❌ Error saving student info: $e');
      rethrow;
    }
  }

  // Increment admins -> summary -> active_users (INT ONLY)
  static Future<void> _incrementActiveUsersCount() async {
    try {
      final summaryRef = _databaseRef
          .child('admins')
          .child('summary')
          .child('active_users');

      final snapshot = await summaryRef.get();
      final current = (snapshot.value as int?) ?? 0;
      final updated = current + 1;

      await summaryRef.set(updated);

      print('📊 Active users count incremented to: $updated');
    } catch (e) {
      print('⚠️ Could not increment admins/summary/active_users: $e');
    }
  }

  // Record STUDENT login history
  static Future<void> _recordStudentLoginHistory(
    String uid,
    String email,
    String action,
  ) async {
    try {
      final now = DateTime.now();
      final timestamp = now.millisecondsSinceEpoch;
      final dateDetails = _formatDateDetails(now);

      final historyRef = _databaseRef
          .child('students_login_history')
          .child(uid)
          .child(timestamp.toString());

      final historyData = {
        'uid': uid,
        'email': email,
        'action': action,
        'timestamp': timestamp,
        'date': dateDetails['shortDate'],
        'fullDate': dateDetails['fullDate'],
        'time': dateDetails['time'],
        'dateTime': dateDetails['dateTime'],
      };

      await historyRef.set(historyData);
      print('📝 Student login history recorded: $action for $email');
    } catch (e) {
      print('❌ Error recording student login history: $e');
    }
  }

  // -----------------------------
  // ADMIN LOGIC
  // -----------------------------
  static Future<void> saveAdminInfo(User user) async {
    try {
      final userEmail = user.email ?? '';
      final adminsRef = _databaseRef.child('admins').child(user.uid);

      print('👑 Saving admin info for: $userEmail');

      final now = DateTime.now();
      final timestamp = now.millisecondsSinceEpoch;
      final dateDetails = _formatDateDetails(now);

      final snapshot = await adminsRef.get();

      final adminData = {
        'uid': user.uid,
        'email': userEmail,
        'name': user.displayName ?? _getNameFromEmail(user.email),
        'profileImage': user.photoURL ?? '',
        'role': 'admin',
        'status': 'active',
        'adminType':
            'administrator', // Can be 'super_admin', 'admin', 'moderator'

        'createdAt': snapshot.exists
            ? snapshot.child('createdAt').value
            : timestamp,
        'createdDate': snapshot.exists
            ? snapshot.child('createdDate').value
            : dateDetails['shortDate'],
        'createdFullDate': snapshot.exists
            ? snapshot.child('createdFullDate').value
            : dateDetails['fullDate'],

        'updatedAt': timestamp,
        'updatedDate': dateDetails['shortDate'],

        'lastLoginAt': timestamp,
        'lastLoginDate': dateDetails['shortDate'],
        'lastLoginTime': dateDetails['time'],

        'totalLogins': snapshot.exists
            ? (snapshot.child('totalLogins').value as int? ?? 0) + 1
            : 1,
      };

      if (!snapshot.exists) {
        await adminsRef.set(adminData);
        print('✅ New admin recorded in admins table');
      } else {
        final updateData = {
          'updatedAt': timestamp,
          'updatedDate': dateDetails['shortDate'],
          'lastLoginAt': timestamp,
          'lastLoginDate': dateDetails['shortDate'],
          'lastLoginTime': dateDetails['time'],
          'status': 'active',
          'totalLogins': (snapshot.child('totalLogins').value as int? ?? 0) + 1,
        };

        await adminsRef.update(updateData);
        print('✅ Admin login updated');
      }

      await _recordAdminLoginHistory(user.uid, userEmail, 'login');

      print('✅ Admin info saved successfully');
    } catch (e) {
      print('❌ Error saving admin info: $e');
      rethrow;
    }
  }

  static Future<void> _recordAdminLoginHistory(
    String uid,
    String email,
    String action,
  ) async {
    try {
      final now = DateTime.now();
      final timestamp = now.millisecondsSinceEpoch;
      final dateDetails = _formatDateDetails(now);

      final historyRef = _databaseRef
          .child('admins_login_history')
          .child(uid)
          .child(timestamp.toString());

      final historyData = {
        'uid': uid,
        'email': email,
        'action': action,
        'timestamp': timestamp,
        'date': dateDetails['shortDate'],
        'fullDate': dateDetails['fullDate'],
        'time': dateDetails['time'],
        'dateTime': dateDetails['dateTime'],
      };

      await historyRef.set(historyData);
      print('📝 Admin login history recorded: $action for $email');
    } catch (e) {
      print('❌ Error recording admin login history: $e');
    }
  }

  // -----------------------------
  // STATUS OFFLINE (LOGOUT)
  // -----------------------------
  static Future<void> updateStudentStatusOffline(String uid) async {
    try {
      final studentRef = _databaseRef.child('students').child(uid);
      final now = DateTime.now();
      final timestamp = now.millisecondsSinceEpoch;
      final dateDetails = _formatDateDetails(now);

      final updateData = {
        'status': 'offline',
        'lastLogoutAt': timestamp,
        'lastLogoutDate': dateDetails['shortDate'],
        'lastLogoutTime': dateDetails['time'],
        'updatedAt': timestamp,
        'updatedDate': dateDetails['shortDate'],
      };

      await studentRef.update(updateData);

      final snapshot = await studentRef.child('email').get();
      final email = snapshot.value as String? ?? '';

      await _recordStudentLogoutHistory(uid, email, timestamp, dateDetails);

      print('✅ Student status updated to offline for: $email');
    } catch (e) {
      print('❌ Error updating student status: $e');
    }
  }

  static Future<void> updateAdminStatusOffline(String uid) async {
    try {
      final adminRef = _databaseRef.child('admins').child(uid);
      final now = DateTime.now();
      final timestamp = now.millisecondsSinceEpoch;
      final dateDetails = _formatDateDetails(now);

      final updateData = {
        'status': 'offline',
        'lastLogoutAt': timestamp,
        'lastLogoutDate': dateDetails['shortDate'],
        'lastLogoutTime': dateDetails['time'],
        'updatedAt': timestamp,
        'updatedDate': dateDetails['shortDate'],
      };

      await adminRef.update(updateData);

      final snapshot = await adminRef.child('email').get();
      final email = snapshot.value as String? ?? '';

      await _recordAdminLogoutHistory(uid, email, timestamp, dateDetails);

      print('✅ Admin status updated to offline for: $email');
    } catch (e) {
      print('❌ Error updating admin status: $e');
    }
  }

  static Future<void> _recordStudentLogoutHistory(
    String uid,
    String email,
    int timestamp,
    Map<String, String> dateDetails,
  ) async {
    try {
      final historyRef = _databaseRef
          .child('students_login_history')
          .child(uid)
          .child(timestamp.toString());

      final historyData = {
        'uid': uid,
        'email': email,
        'action': 'logout',
        'timestamp': timestamp,
        'date': dateDetails['shortDate'],
        'fullDate': dateDetails['fullDate'],
        'time': dateDetails['time'],
        'dateTime': dateDetails['dateTime'],
      };

      await historyRef.set(historyData);
      print('📝 Student logout history recorded for: $email');
    } catch (e) {
      print('⚠️ Could not record student logout history: $e');
    }
  }

  static Future<void> _recordAdminLogoutHistory(
    String uid,
    String email,
    int timestamp,
    Map<String, String> dateDetails,
  ) async {
    try {
      final historyRef = _databaseRef
          .child('admins_login_history')
          .child(uid)
          .child(timestamp.toString());

      final historyData = {
        'uid': uid,
        'email': email,
        'action': 'logout',
        'timestamp': timestamp,
        'date': dateDetails['shortDate'],
        'fullDate': dateDetails['fullDate'],
        'time': dateDetails['time'],
        'dateTime': dateDetails['dateTime'],
      };

      await historyRef.set(historyData);
      print('📝 Admin logout history recorded for: $email');
    } catch (e) {
      print('⚠️ Could not record admin logout history: $e');
    }
  }
}
