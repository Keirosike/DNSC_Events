import 'package:dnsc_events/firebase_options.dart';
import 'package:dnsc_events/student.dart';
import 'package:dnsc_events/studentScreen/eventsPage.dart';
import 'package:dnsc_events/studentScreen/myTicket.dart';
import 'package:dnsc_events/studentScreen/orderSummary.dart';
import 'package:flutter/material.dart';
import 'login.dart';
import 'studentScreen/homePage.dart';
import 'widget/bottomBar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dnsc_events/widget/calendar.dart';

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
      home: const Myticket(),
      theme: ThemeData(fontFamily: 'Inter'),
    );
  }
}
