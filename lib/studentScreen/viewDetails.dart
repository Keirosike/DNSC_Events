import 'package:dnsc_events/colors/color.dart';
import 'package:dnsc_events/studentScreen/orderSummary.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class Viewdetails extends StatefulWidget {
  final Map<String, dynamic> eventData;
  final String eventKey;

  const Viewdetails({
    super.key,
    required this.eventData,
    required this.eventKey,
  });

  @override
  State<Viewdetails> createState() => _ViewdetailsState();
}

class _ViewdetailsState extends State<Viewdetails> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _isCheckingPurchase = false;
  bool _hasAlreadyPurchased = false;
  int _ticketsAvailable = 0;

  @override
  void initState() {
    super.initState();
    _checkIfUserAlreadyPurchased();
    _calculateTicketsAvailable();
  }

  void _calculateTicketsAvailable() {
    final ticketsSold = widget.eventData['tickets_sold'] ?? 0;
    final ticketCapacity = widget.eventData['ticket_quantity'] ?? 0;

    // Calculate available tickets (no unlimited logic)
    _ticketsAvailable = ticketCapacity - ticketsSold;

    setState(() {});
  }

  Future<void> _checkIfUserAlreadyPurchased() async {
    if (_currentUser == null) return;

    setState(() {
      _isCheckingPurchase = true;
    });

    try {
      // Check in user's my_tickets for this event
      final userTicketsRef = _databaseRef
          .child('users')
          .child(_currentUser!.uid)
          .child('my_tickets');

      final snapshot = await userTicketsRef.get();

      if (snapshot.exists) {
        final tickets = snapshot.value as Map<dynamic, dynamic>;

        // Check if any ticket is for this event
        bool hasTicketForThisEvent = false;
        final currentEventId = widget.eventData['event_id']?.toString();
        final currentEventKey = widget.eventKey;

        tickets.forEach((ticketId, ticketData) {
          if (ticketData is Map) {
            final ticketEventId = ticketData['event_id']?.toString();
            final ticketEventKey = ticketData['event_key']?.toString();

            if (ticketEventId == currentEventId ||
                ticketEventKey == currentEventKey) {
              hasTicketForThisEvent = true;
            }
          }
        });

        setState(() {
          _hasAlreadyPurchased = hasTicketForThisEvent;
        });
      }
    } catch (e) {
      print('❌ Error checking purchase: $e');
    } finally {
      setState(() {
        _isCheckingPurchase = false;
      });
    }
  }

  ImageProvider? _getEventImage() {
    try {
      if (widget.eventData['event_image_type'] == 'base64' &&
          widget.eventData['event_image'] != null) {
        // Base64 image
        return MemoryImage(
          base64Decode(widget.eventData['event_image'].split(',').last),
        );
      } else if (widget.eventData['event_image'] != null) {
        // URL image
        return NetworkImage(widget.eventData['event_image']);
      }
    } catch (e) {
      print('Error loading event image: $e');
    }
    return null;
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final monthNames = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  String _formatTime(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        String period = hour >= 12 ? 'PM' : 'AM';
        hour = hour % 12;
        hour = hour == 0 ? 12 : hour;
        return '$hour:${minute.toString().padLeft(2, '0')} $period';
      }
      return timeString;
    } catch (e) {
      return 'Invalid Time';
    }
  }

  String _formatPrice(double price) {
    return '₱${price.toStringAsFixed(2)}';
  }

  void _showAlreadyPurchasedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text('Already Purchased'),
          ],
        ),
        content: Text(
          'You have already purchased a ticket for this event. '
          'Each user can only buy one ticket per event.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.person_off_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('Login Required'),
          ],
        ),
        content: Text(
          'You need to login with your DNSC student account '
          'to purchase tickets for events.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  // 🔹 NEW: Check if this event already passed
  bool get _isEventPast {
    try {
      final event = widget.eventData;

      final String? dateStr = event['event_date']?.toString();
      if (dateStr == null || dateStr.isEmpty) return false;

      DateTime date = DateTime.parse(dateStr);

      // Prefer end time; fallback to start time if needed
      String? timeStr = event['event_end_time']?.toString();
      timeStr ??= event['event_start_time']?.toString();

      if (timeStr != null && timeStr.isNotEmpty) {
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          final hour = int.tryParse(parts[0]) ?? 0;
          final minute = int.tryParse(parts[1]) ?? 0;
          date = DateTime(date.year, date.month, date.day, hour, minute);
        }
      }

      return DateTime.now().isAfter(date);
    } catch (e) {
      print('Error checking if event is past: $e');
      // If parsing fails, don't block purchases by accident
      return false;
    }
  }

  // Check all conditions for buying
  bool get _canBuyTicket {
    return !_isEventPast &&
        _ticketsAvailable > 0 &&
        !_hasAlreadyPurchased &&
        _currentUser != null;
  }

  String get _buyButtonText {
    if (_isCheckingPurchase) return 'Checking...';
    if (_currentUser == null) return 'Login to Buy';
    if (_isEventPast) return 'Event Ended'; // 🔹 NEW
    if (_hasAlreadyPurchased) return 'Already Purchased';
    if (_ticketsAvailable <= 0) return 'Sold Out';
    return 'Buy Ticket';
  }

  Color get _buyButtonColor {
    if (_canBuyTicket) return CustomColor.primary;
    return Colors.grey.shade400;
  }

  void _onBuyButtonPressed() {
    // Extra guard: if event is past, do nothing
    if (_isEventPast) {
      return;
    }

    if (_currentUser == null) {
      _showLoginRequiredDialog();
      return;
    }

    if (_hasAlreadyPurchased) {
      _showAlreadyPurchasedDialog();
      return;
    }

    if (_ticketsAvailable <= 0) {
      // Already showing as "Sold Out", so no action needed
      return;
    }

    // All checks passed, show order summary
    showModalBottomSheet(
      context: context,
      builder: (context) =>
          Ordersummary(eventData: widget.eventData, eventKey: widget.eventKey),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.eventData;
    final imageProvider = _getEventImage();
    final ticketsSold = event['tickets_sold'] ?? 0;

    return Scaffold(
      backgroundColor: CustomColor.background,
      body: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(color: CustomColor.background),
                child: Column(
                  children: [
                    // Event Image
                    Container(
                      width: double.infinity,
                      height: 355,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                        color: Colors.grey.shade200,
                      ),
                      child: imageProvider != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(12),
                              ),
                              child: Image(
                                image: imageProvider,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.image,
                                          size: 50,
                                          color: Colors.grey.shade400,
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          'Event Image',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image,
                                    size: 50,
                                    color: Colors.grey.shade400,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'No Image',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        top: 20,
                        left: 15,
                        right: 15,
                        bottom: 5,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Event Name
                          Text(
                            event['event_name'] ?? 'Unnamed Event',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'InterExtra',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 10),

                          // Event Type
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_alt_rounded,
                                size: 20,
                                color: CustomColor.primary,
                              ),
                              SizedBox(width: 5),
                              Text(
                                event['event_type'] ?? 'Not specified',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),

                          // Location
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 20,
                                color: CustomColor.primary,
                              ),
                              SizedBox(width: 5),
                              Text(
                                event['event_location'] ?? 'No location',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),

                          // Date
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                size: 20,
                                color: CustomColor.primary,
                              ),
                              SizedBox(width: 5),
                              Text(
                                _formatDate(event['event_date'] ?? ''),
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),

                          // Time
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lock_clock_rounded,
                                size: 20,
                                color: CustomColor.primary,
                              ),
                              SizedBox(width: 5),
                              Text(
                                '${_formatTime(event['event_start_time'] ?? '')} - ${_formatTime(event['event_end_time'] ?? '')}',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),

                          // Price
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.price_change_rounded,
                                size: 20,
                                color: CustomColor.primary,
                              ),
                              SizedBox(width: 5),
                              Text(
                                _formatPrice(
                                  (event['ticket_price'] ?? 0).toDouble(),
                                ),
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),

                          // Tickets Available / Purchase Status
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.confirmation_number,
                                size: 20,
                                color: CustomColor.primary,
                              ),
                              SizedBox(width: 5),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isEventPast
                                          ? 'Event has ended'
                                          : '$_ticketsAvailable tickets available',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _isEventPast
                                            ? Colors.red
                                            : _ticketsAvailable > 0
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (_hasAlreadyPurchased)
                                      Text(
                                        'You already have a ticket',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),

                          Center(
                            child: Divider(
                              color: CustomColor.borderGray1,
                              thickness: 2,
                              indent: 25,
                              endIndent: 25,
                            ),
                          ),
                          SizedBox(height: 10),

                          // About this event
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'About this event',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontFamily: 'InterExtra',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 10),

                          // Event Description
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  event['event_description'] ??
                                      'No description provided',
                                  style: TextStyle(fontSize: 14, height: 1.5),
                                  textAlign: TextAlign.justify,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 40,
                left: 20,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(10),
        child: Row(
          children: [
            // Buy Ticket Button
            Expanded(
              child: GestureDetector(
                onTap: _canBuyTicket ? _onBuyButtonPressed : null,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: _buyButtonColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _isCheckingPurchase
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Checking...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            _buyButtonText,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10),
            // Favorite Button
            GestureDetector(
              onTap: () {
                // TODO: Implement favorite functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added to favorites'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: CustomColor.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.favorite_border,
                  size: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
