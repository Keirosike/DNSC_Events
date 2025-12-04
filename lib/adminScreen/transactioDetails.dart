import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:dnsc_events/colors/color.dart';
import 'package:dnsc_events/database/transactionGet.dart'; // 👈 import for TransactionRecord

class TransactionDetails extends StatefulWidget {
  final TransactionRecord transaction; // 👈 add this

  const TransactionDetails({
    super.key,
    required this.transaction, // 👈 required parameter
  });

  @override
  State<TransactionDetails> createState() => _TransactionDetailsState();
}

class _TransactionDetailsState extends State<TransactionDetails> {
  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction; // shorthand

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            height: 566,
            decoration: BoxDecoration(
              color: Colors.white,
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

                  // Title
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Transaction Details',
                          style: TextStyle(
                            fontFamily: 'InterExtra',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),

                  Divider(
                    color: CustomColor.borderGray1,
                    thickness: 1,
                    height: 20,
                  ),

                  // Transaction ID
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Transaction ID',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: Text(
                          tx.transactionId,
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),

                  Divider(
                    color: CustomColor.borderGray1,
                    thickness: 1,
                    height: 20,
                  ),

                  // User
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text('User', style: TextStyle(fontSize: 14)),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            // Profile image
                            Container(
                              height: 38,
                              width: 38,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(50),
                                image: tx.profileImage.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(tx.profileImage),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: tx.profileImage.isEmpty
                                  ? Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 20,
                                    )
                                  : null,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AutoSizeText(
                                    tx.userName.isNotEmpty
                                        ? tx.userName
                                        : tx.userEmail,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxFontSize: 14,
                                    minFontSize: 8,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  AutoSizeText(
                                    tx.userEmail,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                    maxFontSize: 12,
                                    minFontSize: 8,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),

                  Divider(
                    color: CustomColor.borderGray1,
                    thickness: 1,
                    height: 20,
                  ),

                  // Event
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text('Event', style: TextStyle(fontSize: 14)),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: AutoSizeText(
                          tx.eventName,
                          style: TextStyle(fontSize: 14),
                          maxFontSize: 14,
                          minFontSize: 10,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  Divider(
                    color: CustomColor.borderGray1,
                    thickness: 1,
                    height: 20,
                  ),

                  // Event Date
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Event Date',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: Text(
                          tx.eventDate, // you can format this if needed
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),

                  Divider(
                    color: CustomColor.borderGray1,
                    thickness: 1,
                    height: 20,
                  ),

                  // Transaction Date
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Transaction Date',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: Text(
                          tx.transactionDate,
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),

                  Divider(
                    color: CustomColor.borderGray1,
                    thickness: 1,
                    height: 20,
                  ),

                  // Amount
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text('Amount', style: TextStyle(fontSize: 14)),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: Text(
                          tx.formattedAmount.isNotEmpty
                              ? tx.formattedAmount
                              : '₱${tx.amount.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),

                  Divider(
                    color: CustomColor.borderGray1,
                    thickness: 1,
                    height: 20,
                  ),

                  // Payment Method
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Payment Method',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: Text(
                          tx.paymentMethod,
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),

                  Divider(
                    color: CustomColor.borderGray1,
                    thickness: 1,
                    height: 20,
                  ),

                  // Status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status', style: TextStyle(fontSize: 14)),
                      SizedBox(width: 70),
                      Container(
                        height: 20,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: CustomColor.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Center(
                          child: Text(
                            tx.status,
                            style: TextStyle(
                              color: CustomColor.primary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),

                  Divider(
                    color: CustomColor.borderGray1,
                    thickness: 1,
                    height: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
