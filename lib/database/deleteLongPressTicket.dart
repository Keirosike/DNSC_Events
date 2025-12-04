// delete_ticket_service.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeleteTicketService {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // Delete ticket from all locations
  Future<bool> deleteTicket({
    required String ticketId,
    required Map<String, dynamic> ticketData,
  }) async {
    try {
      if (_currentUser == null) {
        print('❌ User not logged in');
        return false;
      }

      final userId = _currentUser!.uid;
      final eventKey = ticketData['event_key']?.toString();
      final ticketQuantity = ticketData['quantity'] ?? 1;

      print('🗑️ Starting delete process for ticket: $ticketId');

      // 1. Delete from ticket_purchase (main table)
      await _databaseRef.child('ticket_purchase').child(ticketId).remove();
      print('✅ Deleted from ticket_purchase');

      // 2. Delete from user's my_tickets
      await _databaseRef
          .child('users')
          .child(userId)
          .child('my_tickets')
          .child(ticketId)
          .remove();
      print('✅ Deleted from user\'s my_tickets');

      // 3. Delete from user's transactions (if exists)
      await _deleteFromTransactions(ticketId);

      // 4. Update event's tickets sold count (decrease)
      if (eventKey != null && eventKey.isNotEmpty) {
        await _updateEventTicketsSold(eventKey, ticketQuantity);
      }

      print('✅ Ticket deletion completed successfully');
      return true;
    } catch (e) {
      print('❌ Error deleting ticket: $e');
      return false;
    }
  }

  // Delete from transactions table
  Future<void> _deleteFromTransactions(String ticketId) async {
    try {
      // First, find transaction by ticket_id
      final transactionsRef = _databaseRef.child('transactions');
      final query = transactionsRef.orderByChild('ticket_id').equalTo(ticketId);
      final snapshot = await query.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;

        // Delete all transactions with this ticket_id
        for (var transactionId in data.keys) {
          await transactionsRef.child(transactionId.toString()).remove();
          print('✅ Deleted transaction: $transactionId');
        }
      } else {
        print('⚠️ No transactions found for ticket: $ticketId');
      }
    } catch (e) {
      print('⚠️ Error deleting from transactions: $e');
    }
  }

  // Update event's tickets sold count
  Future<void> _updateEventTicketsSold(
    String eventKey,
    int ticketQuantity,
  ) async {
    try {
      final eventRef = _databaseRef.child('events').child(eventKey);
      final snapshot = await eventRef.get();

      if (snapshot.exists) {
        final eventData = snapshot.value as Map<dynamic, dynamic>;
        final currentTicketsSold = eventData['tickets_sold'] ?? 0;
        final ticketCapacity = eventData['ticket_capacity'] ?? 0;

        // Decrease tickets sold
        int newTicketsSold = currentTicketsSold - ticketQuantity;
        if (newTicketsSold < 0) newTicketsSold = 0;

        // Update event
        await eventRef.update({
          'tickets_sold': newTicketsSold,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
          'is_available':
              ticketCapacity == 0 || newTicketsSold < ticketCapacity,
        });

        print('✅ Updated event tickets sold: $newTicketsSold/$ticketCapacity');
      } else {
        print('⚠️ Event not found: $eventKey');
      }
    } catch (e) {
      print('⚠️ Error updating event tickets sold: $e');
    }
  }

  // Check if ticket can be deleted (only if not used)
  bool canDeleteTicket(Map<String, dynamic> ticketData) {
    final status = ticketData['order_status']?.toString().toLowerCase() ?? '';

    // Only allow deletion if ticket is not used
    return status != 'used' && status != 'scanned';
  }

  // Get deletion message based on ticket status
  String getDeletionMessage(Map<String, dynamic> ticketData) {
    final status = ticketData['order_status']?.toString().toLowerCase() ?? '';
    final eventName = ticketData['event_name'] ?? 'this event';

    if (status == 'used' || status == 'scanned') {
      return 'This ticket has already been used for "$eventName" and cannot be deleted.';
    } else if (status == 'cancelled') {
      return 'This ticket for "$eventName" has already been cancelled.';
    } else {
      return 'Are you sure you want to delete your ticket for "$eventName"? This action cannot be undone.';
    }
  }
}

// Singleton instance
final deleteTicketService = DeleteTicketService();
