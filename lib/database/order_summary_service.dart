import 'package:firebase_database/firebase_database.dart';
import 'package:dnsc_events/database/transactionInsert.dart';

class OrderService {
  final DatabaseReference _databaseRef;

  OrderService({DatabaseReference? databaseRef})
    : _databaseRef = databaseRef ?? FirebaseDatabase.instance.ref();

  // MAIN ENTRY: Save order + update event + user tickets + summary + transaction
  Future<void> saveOrder({
    required String userId,
    required String? userEmail,
    required String? userName,
    required Map<String, dynamic> eventData,
    required String eventKey,
    required int ticketQuantity,
    required double subtotal,
    required double total,
    required String paymentMethod,
    required String orderDate,
    required String ticketId,
    required String ticketCode,
    required int timestamp,
  }) async {
    // Get event times and other details
    final eventStartTime = eventData['event_start_time'] ?? '';
    final eventEndTime = eventData['event_end_time'] ?? '';
    final eventType = eventData['event_type'] ?? 'General';
    final eventDescription = eventData['event_description'] ?? '';

    // Prepare order data for ticket_purchase
    final orderData = {
      'ticket_id': ticketId,
      'ticket_code': ticketCode,
      'user_id': userId,
      'user_email': userEmail,
      'user_name': userName ?? 'Unknown',
      'event_id': eventData['event_id'] ?? 'N/A',
      'event_key': eventKey,
      'event_name': eventData['event_name'] ?? 'Unnamed Event',
      'event_type': eventType,
      'ticket_price': (eventData['ticket_price'] ?? 0).toDouble(),
      'quantity': ticketQuantity,
      'subtotal': subtotal,
      'total': total,
      'order_date': orderDate,
      'payment_method': paymentMethod,
      'payment_status': 'paid', // pending, paid, cancelled
      'order_status': 'confirmed', // confirmed, used, cancelled
      'scanned': false, // For QR code validation
      'created_at': timestamp,
      'updated_at': timestamp,
      // Include event details for reference
      'event_date': eventData['event_date'],
      'event_start_time': eventStartTime,
      'event_end_time': eventEndTime,
      'event_location': eventData['event_location'] ?? 'Not specified',
      'event_organizer': eventData['organizer_name'] ?? 'DNSC',
      'event_description': eventDescription,
      'ticket_capacity': eventData['ticket_capacity'] ?? 0,
    };

    // 1. Save to ticket_purchase node
    await _databaseRef.child('ticket_purchase').child(ticketId).set(orderData);

    // 2. Update event's ticket sold count
    await _updateEventTicketSoldCount(
      eventKey: eventKey,
      ticketQuantity: ticketQuantity,
    );

    // 3. Save to user's purchase history
    await _databaseRef
        .child('users')
        .child(userId)
        .child('my_tickets')
        .child(ticketId)
        .set(orderData);

    // 4. Save transaction record
    await _saveTransactionRecord(
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      eventData: eventData,
      total: total,
      paymentMethod: paymentMethod,
      ticketQuantity: ticketQuantity,
      ticketId: ticketId,
      ticketCode: ticketCode,
    );

    // 5. Update user summary (tickets bought, pending payments, etc.)
    await _updateUserSummaryOnPurchase(
      userId: userId,
      ticketQuantity: ticketQuantity,
      total: total,
      paymentStatus: 'paid',
    );
  }

  // --- EVENT TICKET SOLD COUNT ---

  Future<void> _updateEventTicketSoldCount({
    required String eventKey,
    required int ticketQuantity,
  }) async {
    final eventRef = _databaseRef.child('events').child(eventKey);

    final eventSnapshot = await eventRef.get();

    if (!eventSnapshot.exists) {
      print('⚠️ Event not found: $eventKey');
      return;
    }

    final eventData = eventSnapshot.value as Map<dynamic, dynamic>;
    int currentTicketsSold = eventData['tickets_sold'] ?? 0;
    int ticketCapacity = eventData['ticket_capacity'] ?? 0;

    int newTicketsSold = currentTicketsSold + ticketQuantity;

    if (ticketCapacity > 0 && newTicketsSold > ticketCapacity) {
      throw Exception('Not enough tickets available');
    }

    await eventRef.update({
      'tickets_sold': newTicketsSold,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
      'is_available': ticketCapacity == 0 || newTicketsSold < ticketCapacity,
    });

    print('✅ Updated event tickets sold: $newTicketsSold/$ticketCapacity');
  }

  // --- TRANSACTION RECORD ---

