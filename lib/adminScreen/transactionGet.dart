import 'package:firebase_database/firebase_database.dart';

class TransactionRecord {
  final String transactionId;
  final String userId;
  final String userName;
  final String userEmail;
  final String eventName;
  final String eventId;
  final String eventDate; // as string for display
  final String transactionDate;
  final double amount;
  final String formattedAmount;
  final String paymentMethod;
  final String status;
  final String ticketCode;
  final String ticketId;
  final int ticketQuantity;
  final int createdAt;
  final int updatedAt;

  // 👇 NEW: profile image from `students` node
  final String profileImage;

  TransactionRecord({
    required this.transactionId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.eventName,
    required this.eventId,
    required this.eventDate,
    required this.transactionDate,
    required this.amount,
    required this.formattedAmount,
    required this.paymentMethod,
    required this.status,
    required this.ticketCode,
    required this.ticketId,
    required this.ticketQuantity,
    required this.createdAt,
    required this.updatedAt,
    required this.profileImage,
  });

  factory TransactionRecord.fromMap(String id, Map<dynamic, dynamic> data) {
    return TransactionRecord(
      transactionId: data['transaction_id']?.toString() ?? id,
      userId: data['user_id']?.toString() ?? '',
      userName: data['user_name']?.toString() ?? '',
      userEmail: data['user_email']?.toString() ?? '',
      eventName: data['event_name']?.toString() ?? '',
      eventId: data['event_id']?.toString() ?? '',
      eventDate: data['event_date']?.toString() ?? '',
      transactionDate: data['transaction_date']?.toString() ?? '',
      amount: (data['amount'] is num)
          ? (data['amount'] as num).toDouble()
          : double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0,
      formattedAmount: data['formatted_amount']?.toString() ?? '',
      paymentMethod: data['payment_method']?.toString() ?? '',
      status: data['status']?.toString() ?? '',
      ticketCode: data['ticket_code']?.toString() ?? '',
      ticketId: data['ticket_id']?.toString() ?? '',
      ticketQuantity: (data['ticket_quantity'] is num)
          ? (data['ticket_quantity'] as num).toInt()
          : int.tryParse(data['ticket_quantity']?.toString() ?? '1') ?? 1,
      createdAt: (data['created_at'] is num)
          ? (data['created_at'] as num).toInt()
          : int.tryParse(data['created_at']?.toString() ?? '0') ?? 0,
      updatedAt: (data['updated_at'] is num)
          ? (data['updated_at'] as num).toInt()
          : int.tryParse(data['updated_at']?.toString() ?? '0') ?? 0,

      // If you ever decide to also store profileImage directly in transaction,
      // this line will pick it up; otherwise it'll be filled later.
      profileImage:
          data['profileImage']?.toString() ??
          data['user_profile_image']?.toString() ??
          '',
    );
  }

  // 👇 helper to easily update just profileImage
  TransactionRecord copyWith({String? profileImage}) {
    return TransactionRecord(
      transactionId: transactionId,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      eventName: eventName,
      eventId: eventId,
      eventDate: eventDate,
      transactionDate: transactionDate,
      amount: amount,
      formattedAmount: formattedAmount,
      paymentMethod: paymentMethod,
      status: status,
      ticketCode: ticketCode,
      ticketId: ticketId,
      ticketQuantity: ticketQuantity,
      createdAt: createdAt,
      updatedAt: updatedAt,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}

class TransactionFetchService {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

  /// Fetch all transactions (admin view), enriched with student.profileImage
  Future<List<TransactionRecord>> fetchAllTransactions() async {
    try {
      final txSnapshot = await _databaseRef.child('transactions').get();

      if (!txSnapshot.exists) {
        return [];
      }

      final txData = txSnapshot.value as Map<dynamic, dynamic>;
      final List<TransactionRecord> transactions = [];

      txData.forEach((key, value) {
        if (value is Map) {
          transactions.add(
            TransactionRecord.fromMap(
              key.toString(),
              Map<dynamic, dynamic>.from(value),
            ),
          );
        }
      });

      // Sort by created_at descending (newest first)
      transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // 🔹 Fetch all students once
      final studentsSnapshot = await _databaseRef.child('students').get();
      Map<String, dynamic> studentsMap = {};

      if (studentsSnapshot.exists) {
        studentsMap = Map<String, dynamic>.from(
          studentsSnapshot.value as Map<dynamic, dynamic>,
        );
      }

      // 🔹 Attach profileImage based on userId
      final List<TransactionRecord> enriched = transactions.map((tx) {
        final studentDataRaw = studentsMap[tx.userId];
        if (studentDataRaw is Map) {
          final studentData = Map<String, dynamic>.from(studentDataRaw);
          final imageUrl = studentData['profileImage']?.toString() ?? '';
          return tx.copyWith(profileImage: imageUrl);
        }
        return tx;
      }).toList();

      return enriched;
    } catch (e) {
      print('❌ Error fetching transactions: $e');
      return [];
    }
  }
}

// Singleton instance
final transactionFetchService = TransactionFetchService();
