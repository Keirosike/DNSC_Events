import 'package:flutter/material.dart';
import 'package:dnsc_events/database/auth.dart';
import 'package:dnsc_events/student.dart';
import 'package:dnsc_events/colors/color.dart';
import 'package:dnsc_events/admin.dart';

import 'package:dnsc_events/database/record_info_login.dart';

class GoogleLoginButtons extends StatefulWidget {
  final int initialIndex;
  const GoogleLoginButtons({super.key, this.initialIndex = 0});

  @override
  State<GoogleLoginButtons> createState() => _GoogleLoginButtonsState();
}

class _GoogleLoginButtonsState extends State<GoogleLoginButtons> {
  String? activeButton;

  void setActive(String type) {
    setState(() => activeButton = type);
    Future.delayed(
      const Duration(seconds: 1),
      () => setState(() => activeButton = null),
    );
  }

  // STUDENT LOGIN
  Future<void> _loginStudent(BuildContext context) async {
    setActive("student");
    try {
      final userCredential = await AuthService.loginStudent(context);
      if (userCredential != null && userCredential.user != null) {
        final user = userCredential.user!;
        print('✅ Student login successful: ${user.email}');

        try {
          // Save student info to database (moved to service)
          await UserDatabaseService.saveStudentInfo(user);

          // Navigate to student home
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Student(initialIndex: 0)),
          );
        } catch (e) {
          print('❌ Error saving student info: $e');
          // Still navigate even if saving fails
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Student(initialIndex: 0)),
          );
        }
      } else {
        print('❌ Student login failed - no user credential returned');
      }
    } catch (e) {
      print('❌ Student login error: $e');
    }
  }

  // ADMIN LOGIN
  Future<void> _loginAdmin(BuildContext context) async {
    setActive("admin");
    try {
      final userCredential = await AuthService.loginAdmin(context);
      if (userCredential != null && userCredential.user != null) {
        final user = userCredential.user!;
        print('✅ Admin login successful: ${user.email}');

        try {
          // Save admin info to database (moved to service)
          await UserDatabaseService.saveAdminInfo(user);

          // Navigate to admin panel
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Admin()),
          );
        } catch (e) {
          print('❌ Error saving admin info: $e');
          // Still navigate even if saving fails
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Admin()),
          );
        }
      } else {
        print('❌ Admin login failed - no user credential returned');
      }
    } catch (e) {
      print('❌ Admin login error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // STUDENT BUTTON
        InkWell(
          onTap: () => _loginStudent(context),
          child: _loginButton(
            "Continue with DNSC Google (Students)",
            activeButton == "student",
          ),
        ),

        const SizedBox(height: 18),

        // ADMIN BUTTON
        InkWell(
          onTap: () => _loginAdmin(context),
          child: _loginButton(
            "Continue with DNSC Google (Admin)",
            activeButton == "admin",
          ),
        ),
      ],
    );
  }

  // REUSABLE BUTTON UI
  Widget _loginButton(String text, bool active) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: active ? CustomColor.borderGray : Colors.white,
        border: Border.all(color: CustomColor.borderGray1, width: 1),
      ),
      child: Row(
        children: [
          Image.asset('assets/image/google.png', height: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
