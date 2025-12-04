import 'package:flutter/material.dart';
import 'package:dnsc_events/colors/color.dart';
import 'package:dnsc_events/widget/calendar.dart';
import 'package:dnsc_events/widget/appbar.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:dnsc_events/database/admin_summary.dart'; // TransactionService
import 'package:dnsc_events/database/event_service.dart'; // EventService
import 'package:dnsc_events/database/transactionGet.dart'; // TransactionRecord + transactionFetchService
import 'package:dnsc_events/admin.dart';

class Homepageadmin extends StatefulWidget {
  const Homepageadmin({super.key});

  @override
  State<Homepageadmin> createState() => _HomepageadminState();
}

class _HomepageadminState extends State<Homepageadmin> {
  bool isLoading = true;

  // Events (upcoming, for recent events section)
  final EventService _eventService = EventService();
  late Future<List<Map<String, dynamic>>> _recentEventsFuture;

  // Transactions (for recent transaction card)
  late Future<List<TransactionRecord>> _recentTransactionsFuture;

  @override
  void initState() {
    super.initState();

    // Get up to 3 upcoming events
    _recentEventsFuture = _eventService.getUpcomingEvents(maxCount: 3);

    // Fetch all transactions (sorted by created_at desc in service)
    _recentTransactionsFuture = transactionFetchService.fetchAllTransactions();

    _initDashboard();
  }

