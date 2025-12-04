import 'package:dnsc_events/adminScreen/createEvent.dart';
import 'package:dnsc_events/adminScreen/eventsPage.dart';
import 'package:dnsc_events/adminScreen/qrCode.dart';
import 'package:dnsc_events/adminScreen/transactioDetails.dart';
import 'package:dnsc_events/firebase_options.dart';
import 'package:dnsc_events/student.dart';
import 'package:dnsc_events/studentScreen/eventsPage.dart';
import 'package:dnsc_events/studentScreen/myTicket.dart';
import 'package:dnsc_events/studentScreen/orderSummary.dart';
import 'package:dnsc_events/studentScreen/profile.dart';
import 'package:dnsc_events/studentScreen/viewDetails.dart';
import 'package:dnsc_events/studentScreen/viewTicket.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';
import 'studentScreen/homePage.dart';
import 'widget/bottomBar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dnsc_events/widget/calendar.dart';
import 'package:dnsc_events/admin.dart';
import 'package:dnsc_events/database/auth.dart'; // ✅ NEW: to access AuthService.adminEmail

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const DnscEvents());
}

class DnscEvents extends StatelessWidget {
  const DnscEvents({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
      theme: ThemeData(fontFamily: 'Inter'),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print('Auth state changed: ${snapshot.connectionState}');

        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('Checking auth state...');
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF008080)),
                  SizedBox(height: 20),
                  Text(
                    'Checking login status...',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        }

        // Debug print
        if (snapshot.hasData) {
          print('✅ User found: ${snapshot.data!.email}');
        } else {
          print('ℹ️ No user found, showing login screen');
        }

        // If no data or user is null, show login screen
        if (!snapshot.hasData || snapshot.data == null) {
          return const Login();
        }

        // User is logged in
        final user = snapshot.data!;
        final email = (user.email ?? '').trim().toLowerCase();

        // ✅ Normalize admin list for comparison
        final adminEmails = AuthService.adminEmail
            .map((e) => e.trim().toLowerCase())
            .toList();

        final bool isAdmin = adminEmails.contains(email);
        final bool isStudent =
            email.endsWith('@dnsc.edu.ph') &&
            !isAdmin; // student = dnsc email & not admin

        // ADMIN FLOW
        if (isAdmin) {
          print('🛠️ Admin detected ($email), redirecting to admin panel');
          return const Admin();
        }
        // STUDENT FLOW
        else if (isStudent) {
          print('🎓 Student detected ($email), redirecting to student home');
          return const Student();
        }
        // INVALID EMAIL (NEITHER ADMIN NOR STUDENT)
        else {
          print(
            '❌ Invalid email format: $email (not admin & not @dnsc.edu.ph)',
          );
          FirebaseAuth.instance.signOut();
          return const Login();
        }
      },
    );
  }
}
