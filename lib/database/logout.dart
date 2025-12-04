import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dnsc_events/login.dart';
import 'package:dnsc_events/colors/color.dart';

class LogoutDialog {
  // Show logout confirmation dialog
  static void show({
    required BuildContext context,
    bool isAdmin = false,
    String userEmail = '',
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: CustomColor.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isAdmin
                    ? Icons.admin_panel_settings_rounded
                    : Icons.logout_rounded,
                color: CustomColor.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isAdmin ? 'Admin Logout' : 'Logout',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAdmin
                  ? 'Are you sure you want to logout from admin panel?'
                  : 'Are you sure you want to logout from your account?',
              style: const TextStyle(fontSize: 15),
            ),
            if (userEmail.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Email: $userEmail',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _performLogout(context, isAdmin: isAdmin);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CustomColor.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  children: [
                    Icon(Icons.logout, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Logout',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Perform logout function
  static Future<void> _performLogout(
    BuildContext context, {
    required bool isAdmin,
  }) async {
    print('${isAdmin ? 'ADMIN: ' : ''}Starting logout process...');

    try {
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();
      print('✅ ${isAdmin ? 'ADMIN: ' : ''}Firebase sign out successful');

      // Navigate to login and clear all routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false,
      );

      print('✅ ${isAdmin ? 'ADMIN: ' : ''}Navigation to login completed');
    } catch (e) {
      print('❌ ${isAdmin ? 'ADMIN: ' : ''}Logout failed: $e');

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
