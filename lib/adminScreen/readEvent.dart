import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:dnsc_events/colors/color.dart';
import 'dart:convert';
import 'package:dnsc_events/adminScreen/editEvent.dart';
import 'package:dnsc_events/adminScreen/qrCode.dart';

class Readevent extends StatefulWidget {
  final Map<String, dynamic> eventData;
  final String eventKey;

  const Readevent({super.key, required this.eventData, required this.eventKey});

  @override
  State<Readevent> createState() => _ReadeventState();
}

class _ReadeventState extends State<Readevent> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

  // Parse Base64 image if stored that way
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

  /// 🔥 Actually delete event from all related paths in the database
  Future<void> _deleteEventFromDatabase() async {
    final String eventKey = widget.eventKey;
    final String eventId = widget.eventData['event_id']?.toString() ?? '';

    // 1️⃣ Delete from /events/{eventKey}
    await _databaseRef.child('events').child(eventKey).remove();

    // 2️⃣ Delete related transactions in /transactions where event_id matches
    try {
      final txSnapshot = await _databaseRef.child('transactions').get();
      if (txSnapshot.exists) {
        for (final child in txSnapshot.children) {
          final data = child.value;
          if (data is Map) {
            final String txEventId = data['event_id']?.toString() ?? '';
            if (txEventId == eventId) {
              await child.ref.remove();
            }
          }
        }
      }
    } catch (e) {
      print('⚠️ Error deleting related transactions for event $eventId: $e');
    }

    // 3️⃣ Delete related tickets under /users/{uid}/my_tickets
    try {
      final usersSnapshot = await _databaseRef.child('users').get();
      if (usersSnapshot.exists) {
        for (final userSnap in usersSnapshot.children) {
          final myTicketsSnap = await userSnap.child('my_tickets').ref.get();

          if (!myTicketsSnap.exists) continue;

          for (final ticketSnap in myTicketsSnap.children) {
            final ticketData = ticketSnap.value;
            if (ticketData is Map) {
              final String ticketEventId =
                  ticketData['event_id']?.toString() ?? '';
              final String ticketEventKey =
                  ticketData['event_key']?.toString() ?? '';

              if (ticketEventId == eventId || ticketEventKey == eventKey) {
                await ticketSnap.ref.remove();
              }
            }
          }
        }
      }
    } catch (e) {
      print('⚠️ Error deleting related user tickets for event $eventId: $e');
    }

    // (Optional) 4️⃣ You could also adjust admins/summary/events_created here
    // if you want to decrement the count on delete.
  }

  Future<void> _deleteEvent() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Icon
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_forever,
                  size: 40,
                  color: Colors.red.shade700,
                ),
              ),

              SizedBox(height: 20),

              // Title
              Text(
                'Delete Event',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade800,
                  fontFamily: 'InterExtra',
                ),
              ),

              SizedBox(height: 12),

              // Description
              Text(
                'Are you sure you want to delete this event?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 4),

              // Warning message
              Text(
                'This action cannot be undone.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 8),

              // Event details preview
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.event,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.eventData['event_name'] ?? 'Unnamed Event',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_month,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: 6),
                        Text(
                          _formatDate(widget.eventData['event_date'] ?? ''),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.eventData['event_location'] ?? 'No location',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
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

              SizedBox(height: 25),

              // Action Buttons
              Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade400,
                          width: 1.5,
                        ),
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 16),

                  // Delete Button
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade600, Colors.red.shade800],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.shade300.withOpacity(0.4),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      try {
        // Show loading overlay
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await Future.delayed(Duration(milliseconds: 500)); // Simulate delay

        // 🔥 Call our DB delete function
        await _deleteEventFromDatabase();

        // Close loading dialog
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Event Deleted',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'The event and related data have been deleted',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            margin: EdgeInsets.all(16),
          ),
        );

        // Navigate back after success
        await Future.delayed(Duration(milliseconds: 500));
        Navigator.of(context).pop();
      } catch (e) {
        // Close loading dialog if still open
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delete Failed',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Failed to delete event: ${e.toString()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            margin: EdgeInsets.all(16),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _deleteEvent,
            ),
          ),
        );
      }
    }
  }

  void _editEvent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            Editevent(eventKey: widget.eventKey, eventData: widget.eventData),
      ),
    ).then((_) {
      // Optionally refresh data when returning from edit
      // You might want to pass a callback to refresh the event data
    });
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatPrice(double price) {
    return '₱${price.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.eventData;
    final imageProvider = _getEventImage();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(top: 55, left: 15, right: 15, bottom: 15),
          child: Column(
            children: [
              // Header with Back Button
              Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Event ',
                        style: TextStyle(
                          fontFamily: 'InterExtra',
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Details',
                        style: TextStyle(
                          fontFamily: 'InterExtra',
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: CustomColor.primary,
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    right: 5,
                    child: IconButton(
                      onPressed: () {
                        final eventId =
                            widget.eventData['event_id']?.toString() ??
                            ''; // very important

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QRTicketScanner(eventId: eventId),
                          ),
                        );
                      },
                      icon: Icon(Icons.qr_code_scanner_outlined),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Event Image
              Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: imageProvider != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image(
                          image: imageProvider,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
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

              SizedBox(height: 20),

              // Event Name
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Event Name',
                    style: TextStyle(
                      fontFamily: 'InterExtra',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 40,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(width: 1, color: Colors.grey.shade300),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          event['event_name'] ?? 'Not specified',
                          style: TextStyle(fontSize: 14, color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 15),

              // Date and Time Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Date',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'InterExtra',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Start time',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'InterExtra',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'End time',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'InterExtra',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Date Display
                      Expanded(
                        flex: 3,
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              width: 1,
                              color: Colors.grey.shade300,
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_month,
                                  size: 14,
                                  color: Colors.black,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  _formatDate(event['event_date'] ?? ''),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),

                      // Start Time Display
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              width: 1,
                              color: Colors.grey.shade300,
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time_filled,
                                  size: 14,
                                  color: Colors.black,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  event['event_start_time'] ?? 'Not specified',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),

                      // End Time Display
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              width: 1,
                              color: Colors.grey.shade300,
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time_filled,
                                  size: 14,
                                  color: Colors.black,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  event['event_end_time'] ?? 'Not specified',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 15),

              // Event Type
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Event Type',
                    style: TextStyle(
                      fontFamily: 'InterExtra',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(width: 1, color: Colors.grey.shade300),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          event['event_type'] ?? 'Not specified',
                          style: TextStyle(fontSize: 14, color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 15),

              // Event Location
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Event Location',
                    style: TextStyle(
                      fontFamily: 'InterExtra',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(width: 1, color: Colors.grey.shade300),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          event['event_location'] ?? 'Not specified',
                          style: TextStyle(fontSize: 14, color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 15),

              // Event Description
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Event Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'InterExtra',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(width: 1, color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          event['event_description'] ??
                              'No description provided',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 15),

              // Ticket Price and Quantity
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Ticket Price',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'InterExtra',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Ticket Quantity',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'InterExtra',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      // Ticket Price
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              width: 1,
                              color: Colors.grey.shade300,
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              children: [
                                Text(
                                  '₱',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    (event['ticket_price'] ?? 0)
                                        .toStringAsFixed(2),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),

                      // Ticket Quantity
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              width: 1,
                              color: Colors.grey.shade300,
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                event['ticket_quantity']?.toString() ?? '0',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 30),

              // Tickets Sold Information
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tickets Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'InterExtra',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(width: 1, color: Colors.grey.shade300),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.confirmation_number,
                                size: 16,
                                color: CustomColor.primary,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Tickets Sold',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                '${event['tickets_sold'] ?? 0} / ${event['ticket_quantity'] ?? 0}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      (event['tickets_sold'] ?? 0) >=
                                          (event['ticket_quantity'] ?? 1)
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.green.shade200,
                                  ),
                                ),
                                child: Text(
                                  '${event['ticket_quantity'] != null && event['ticket_quantity'] > 0 ? (((event['ticket_quantity'] - (event['tickets_sold'] ?? 0)) / event['ticket_quantity']) * 100).toStringAsFixed(0) : '0'}% left',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
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

              SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _deleteEvent,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Delete Event',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: _editEvent,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: CustomColor.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit, size: 20, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Edit Event',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
