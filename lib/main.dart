import 'package:flutter/material.dart';
import 'loginScreen/loginUser.dart';

void main() {
  runApp(const DnscEvents());
}

class DnscEvents extends StatelessWidget {
  const DnscEvents({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LoginUser(),
    );
  }
}
