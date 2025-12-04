import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:dnsc_events/colors/color.dart';
import 'package:dnsc_events/widget/calendar.dart';
import 'package:dnsc_events/widget/appbar.dart';
import 'package:dnsc_events/database/event_service.dart';
import 'package:dnsc_events/student.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

/// Simple model for user summary (separate DB node)
class UserSummary {
  final int ticketsPurchased;
  final double totalSpent;
  final int eventsAttended;
  final int pendingPayments;

  const UserSummary({
    required this.ticketsPurchased,
    required this.totalSpent,
    required this.eventsAttended,
    required this.pendingPayments,
  });

  factory UserSummary.empty() => const UserSummary(
    ticketsPurchased: 0,
    totalSpent: 0,
    eventsAttended: 0,
    pendingPayments: 0,
  );

  factory UserSummary.fromMap(Map<dynamic, dynamic> map) {
    int _toInt(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      if (v is double) return v.toInt();
      return 0;
    }

    double _toDouble(dynamic v) {
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    return UserSummary(
      ticketsPurchased: _toInt(map['tickets_bought']),
      totalSpent: _toDouble(map['total_spent']),
      eventsAttended: _toInt(map['events_attended']),
      pendingPayments: _toInt(map['pending_payments']),
    );
  }
}

class _HomepageState extends State<Homepage> {
  final EventService _eventService = EventService();
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  bool isLoading = true;

  /// Upcoming events pulled from DB (max 4)
  List<Map<String, dynamic>> _upcomingEvents = [];

  /// Per-user summary
  UserSummary? _userSummary;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final eventsFuture = _eventService.getUpcomingEvents(
        maxCount: 4,
      ); // only upcoming
      final summaryFuture = _loadUserSummary();

      final results = await Future.wait([eventsFuture, summaryFuture]);

      if (!mounted) return;

      setState(() {
        _upcomingEvents = results[0] as List<Map<String, dynamic>>;
        _userSummary = results[1] as UserSummary;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading homepage data: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Fetch user summary from a separate node.
  /// Adjust the path if you use a different structure.
  ///
  /// Example DB path:
  /// user_summaries/{uid}/{
  ///   tickets_purchased: 2,
  ///   total_spent: 30000,
  ///   events_attended: 2,
  ///   pending_payments: 2
  /// }
  Future<UserSummary> _loadUserSummary() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return UserSummary.empty();
    }

    try {
      // USER -> {uid} -> SUMMARY
      final snapshot = await _db
          .child('users')
          .child(user.uid)
          .child('summary')
          .get();

      if (!snapshot.exists || snapshot.value == null) {
        return UserSummary.empty();
      }

      final value = snapshot.value;
      if (value is Map) {
        return UserSummary.fromMap(value);
      }
      return UserSummary.empty();
    } catch (e) {
      print('Error loading user summary: $e');
      return UserSummary.empty();
    }
  }

  bool get _enableCarousel => _upcomingEvents.length >= 3;

  @override
  Widget build(BuildContext context) {
    // Show loading screen while isLoading is true
    if (isLoading) {
      return Scaffold(
        backgroundColor: CustomColor.background,
        appBar: Appbar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [CircularProgressIndicator(color: CustomColor.primary)],
          ),
        ),
      );
    }

