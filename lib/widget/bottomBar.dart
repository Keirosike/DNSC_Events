import 'package:flutter/material.dart';
import 'package:dnsc_events/colors/color.dart';

class BottomBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) tapItem;
  const BottomBar({
    super.key,
    required this.selectedIndex,
    required this.tapItem,
  });

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  static const List<BottomNavigationBarItem> _navItems = [
    BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"),
    BottomNavigationBarItem(
      icon: Icon(Icons.calendar_today_outlined),
      label: "Events",
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.confirmation_number_outlined),
      label: "Tickets",
    ),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),

      child: BottomNavigationBar(
        backgroundColor: Colors.white,
        elevation: 24,
        currentIndex: widget.selectedIndex >= 0 ? widget.selectedIndex : 0,
        onTap: widget.tapItem,
        selectedItemColor: CustomColor.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: _navItems,
      ),
    );
  }
}

class BottomBarAdmin extends StatefulWidget {
  final int selectedIndex;
  final Function(int) tapItem;
  const BottomBarAdmin({
    super.key,
    required this.selectedIndex,
    required this.tapItem,
  });

  @override
  State<BottomBarAdmin> createState() => _BottomBarAdminState();
}

class _BottomBarAdminState extends State<BottomBarAdmin> {
  static const List<BottomNavigationBarItem> _navItems = [
    BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"),
    BottomNavigationBarItem(
      icon: Icon(Icons.calendar_today_outlined),
      label: "Events",
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.payment_outlined),
      label: "Transactions",
    ),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
  ];

  @override
  Widget build(BuildContext context) {
    // Create a custom theme when selectedIndex is negative
    if (widget.selectedIndex < 0) {
      return Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          // Force all tabs to be grey
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            selectedItemColor: Colors.grey,
            unselectedItemColor: Colors.grey,
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          elevation: 24,
          currentIndex: 0, // Set to 0 but color overrides make it irrelevant
          onTap: widget.tapItem,
          type: BottomNavigationBarType.fixed,
          items: _navItems,
        ),
      );
    }

    // Normal behavior when selectedIndex is 0-3
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),

      child: BottomNavigationBar(
        backgroundColor: Colors.white,
        elevation: 24,
        currentIndex: widget.selectedIndex,
        onTap: widget.tapItem,
        selectedItemColor: CustomColor.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: _navItems,
      ),
    );
  }
}
