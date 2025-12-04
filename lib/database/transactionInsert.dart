// transaction_service.dart
import 'package:firebase_database/firebase_database.dart';

class TransactionService {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

  // Generate transaction ID
  String _generateTransactionId() {
    return 'TRX-${DateTime.now().millisecondsSinceEpoch}';
  }

  // Format date for display - handles multiple input types
  String _formatDateForDisplay(dynamic dateValue) {
    try {
      if (dateValue == null) {
        final now = DateTime.now();
        return '${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}-${now.year}';
      } else if (dateValue is int) {
        // Convert timestamp to DateTime
        final date = DateTime.fromMillisecondsSinceEpoch(dateValue);
        return '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}-${date.year}';
      } else if (dateValue is String) {
        // Parse string date
        try {
          // Check if it's already in MM-DD-YYYY format
          if (dateValue.contains('-') && dateValue.length == 10) {
            final parts = dateValue.split('-');
            if (parts.length == 3) {
              final month = int.tryParse(parts[0]) ?? DateTime.now().month;
              final day = int.tryParse(parts[1]) ?? DateTime.now().day;
              final year = int.tryParse(parts[2]) ?? DateTime.now().year;
              final date = DateTime(year, month, day);
              return '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}-${date.year}';
            }
          }

          // Try standard parsing
          final date = DateTime.parse(dateValue);
          return '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}-${date.year}';
        } catch (e) {
          // If parsing fails, return as-is
          return dateValue;
        }
      } else if (dateValue is DateTime) {
        return '${dateValue.month.toString().padLeft(2, '0')}-${dateValue.day.toString().padLeft(2, '0')}-${dateValue.year}';
      } else {
        // Try to convert to string
        final now = DateTime.now();
        return '${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}-${now.year}';
      }
    } catch (e) {
      print('⚠️ Error formatting date: $e');
      final now = DateTime.now();
      return '${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}-${now.year}';
    }
  }

  // Get ISO date for sorting
  String _getIsoDate(dynamic dateValue) {
    try {
      if (dateValue == null) {
        return DateTime.now().toIso8601String();
      } else if (dateValue is int) {
        return DateTime.fromMillisecondsSinceEpoch(dateValue).toIso8601String();
      } else if (dateValue is String) {
        try {
          // Check if it's already in MM-DD-YYYY format
          if (dateValue.contains('-') && dateValue.length == 10) {
            final parts = dateValue.split('-');
            if (parts.length == 3) {
              final month = int.tryParse(parts[0]) ?? DateTime.now().month;
              final day = int.tryParse(parts[1]) ?? DateTime.now().day;
              final year = int.tryParse(parts[2]) ?? DateTime.now().year;
              final date = DateTime(year, month, day);
              return date.toIso8601String();
            }
          }

          // Try standard parsing
          return DateTime.parse(dateValue).toIso8601String();
        } catch (e) {
          // If parsing fails, return current date
          return DateTime.now().toIso8601String();
        }
      } else if (dateValue is DateTime) {
        return dateValue.toIso8601String();
      } else {
        return DateTime.now().toIso8601String();
      }
    } catch (e) {
      print('⚠️ Error getting ISO date: $e');
      return DateTime.now().toIso8601String();
    }
  }