    // Show actual content when loading is complete
    return Scaffold(
      backgroundColor: CustomColor.background,
      appBar: Appbar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    "Welcome ",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontFamily: 'InterExtra',
                      fontSize: 24,
                    ),
                  ),
                  Text(
                    "Back",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontFamily: 'InterExtra',
                      fontSize: 24,
                      color: CustomColor.primary,
                    ),
                  ),
                  Text(
                    "!",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontFamily: 'InterExtra',
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              realStatsLayout(_userSummary ?? UserSummary.empty()),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    "Upcoming",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'InterExtra',
                    ),
                  ),
                  Text(
                    " Events",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: CustomColor.primary,
                      fontFamily: 'InterExtra',
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Student(initialIndex: 1),
                        ),
                      );
                    },
                    child: Icon(
                      Icons.chevron_right_outlined,
                      color: CustomColor.primary,
                      size: 30,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              /// CAROUSEL FROM EVENTS (ONLY UPCOMING, MAX 4)
              if (_upcomingEvents.isEmpty)
                Container(
                  height: 150,
                  alignment: Alignment.center,
                  child: Text(
                    "No upcoming events",
                    style: TextStyle(
                      fontSize: 14,
                      color: CustomColor.subtextColor,
                    ),
                  ),
                )
              else
                CarouselSlider.builder(
                  itemCount: _upcomingEvents.length,
                  itemBuilder: (context, index, realIndex) {
                    final Map<String, dynamic> event = _upcomingEvents[index];
                    final String? base64Image =
                        (event['event_image'] as String?) ?? '';

                    ImageProvider imageProvider;
                    if (base64Image != null && base64Image.isNotEmpty) {
                      try {
                        imageProvider = MemoryImage(base64Decode(base64Image));
                      } catch (e) {
                        print(
                          'Error decoding base64 event image (${event['key']}): $e',
                        );
                        imageProvider = const AssetImage(
                          'assets/image/example.png',
                        );
                      }
                    } else {
                      imageProvider = const AssetImage(
                        'assets/image/example.png',
                      );
                    }

                    return GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const Student(initialIndex: 1),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                  options: CarouselOptions(
                    height: 150,
                    viewportFraction: 0.40,
                    autoPlay: _enableCarousel,
                    autoPlayInterval: const Duration(seconds: 5),
                    autoPlayAnimationDuration: const Duration(seconds: 5),
                    enableInfiniteScroll: _enableCarousel,
                  ),
                ),

              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    "Event ",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'InterExtra',
                    ),
                  ),
                  Text(
                    "Calendar",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: CustomColor.primary,
                      fontFamily: 'InterExtra',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Calendar(),
            ],
          ),
        ),
      ),
    );
  }
}

/// REAL STATS LAYOUT – now uses [UserSummary] from DB
Widget realStatsLayout(UserSummary summary) {
  return Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      // upper-left
      Container(
        height: 90,
        width: 165,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(width: 1, color: CustomColor.borderGray),
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              spreadRadius: 1,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ticket Purchases",
                    style: TextStyle(
                      fontSize: 13,
                      color: CustomColor.subtextColor,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.confirmation_num_outlined,
                    color: Color(0xFF4726BF),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                summary.ticketsPurchased.toString(),
                style: const TextStyle(
                  fontSize: 24,
                  fontFamily: 'InterExtra',
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4726BF),
                ),
              ),
            ],
          ),
        ),
      ),
      // upper-right
      Container(
        height: 90,
        width: 165,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(width: 1, color: CustomColor.borderGray),
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              spreadRadius: 1,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total Spent",
                    style: TextStyle(
                      fontSize: 13,
                      color: CustomColor.subtextColor,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.payments_outlined, color: Color(0xFF960E0E)),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                "₱${summary.totalSpent.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 24,
                  fontFamily: 'InterExtra',
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF960E0E),
                ),
              ),
            ],
          ),
        ),
      ),
      // bottom-left
      Container(
        height: 90,
        width: 165,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(width: 1, color: CustomColor.borderGray),
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              spreadRadius: 1,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Events Attended",
                    style: TextStyle(
                      fontSize: 13,
                      color: CustomColor.subtextColor,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.event_outlined, color: Color(0xFF056405)),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                summary.eventsAttended.toString(),
                style: const TextStyle(
                  fontSize: 24,
                  fontFamily: 'InterExtra',
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF056405),
                ),
              ),
            ],
          ),
        ),
      ),
      // bottom-right
      Container(
        height: 90,
        width: 165,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(width: 1, color: CustomColor.borderGray),
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              spreadRadius: 1,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Pending Payments",
                    style: TextStyle(
                      fontSize: 13,
                      color: CustomColor.subtextColor,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.warning_amber_outlined,
                    color: Colors.orange.shade700,
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                '₱${summary.pendingPayments.toString()}',
                style: TextStyle(
                  fontSize: 24,
                  fontFamily: 'InterExtra',
                  fontWeight: FontWeight.w800,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
