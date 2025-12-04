import 'package:dnsc_events/adminScreen/eventsPage.dart';
import 'package:dnsc_events/adminScreen/homePage.dart';
import 'package:dnsc_events/adminScreen/profileAdmin.dart';
import 'package:dnsc_events/adminScreen/users.dart';
import 'package:dnsc_events/widget/bottomBar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ADD THIS
import 'package:dnsc_events/login.dart';
import 'package:dnsc_events/adminScreen/transaction.dart';
import 'package:dnsc_events/database/auth.dart';
// ADD THIS

class Admin extends StatefulWidget {
  final int initialIndex;
  const Admin({super.key, this.initialIndex = 0});

  @override
  State<Admin> createState() => _AdminState();
}

class _AdminState extends State<Admin> {
  late int _selectedIndex = 0;
  bool _checkingAuth = false;

  final List<Widget> pages = [
    const Homepageadmin(),
    const Eventadmin(),
    const Transaction(),
    const Profileadmin(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    setState(() {
      _checkingAuth = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    final user = FirebaseAuth.instance.currentUser;

    // No user → kick to login
    if (user == null && mounted) {
      print('⚠️ Admin: No user logged in, redirecting to login');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
          (route) => false,
        );
      });
    } else if (user != null && mounted) {
      final email = (user.email ?? '').trim().toLowerCase();
      final allowedAdmins = AuthService.adminEmail
          .map((e) => e.trim().toLowerCase())
          .toList();

      // ❌ Logged-in user is not in admin list
      if (!allowedAdmins.contains(email)) {
        print('❌ Admin: User $email is not admin, redirecting to login');

        await FirebaseAuth.instance.signOut();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Login()),
            (route) => false,
          );
        });
      } else {
        print('✅ Admin: Admin user verified: $email');
      }
    }

    if (mounted) {
      setState(() {
        _checkingAuth = false;
      });
    }
  }

  void _tapItem(int index) {
    if (_selectedIndex == index) {
      if (index == 0) {
        setState(() {
          pages[0] = Homepageadmin(key: UniqueKey());
        });
      }
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomBarAdmin(
        selectedIndex: _selectedIndex,
        tapItem: _tapItem,
      ),
    );
  }
}
