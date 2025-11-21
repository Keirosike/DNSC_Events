import 'package:flutter/material.dart';
import 'package:dnsc_events/studentScreen/homePage.dart';
import 'package:dnsc_events/studentScreen/eventsPage.dart';
import 'package:dnsc_events/widget/bottomBar.dart';

class Student extends StatefulWidget {
  const Student({super.key});

  @override
  State<Student> createState() => _StudentState();
}

class _StudentState extends State<Student> {
  int _selectedIndex = 0;

  final List<Widget> pages = [const Homepage(), const Eventspage()];

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
