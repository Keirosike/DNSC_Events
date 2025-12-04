import 'package:firebase_database/firebase_database.dart';

class TransactionService {
  static final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Fetch total revenue (Paid) and Pending payments
  static Future<Map<String, dynamic>> getTransactionSummary() async {
    final snapshot = await _db.child("transactions").get();

    if (!snapshot.exists) {
      return {"totalRevenue": 0.0, "totalPending": 0.0};
    }

    double totalRevenue = 0.0;
    double totalPending = 0.0;

    for (var trx in snapshot.children) {
      final rawAmount = trx.child("amount").value;
      final amount = (rawAmount is num) ? rawAmount.toDouble() : 0.0;

      final status = trx.child("status").value?.toString() ?? "";

      if (status == "Paid") {
        totalRevenue += amount;
      } else if (status == "Pending") {
        totalPending += amount;
      }
    }

    return {"totalRevenue": totalRevenue, "totalPending": totalPending};
  }

  /// Compute summary from transactions & update `admins -> summary`
  static Future<void> updateAdminSummaryFromTransactions() async {
    try {
      final summary = await getTransactionSummary();

      final double totalRevenue = (summary["totalRevenue"] is num)
          ? (summary["totalRevenue"] as num).toDouble()
          : 0.0;

      final double totalPending = (summary["totalPending"] is num)
          ? (summary["totalPending"] as num).toDouble()
          : 0.0;

      final summaryRef = _db.child("admins").child("summary");

      await summaryRef.update({
        "total_revenue": totalRevenue,
        "total_pending": totalPending,
      });

      print(
        '📊 admins/summary updated → revenue: $totalRevenue, pending: $totalPending',
      );
    } catch (e) {
      print('❌ Error updating admins/summary from transactions: $e');
    }
  }
}
