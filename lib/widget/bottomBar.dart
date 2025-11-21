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
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent, // removes tap ripple
        highlightColor: Colors.transparent, // removes tap highlight
      ),

      child: BottomNavigationBar(
        backgroundColor: Colors.white,
        elevation: 24,
        currentIndex: widget.selectedIndex,
        onTap: widget.tapItem,
        selectedItemColor: CustomColor.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: "Events",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number_outlined),
            label: "Tickets",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