  // Save transaction to database
  Future<void> saveTransaction({
    required String userId,
    required String userName,
    required String userEmail,
    required String eventName,
    required dynamic eventDate, // Accept dynamic to handle various formats
    required double amount,
    required String paymentMethod,
    required int ticketQuantity,
    required String ticketId,
    required String ticketCode,
    required String eventId,
  }) async {
    try {
      final transactionId = _generateTransactionId();
      final now = DateTime.now();
      final timestamp = now.millisecondsSinceEpoch;

      // Format dates
      final formattedEventDate = _formatDateForDisplay(eventDate);
      final formattedTransactionDate = _formatDateForDisplay(now);

      // Prepare transaction data - ensure all values are properly typed
      final transactionData = {
        'transaction_id': transactionId,
        'user_id': userId.toString(),
        'user_name': userName.toString(),
        'user_email': userEmail.toString(),
        'event_name': eventName.toString(),
        'event_date': formattedEventDate.toString(),
        'transaction_date': formattedTransactionDate.toString(),
        'amount': amount.toDouble(),
        'formatted_amount': '₱${amount.toStringAsFixed(2)}',
        'payment_method': paymentMethod.toString(),
        'status': 'Paid',
        'ticket_quantity': ticketQuantity.toInt(),
        'ticket_id': ticketId.toString(),
        'ticket_code': ticketCode.toString(),
        'event_id': eventId.toString(),
        'created_at': timestamp.toInt(),
        'updated_at': timestamp.toInt(),
        // Add ISO dates for sorting
        'iso_transaction_date': now.toIso8601String(),
        'iso_event_date': _getIsoDate(eventDate),
      };

      // Debug print
      print('📊 Transaction Data Types:');
      transactionData.forEach((key, value) {
        print('  $key: $value (${value.runtimeType})');
      });

      // Save to transactions node
      await _databaseRef
          .child('transactions')
          .child(transactionId)
          .set(transactionData);

      print('✅ Transaction saved: $transactionId');

      // Also save to user's transaction history
      await _databaseRef
          .child('users')
          .child(userId)
          .child('transactions')
          .child(transactionId)
          .set(transactionData);

      print('✅ Transaction saved to user\'s history');
    } catch (e) {
      print('❌ Error saving transaction: $e');
      print('❌ Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  Future<void> saveTransactionSimple({
    required String userId,
    required String userName,
    required String userEmail,
    required String eventName,
    required String eventDate, // Must be string
    required String amount, // Pass as string like "300.00"
    required String paymentMethod,
    required String ticketQuantity, // Pass as string
    required String ticketId,
    required String ticketCode,
    required String eventId,
  }) async {
    try {
      final transactionId = _generateTransactionId();
      final now = DateTime.now();
      final timestamp = now.millisecondsSinceEpoch;

      // 👇 add this
      final formattedEventDate = _formatDateForDisplay(eventDate);

      final transactionData = {
        'transaction_id': transactionId,
        'user_id': userId,
        'user_name': userName,
        'user_email': userEmail,
        'event_name': eventName,

        // 👇 use formatted value instead of raw
        'event_date': formattedEventDate,

        'transaction_date': _formatDateForDisplay(now),
        'amount': double.tryParse(amount) ?? 0.0,
        'formatted_amount':
            '₱${double.tryParse(amount)?.toStringAsFixed(2) ?? "0.00"}',
        'payment_method': paymentMethod,
        'status': 'Paid',
        'ticket_quantity': int.tryParse(ticketQuantity) ?? 1,
        'ticket_id': ticketId,
        'ticket_code': ticketCode,
        'event_id': eventId,
        'created_at': timestamp,
        'updated_at': timestamp,
        'iso_transaction_date': now.toIso8601String(),

        // 👇 still normalized ISO for sorting
        'iso_event_date': _getIsoDate(eventDate),
      };

      await _databaseRef
          .child('transactions')
          .child(transactionId)
          .set(transactionData);

      print('✅ Transaction saved (simple): $transactionId');

      await _databaseRef
          .child('users')
          .child(userId)
          .child('transactions')
          .child(transactionId)
          .set(transactionData);

      print('✅ Transaction saved to user\'s history');
    } catch (e) {
      print('❌ Error saving transaction (simple): $e');
      rethrow;
    }
  }

  // Get all transactions for a user
  Future<List<Map<String, dynamic>>> getUserTransactions(String userId) async {
    try {
      final snapshot = await _databaseRef
          .child('users')
          .child(userId)
          .child('transactions')
          .get();

      if (snapshot.exists) {
        final transactions = <Map<String, dynamic>>[];
        final data = snapshot.value as Map<dynamic, dynamic>;

        data.forEach((key, value) {
          if (value is Map) {
            transactions.add({
              'transaction_id': key.toString(),
              ...Map<String, dynamic>.from(value),
            });
          }
        });

        // Sort by date (newest first)
        transactions.sort((a, b) {
          final dateA = a['created_at'] ?? 0;
          final dateB = b['created_at'] ?? 0;
          return dateB.compareTo(dateA);
        });

        return transactions;
      }
      return [];
    } catch (e) {
      print('❌ Error fetching user transactions: $e');
      return [];
    }
  }

  // Get all transactions (admin view)
  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    try {
      final snapshot = await _databaseRef.child('transactions').get();

      if (snapshot.exists) {
        final transactions = <Map<String, dynamic>>[];
        final data = snapshot.value as Map<dynamic, dynamic>;

        data.forEach((key, value) {
          if (value is Map) {
            transactions.add({
              'transaction_id': key.toString(),
              ...Map<String, dynamic>.from(value),
            });
          }
        });

        // Sort by date (newest first)
        transactions.sort((a, b) {
          final dateA = a['created_at'] ?? 0;
          final dateB = b['created_at'] ?? 0;
          return dateB.compareTo(dateA);
        });

        return transactions;
      }
      return [];
    } catch (e) {
      print('❌ Error fetching all transactions: $e');
      return [];
    }
  }

  // Update transaction status
  Future<void> updateTransactionStatus({
    required String transactionId,
    required String status, // 'Paid', 'Pending', 'Cancelled', 'Refunded'
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      await _databaseRef.child('transactions').child(transactionId).update({
        'status': status,
        'updated_at': timestamp,
      });

      // Also update in user's transaction history
      final snapshot = await _databaseRef
          .child('transactions')
          .child(transactionId)
          .child('user_id')
          .get();

      if (snapshot.exists) {
        final userId = snapshot.value as String;
        await _databaseRef
            .child('users')
            .child(userId)
            .child('transactions')
            .child(transactionId)
            .update({'status': status, 'updated_at': timestamp});
      }

      print('✅ Transaction status updated: $transactionId -> $status');
    } catch (e) {
      print('❌ Error updating transaction status: $e');
      rethrow;
    }
  }
}

// Singleton instance
final transactionService = TransactionService();
