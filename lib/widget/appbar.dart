import 'package:dnsc_events/admin.dart';
import 'package:dnsc_events/student.dart';
import 'package:flutter/material.dart';
import 'package:dnsc_events/database/logout.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dnsc_events/adminScreen/users.dart';

class Appbar extends StatelessWidget implements PreferredSizeWidget {
  const Appbar({super.key});
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    // Get current user email
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      scrolledUnderElevation: 0,
      title: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const Student(initialIndex: 0),
                ),
                (route) => false,
              );
            },
            child: Image.asset('assets/image/dnscEvents.png', height: 60),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const Student(initialIndex: 1),
                ),
                (route) => false,
              );
            },
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 20,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 15),
          // Logout Button - using the imported LogoutDialog
          GestureDetector(
            onTap: () => LogoutDialog.show(
              context: context,
              isAdmin: false,
              userEmail: userEmail,
            ),
            child: const Icon(
              Icons.logout_outlined,
              size: 20,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class Appbaradmin extends StatefulWidget implements PreferredSizeWidget {
  const Appbaradmin({super.key});
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<Appbaradmin> createState() => _AppbaradminState();
}

class _AppbaradminState extends State<Appbaradmin> {
  @override
  Widget build(BuildContext context) {
    // Get current user email
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      scrolledUnderElevation: 0,
      title: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const Student(initialIndex: 0),
                ),
                (route) => false,
              );
            },
            child: Image.asset('assets/image/dnscEvents.png', height: 60),
          ),
          Spacer(),

          const SizedBox(width: 15),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Userlogged()),
              );
            },
            child: Icon(Icons.people_outline, size: 20, color: Colors.black),
          ),
          const SizedBox(width: 15),
          // Logout Button for Admin - using the imported LogoutDialog
          GestureDetector(
            onTap: () => LogoutDialog.show(
              context: context,
              isAdmin: true, // Set to true for admin
              userEmail: userEmail,
            ),
            child: const Icon(
              Icons.logout_outlined,
              size: 20,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