  Future<void> _initDashboard() async {
    try {
      // Recompute total_revenue & total_pending from transactions
      await TransactionService.updateAdminSummaryFromTransactions();
    } catch (e) {
      print('Error initializing dashboard summary: $e');
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while isLoading is true
    if (isLoading) {
      return Scaffold(
        backgroundColor: CustomColor.background,
        appBar: Appbaradmin(),
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
      appBar: Appbaradmin(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    "Admin ",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontFamily: 'InterExtra',
                      fontSize: 24,
                    ),
                  ),
                  Text(
                    "Dashboard",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontFamily: 'InterExtra',
                      fontSize: 24,
                      color: CustomColor.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // SUMMARY CARDS (events, revenue, active users, pending)
              realStatsLayout(),
              const SizedBox(height: 10),

              // ======================
              // RECENT EVENTS (DYNAMIC)
              // ======================
              Row(
                children: [
                  Text(
                    "Recent",
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
                          builder: (context) => const Admin(initialIndex: 1),
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
              const SizedBox(height: 5),

              FutureBuilder<List<Map<String, dynamic>>>(
                future: _recentEventsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: CustomColor.primary,
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Failed to load recent events',
                        style: TextStyle(
                          color: Colors.red.shade400,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }

                  final events = snapshot.data ?? [];

                  if (events.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.event_busy_outlined,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'No recent events',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Show up to 3 event cards (already limited in service)
                  return Column(
                    children: events
                        .map((event) => _buildEventCard(context, event))
                        .toList(),
                  );
                },
              ),

              const SizedBox(height: 10),

              // ==========================
              // RECENT TRANSACTION (DYNAMIC)
              // ==========================
              Row(
                children: [
                  Text(
                    "Recent",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'InterExtra',
                    ),
                  ),
                  Text(
                    " Transactions",
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
                          builder: (context) => const Admin(initialIndex: 2),
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

              const SizedBox(height: 5),

              FutureBuilder<List<TransactionRecord>>(
                future: _recentTransactionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: CustomColor.primary,
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Failed to load recent transactions',
                        style: TextStyle(
                          color: Colors.red.shade400,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }

                  final txList = snapshot.data ?? [];

                  if (txList.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'No recent transactions',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // 🔥 LIMIT TO 3 MOST RECENT TRANSACTIONS
                  final top3 = txList.take(3).toList();

                  return Column(
                    children: top3
                        .map((tx) => _buildRecentTransactionCard(tx))
                        .toList(),
                  );
                },
              ),

              const SizedBox(height: 10),

              // CALENDAR
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

              const Calendar(),
            ],
          ),
        ),
      ),
    );
  }

  // ====== EVENT CARD (for Recent Events) ======
  Widget _buildEventCard(BuildContext context, Map<String, dynamic> event) {
    // Title
    final String title =
        event['event_name']?.toString() ??
        event['name']?.toString() ??
        'Untitled Event';

    // Time text
    final String timeText =
        event['event_start_time']?.toString() ??
        event['time']?.toString() ??
        '';

    // Location
    final String location =
        event['event_location']?.toString() ?? 'To be announced';

    // Date
    DateTime? dt;
    if (event['_event_ts'] is int) {
      dt = DateTime.fromMillisecondsSinceEpoch(event['_event_ts'] as int);
    } else if (event['event_date'] != null) {
      dt = DateTime.tryParse(event['event_date'].toString());
    }

    String monthText = '--';
    String dayText = '--';

    if (dt != null) {
      monthText = _monthShortName(dt.month);
      dayText = dt.day.toString().padLeft(2, '0');
    }
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Admin(initialIndex: 1)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        height: 88,
        decoration: BoxDecoration(
          color: CustomColor.primary,
          borderRadius: const BorderRadius.horizontal(
            left: Radius.circular(12),
            right: Radius.circular(12),
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              spreadRadius: 1,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Container(
            padding: const EdgeInsets.only(left: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  // Date box
                  Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: CustomColor.primary,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          monthText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          dayText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Event Info
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_filled_outlined,
                                size: 14,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                timeText.isEmpty ? 'Time not set' : timeText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  location,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ====== RECENT TRANSACTION CARD (LEFT LAYOUT) ======
  Widget _buildRecentTransactionCard(TransactionRecord tx) {
    // Top-left text: prefer ticketCode, else transactionId
    final String topLeftId = tx.transactionId.isNotEmpty
        ? '#${tx.transactionId}'
        : '#${tx.transactionId}';

    // Right side date text: use transactionDate if present
    final String dateText = tx.transactionDate.isNotEmpty
        ? tx.transactionDate
        : '';

    // Amount display: formattedAmount or fallback
    final String amountText = tx.formattedAmount.isNotEmpty
        ? tx.formattedAmount
        : '₱${tx.amount.toStringAsFixed(2)}';

    // Status pill
    final String statusText = tx.status.isNotEmpty ? tx.status : 'Unknown';
    final bool isPaid = statusText.toLowerCase() == 'paid';

    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Admin(initialIndex: 2)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        height: 88,
        decoration: BoxDecoration(
          color: CustomColor.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              spreadRadius: 1,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 5),
              child: Container(
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT SIDE (ID, Name, Event)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topLeftId,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            tx.userName.isNotEmpty
                                ? tx.userName
                                : 'Unknown User',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tx.eventName.isNotEmpty
                                ? tx.eventName.toUpperCase()
                                : 'UNKNOWN EVENT',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // RIGHT SIDE (Amount, Date)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            amountText,
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            dateText,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // STATUS PILL
          ],
        ),
      ),
    );
  }

  String _monthShortName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month < 1 || month > 12) return '--';
    return months[month - 1];
  }
}

// ====== SUMMARY STATS LAYOUT (admins/summary) ======
Widget realStatsLayout() {
  final DatabaseReference summaryRef = FirebaseDatabase.instance
      .ref()
      .child('admins')
      .child('summary');

  return StreamBuilder<DatabaseEvent>(
    stream: summaryRef.onValue,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(
          child: CircularProgressIndicator(color: CustomColor.primary),
        );
      }

      Map<String, dynamic> data = {};
      if (snapshot.hasData && snapshot.data!.snapshot.value is Map) {
        data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
      }

      final dynamic eventsCreatedRaw = data['events_created'];
      final int eventsCreated = eventsCreatedRaw is num
          ? eventsCreatedRaw.toInt()
          : 0;

      final dynamic revenueRaw = data['total_revenue'];
      final double totalRevenue = revenueRaw is num
          ? revenueRaw.toDouble()
          : 0.0;

      final dynamic activeUsersRaw = data['active_users'];
      final int activeUsers = activeUsersRaw is num
          ? activeUsersRaw.toInt()
          : 0;

      final dynamic pendingRaw = data['total_pending'];
      final double pendingPayments = pendingRaw is num
          ? pendingRaw.toDouble()
          : 0.0;

      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          //upper-left - Total Events
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
                        "Total Events",
                        style: TextStyle(
                          fontSize: 13,
                          color: CustomColor.subtextColor,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.calendar_month_outlined,
                        color: Color(0xFF4726BF),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    eventsCreated.toString(),
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
          //upper-right - Total Revenue
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
                        "Total Revenue",
                        style: TextStyle(
                          fontSize: 13,
                          color: CustomColor.subtextColor,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.monetization_on_outlined,
                        color: Color(0xFF960E0E),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '₱${totalRevenue.toStringAsFixed(2)}',
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
          //bottom-left - Active Users
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
                        "Active Users",
                        style: TextStyle(
                          fontSize: 13,
                          color: CustomColor.subtextColor,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.people_outlined,
                        color: Color(0xFF056405),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    activeUsers.toString(),
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
          //bottom-right - Pending Payments
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
                        Icons.verified_user_outlined,
                        color: Colors.orange.shade700,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '₱${pendingPayments.toStringAsFixed(2)}',
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
    },
  );
}
