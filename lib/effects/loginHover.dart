import 'package:dnsc_events/studentScreen/eventsPage.dart';
import 'package:dnsc_events/studentScreen/homePage.dart';
import 'package:flutter/material.dart';
import 'package:dnsc_events/colors/color.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dnsc_events/student.dart';

class GoogleLoginButtons extends StatefulWidget {
  const GoogleLoginButtons({super.key});

  @override
  State<GoogleLoginButtons> createState() => _GoogleLoginButtonsState();
}

class _GoogleLoginButtonsState extends State<GoogleLoginButtons> {
  String? activeButton; // 'student' or 'admin'

  void setActive(String button) {
    setState(() {
      activeButton = button;
    });

    // Reset highlight after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        activeButton = null;
      });
    });
  }

  //student credentials
  Future<UserCredential?> loginStudent() async {
    try {
      await GoogleSignIn().signOut();
      final GoogleSignInAccount? googleuser = await GoogleSignIn().signIn();

      if (googleuser == null) {
        return null;
      }

      if (!googleuser.email.endsWith('@dnsc.edu.ph')) {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20), // Rounded corners
            ),
            elevation: 10,
            backgroundColor: Colors.white,
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.redAccent, // Modern icon for error
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Sign-in Failed',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Invalid Gmail. Please use your dnsc.edu.ph account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        return null;
      } else if (googleuser.email == 'robles.kurtzidrick@dnsc.edu.ph') {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20), // Rounded corners
            ),
            elevation: 10,
            backgroundColor: Colors.white,
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.redAccent, // Modern icon for error
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Sign-in Failed',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Invalid Gmail.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleuser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      return null;
    }
  }

  Future<UserCredential?> loginAdmin() async {
    try {
      await GoogleSignIn().signOut();

      final GoogleSignInAccount? googleuser = await GoogleSignIn().signIn();

      if (googleuser == null) {
        return null;
      }

      if (!googleuser.email.endsWith('@dnsc.edu.ph')) {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20), // Rounded corners
            ),
            elevation: 10,
            backgroundColor: Colors.white,
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.redAccent, // Modern icon for error
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Sign-in Failed',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Invalid Gmail. Please use your dnsc.edu.ph account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleuser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      if (googleuser.email == 'robles.kurtzidrick@dnsc.edu.ph') {
        return await FirebaseAuth.instance.signInWithCredential(credential);
      } else {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20), // Rounded corners
            ),
            elevation: 10,
            backgroundColor: Colors.white,
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.redAccent, // Modern icon for error
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Sign-in Failed',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Invalid Gmail.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        return null;
      }
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Student Button
        InkWell(
          onTap: () async {
            setActive('student');

            final UserCredential = await loginStudent();
            if (UserCredential != null) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => Student()),
                (route) => false,
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16),
            constraints: BoxConstraints(maxHeight: 48),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: activeButton == 'student'
                  ? CustomColor.borderGray
                  : Colors.white,
              border: Border.all(color: CustomColor.borderGray1, width: 1),
            ),
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Image.asset(
                    'assets/image/google.png',
                    height: 70,
                    width: 18,
                  ),
                ),
                Text(
                  "Continue with DNSC Google (Students)",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 18),

        // Admin Button
        InkWell(
          onTap: () async {
            setActive('admin');
            final UserCredential = await loginAdmin();
            if (UserCredential != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => Eventspage()),
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16),
            constraints: BoxConstraints(maxHeight: 48),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: activeButton == 'admin'
                  ? CustomColor.borderGray
                  : Colors.white,
              border: Border.all(color: CustomColor.borderGray1, width: 1),
            ),
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Image.asset(
                    'assets/image/google.png',
                    height: 70,
                    width: 18,
                  ),
                ),
                Text(
                  "Continue with DNSC Google (Admin)",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
