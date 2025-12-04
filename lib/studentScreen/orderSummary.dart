import 'package:flutter/material.dart';
import 'package:dnsc_events/colors/color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:dnsc_events/database/order_summary_service.dart'; // <--- service import
import 'package:dnsc_events/student.dart'; // <--- 🆕 for navigating to ticket page (Student tabs)

class Ordersummary extends StatefulWidget {
  final Map<String, dynamic> eventData;
  final String eventKey;

  const Ordersummary({
    super.key,
    required this.eventData,
    required this.eventKey,
  });

  @override
  State<Ordersummary> createState() => _OrdersummaryState();
}

class _OrdersummaryState extends State<Ordersummary> {
  int _ticketQuantity = 1;
  String? _userId;
  String? _userEmail;
  String? _userName;
  bool _isLoadingUser = true;
  bool _isSavingOrder = false;

  // Service instance
  late final OrderService _orderService;

  @override
  void initState() {
    super.initState();
    _orderService = OrderService();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      setState(() {
        _userId = user.uid;
        _userEmail = user.email;
        _userName = user.displayName;
        _isLoadingUser = false;
      });
    } else {
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  String _formatPrice(double price) {
    return '₱${price.toStringAsFixed(2)}';
  }

  double get _subtotal {
    final ticketPrice = (widget.eventData['ticket_price'] ?? 0).toDouble();
    return ticketPrice * _ticketQuantity;
  }

  double get _total {
    return _subtotal;
  }

  // Generate ticket ID
  String get _ticketId {
    return 'TKT-${DateTime.now().millisecondsSinceEpoch}';
  }

  // Generate ticket code
  String get _ticketCode {
    return 'DNSC${DateTime.now().millisecondsSinceEpoch ~/ 1000}';
  }

  // Format order date
  String get _formattedOrderDate {
    final now = DateTime.now();
    return DateFormat('yyyy-MM-dd HH:mm').format(now);
  }

  // Format time for display
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

  // Get current timestamp
  int get _currentTimestamp {
    return DateTime.now().millisecondsSinceEpoch;
  }

  // Payment method
  String get _paymentMethod => 'Cash';

  // ----------- SAVE ORDER (UI calls service here) -----------

  Future<void> _saveOrderToFirebase() async {
    if (_isSavingOrder) return; // Prevent multiple clicks
    if (_userId == null) return;

    setState(() {
      _isSavingOrder = true;
    });

    try {
      final ticketId = _ticketId;
      final ticketCode = _ticketCode;
      final timestamp = _currentTimestamp;
      final orderDate = _formattedOrderDate;

      await _orderService.saveOrder(
        userId: _userId!,
        userEmail: _userEmail,
        userName: _userName,
        eventData: widget.eventData,
        eventKey: widget.eventKey,
        ticketQuantity: _ticketQuantity,
        subtotal: _subtotal,
        total: _total,
        paymentMethod: _paymentMethod,
        orderDate: orderDate,
        ticketId: ticketId,
        ticketCode: ticketCode,
        timestamp: timestamp,
      );

      if (!mounted) return;

      // ✅ Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ticket purchase confirmed!',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // ✅ Navigate to TICKETS PAGE after confirming purchase
      // Change `initialIndex` to whatever tab index your "Tickets" tab uses.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const Student(
            initialIndex: 2, // 🔁 <-- SET THIS TO YOUR TICKETS TAB INDEX
          ),
        ),
      );
    } catch (e) {
      print('❌ Error saving order: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Error saving order. Please try again.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingOrder = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.eventData;
    final ticketPrice = (event['ticket_price'] ?? 0).toDouble();
    final eventName = event['event_name'] ?? 'Unnamed Event';
    final eventId = event['event_id'] ?? 'N/A';
    final eventStartTime = event['event_start_time'] ?? '';
    final eventEndTime = event['event_end_time'] ?? '';

    // Show loading while getting user data
    if (_isLoadingUser) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Check if user is logged in
    if (_userId == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: CustomColor.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: Colors.red),
                    SizedBox(height: 20),
                    Text(
                      'Login Required',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'InterExtra',
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Please login with your DNSC student account to purchase tickets.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('Go to Login'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            height: 600,
            decoration: BoxDecoration(
              color: CustomColor.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Drag handle
                  Container(
                    padding: EdgeInsets.only(top: 5, bottom: 10),
                    child: Center(
                      child: Container(
                        width: 100,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(12),
                            right: Radius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),

                  // Event Name
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          eventName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'InterExtra',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),

                  Row(
                    children: [
                      Text(
                        'Order Summary',
                        style: TextStyle(
                          fontFamily: 'InterExtra',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  // Order Details
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Price Breakdown
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              children: [
                                // Ticket Type
                                Row(
                                  children: [
                                    Text(
                                      'General Admission',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Spacer(),
                                    Text(
                                      '${_formatPrice(ticketPrice)} x $_ticketQuantity',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),

                                Divider(
                                  color: CustomColor.borderGray1,
                                  thickness: 1,
                                  height: 20,
                                ),

                                // Subtotal
                                Row(
                                  children: [
                                    Text(
                                      'Subtotal',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Spacer(),
                                    Text(
                                      _formatPrice(_subtotal),
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),

                                Divider(
                                  color: CustomColor.borderGray1,
                                  thickness: 1,
                                  height: 20,
                                ),

                                // Total
                                Row(
                                  children: [
                                    Text(
                                      'Total',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Spacer(),
                                    Text(
                                      _formatPrice(_total),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: CustomColor.primary,
                                      ),
                                    ),
                                  ],
                                ),

                                Divider(
                                  color: CustomColor.borderGray1,
                                  thickness: 1,
                                  height: 20,
                                ),

                                // Payment Method
                                Row(
                                  children: [
                                    Text(
                                      'Payment Method',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Spacer(),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.blue.shade100,
                                        ),
                                      ),
                                      child: Text(
                                        _paymentMethod,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.blue.shade800,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 10),

                                // Payment Note
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.yellow.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.yellow.shade100,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info,
                                        size: 16,
                                        color: Colors.orange.shade700,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Pay with cash upon entry. Bring this receipt.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.orange.shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 20),

                          // User Information Section
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade100),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 16,
                                      color: Colors.blue.shade700,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Account Information',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'InterExtra',
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),

                                // Display Name if available
                                if (_userName != null && _userName!.isNotEmpty)
                                  _buildOrderDetailRow(
                                    label: 'Name',
                                    value: _userName!,
                                    icon: Icons.badge,
                                    valueColor: Colors.blue.shade800,
                                  ),

                                if (_userName != null && _userName!.isNotEmpty)
                                  SizedBox(height: 8),

                                // Display Email
                                _buildOrderDetailRow(
                                  label: 'Email',
                                  value: _userEmail ?? 'No email',
                                  icon: Icons.email,
                                  valueColor: Colors.blue.shade800,
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 20),

                          // Order Information Section
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order Information',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'InterExtra',
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                SizedBox(height: 12),

                                // Ticket ID
                                _buildOrderDetailRow(
                                  label: 'Ticket ID',
                                  value: _ticketId,
                                  icon: Icons.confirmation_number,
                                ),
                                SizedBox(height: 8),

                                // Event ID
                                _buildOrderDetailRow(
                                  label: 'Event ID',
                                  value: eventId.toString(),
                                  icon: Icons.event,
                                ),
                                SizedBox(height: 8),

                                // Quantity
                                _buildOrderDetailRow(
                                  label: 'Quantity',
                                  value: '$_ticketQuantity ticket(s)',
                                  icon: Icons.numbers,
                                ),
                                SizedBox(height: 8),

                                // Total Price
                                _buildOrderDetailRow(
                                  label: 'Total Price',
                                  value: _formatPrice(_total),
                                  icon: Icons.attach_money,
                                  valueColor: CustomColor.primary,
                                ),
                                SizedBox(height: 8),

                                // Order Date
                                _buildOrderDetailRow(
                                  label: 'Order Date',
                                  value: _formattedOrderDate,
                                  icon: Icons.calendar_today,
                                ),
                                SizedBox(height: 8),

                                // Event Date
                                if (event['event_date'] != null)
                                  _buildOrderDetailRow(
                                    label: 'Event Date',
                                    value: _formatDate(event['event_date']),
                                    icon: Icons.date_range,
                                  ),
                                if (event['event_date'] != null)
                                  SizedBox(height: 8),

                                // Event Time
                                if (eventStartTime.isNotEmpty &&
                                    eventEndTime.isNotEmpty)
                                  _buildOrderDetailRow(
                                    label: 'Event Time',
                                    value:
                                        '${_formatTime(eventStartTime)} - ${_formatTime(eventEndTime)}',
                                    icon: Icons.access_time,
                                  ),
                                if (eventStartTime.isNotEmpty &&
                                    eventEndTime.isNotEmpty)
                                  SizedBox(height: 8),

                                // Ticket Code
                                _buildOrderDetailRow(
                                  label: 'Ticket Code',
                                  value: _ticketCode,
                                  icon: Icons.qr_code,
                                  valueStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                SizedBox(height: 8),

                                // Payment Method
                                _buildOrderDetailRow(
                                  label: 'Payment Method',
                                  value: _paymentMethod,
                                  icon: Icons.payment,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Confirm Purchase Button
                  Container(
                    height: 48,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _isSavingOrder ? Colors.grey : CustomColor.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _isSavingOrder
                          ? []
                          : [
                              BoxShadow(
                                color: CustomColor.primary.withOpacity(0.3),
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                    ),
                    child: TextButton(
                      onPressed: _isSavingOrder
                          ? null
                          : () {
                              _saveOrderToFirebase();
                            },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSavingOrder
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
                                  'Processing...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_cart_checkout, size: 20),
                                SizedBox(width: 10),
                                Text(
                                  'Confirm Purchase',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailRow({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
    TextStyle? valueStyle,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            value,
            style:
                valueStyle ??
                TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? Colors.grey.shade800,
                ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Helper method to format date
  String _formatDate(dynamic dateInput) {
    try {
      if (dateInput is String) {
        final date = DateTime.parse(dateInput);
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
      } else if (dateInput is int) {
        final date = DateTime.fromMillisecondsSinceEpoch(dateInput);
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
      }
      return 'Invalid Date';
    } catch (e) {
      return 'Invalid Date';
    }
  }
}
