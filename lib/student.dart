import 'package:dnsc_events/studentScreen/profile.dart';
import 'package:flutter/material.dart';
import 'package:dnsc_events/studentScreen/homePage.dart';
import 'package:dnsc_events/studentScreen/eventsPage.dart';
import 'package:dnsc_events/widget/bottomBar.dart';
import 'package:dnsc_events/studentScreen/myTicket.dart';
import 'package:dnsc_events/login.dart'; // ADD THIS IMPORT
import 'package:firebase_auth/firebase_auth.dart'; // ADD THIS IMPORT

class Student extends StatefulWidget {
  final int initialIndex;
  const Student({super.key, this.initialIndex = 0});

  @override
  State<Student> createState() => _StudentState();
}

class _StudentState extends State<Student> {
  late int _selectedIndex = 0;

  // ADD THIS: Authentication check
  bool _checkingAuth = false;

  final List<Widget> pages = [
    const Homepage(),
    const Eventspage(),
    const Myticket(),
    const Profile(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    // ADD THIS: Check authentication on init
    _checkAuthentication();
  }

  // ADD THIS METHOD: Check if user is authenticated
  Future<void> _checkAuthentication() async {
    setState(() {
      _checkingAuth = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    final user = FirebaseAuth.instance.currentUser;

    if (user == null && mounted) {
      print('⚠️ Student: No user logged in, redirecting to login');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
          (route) => false,
        );
      });
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
          pages[0] = Homepage(key: UniqueKey());
        });
      }
    } else {
      // Switch to another tab
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomBar(
        selectedIndex: _selectedIndex,
        tapItem: _tapItem,
      ),
    );
  }
}