  Future<void> _saveTransactionRecord({
    required String userId,
    required String? userName,
    required String? userEmail,
    required Map<String, dynamic> eventData,
    required double total,
    required String paymentMethod,
    required int ticketQuantity,
    required String ticketId,
    required String ticketCode,
  }) async {
    try {
      final safeUserId = userId;
      final safeUserName = userName?.toString() ?? 'Unknown User';
      final safeUserEmail = userEmail?.toString() ?? 'No Email';
      final eventName = eventData['event_name']?.toString() ?? 'Unnamed Event';
      final eventId = eventData['event_id']?.toString() ?? 'N/A';

      // Format event date
      String eventDate;
      final rawEventDate = eventData['event_date'];
      if (rawEventDate == null) {
        final now = DateTime.now();
        eventDate =
            '${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}-${now.year}';
      } else if (rawEventDate is int) {
        final date = DateTime.fromMillisecondsSinceEpoch(rawEventDate);
        eventDate =
            '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}-${date.year}';
      } else {
        eventDate = rawEventDate.toString();
      }

      final amountString = total.toStringAsFixed(2);
      final quantityString = ticketQuantity.toString();

      await transactionService.saveTransactionSimple(
        userId: safeUserId,
        userName: safeUserName,
        userEmail: safeUserEmail,
        eventName: eventName,
        eventDate: eventDate,
        amount: amountString,
        paymentMethod: paymentMethod,
        ticketQuantity: quantityString,
        ticketId: ticketId,
        ticketCode: ticketCode,
        eventId: eventId,
      );

      print('✅ Transaction record saved successfully');
    } catch (e) {
      print('❌ Error saving transaction record: $e');
      print('❌ Error type: ${e.runtimeType}');
    }
  }

  // --- USER SUMMARY ON PURCHASE ---
  //
  // users/{userId}/summary:
  //   tickets_bought: int
  //   events_attended: int
  //   total_spent: double
  //   pending_payments: double
  //
  // On purchase (pending payment):
  //   - tickets_bought += quantity
  //   - pending_payments += total

  Future<void> _updateUserSummaryOnPurchase({
    required String userId,
    required int ticketQuantity,
    required double total,
    required String paymentStatus,
  }) async {
    final summaryRef = _databaseRef
        .child('users')
        .child(userId)
        .child('summary');

    final snapshot = await summaryRef.get();
    int ticketsBought = 0;
    int eventsAttended = 0;
    double totalSpent = 0.0;
    double pendingPayments = 0.0;

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      ticketsBought = (data['tickets_bought'] ?? 0) as int;
      eventsAttended = (data['events_attended'] ?? 0) as int;
      totalSpent = (data['total_spent'] ?? 0).toDouble();
      pendingPayments = (data['pending_payments'] ?? 0).toDouble();
    }

    ticketsBought += ticketQuantity;

    if (paymentStatus == 'pending') {
      pendingPayments += total;
    } else if (paymentStatus == 'paid') {
      totalSpent += total;
    }

    await summaryRef.update({
      'tickets_bought': ticketsBought,
      'events_attended': eventsAttended,
      'total_spent': totalSpent,
      'pending_payments': pendingPayments,
    });

    print('✅ User summary updated on purchase');
  }

  // --- USER SUMMARY WHEN QR SCANNED & PAYMENT PAID ---
  //
  // Call this from your QR scanner / validation screen when:
  // - ticket is scanned
  // - payment_status is updated from "pending" to "paid"
  //
  // It will:
  //   - mark ticket as scanned & paid
  //   - events_attended += 1
  //   - pending_payments -= total
  //   - total_spent += total

  Future<void> markTicketScannedAndPaid({
    required String userId,
    required String ticketId,
  }) async {
    final ticketRef = _databaseRef.child('ticket_purchase').child(ticketId);
    final snapshot = await ticketRef.get();

    if (!snapshot.exists) {
      print('⚠️ Ticket not found for scanning: $ticketId');
      return;
    }

    final ticketData = Map<String, dynamic>.from(snapshot.value as Map);

    final double total = (ticketData['total'] ?? 0).toDouble();

    // 1. Update ticket record
    await ticketRef.update({
      'payment_status': 'paid',
      'order_status': 'used',
      'scanned': true,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });

    // 2. Update user's ticket entry (my_tickets)
    final userTicketRef = _databaseRef
        .child('users')
        .child(userId)
        .child('my_tickets')
        .child(ticketId);

    await userTicketRef.update({
      'payment_status': 'paid',
      'order_status': 'used',
      'scanned': true,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });

    // 3. Update summary for events_attended / total_spent / pending_payments
    final summaryRef = _databaseRef
        .child('users')
        .child(userId)
        .child('summary');
    final summarySnapshot = await summaryRef.get();

    int ticketsBought = 0;
    int eventsAttended = 0;
    double totalSpent = 0.0;
    double pendingPayments = 0.0;

    if (summarySnapshot.exists) {
      final data = Map<String, dynamic>.from(summarySnapshot.value as Map);
      ticketsBought = (data['tickets_bought'] ?? 0) as int;
      eventsAttended = (data['events_attended'] ?? 0) as int;
      totalSpent = (data['total_spent'] ?? 0).toDouble();
      pendingPayments = (data['pending_payments'] ?? 0).toDouble();
    }

    eventsAttended += 1;
    totalSpent += total;
    pendingPayments = (pendingPayments - total).clamp(0, double.infinity);

    await summaryRef.update({
      'tickets_bought': ticketsBought,
      'events_attended': eventsAttended,
      'total_spent': totalSpent,
      'pending_payments': pendingPayments,
    });

    print('✅ User summary updated on scan & payment');
  }
}
