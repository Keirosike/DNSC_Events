import 'dart:math' as math;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:dnsc_events/colors/color.dart';
import 'package:flutter/material.dart';
import 'package:dnsc_events/widget/appbar.dart';

import 'package:dnsc_events/adminScreen/transactioDetails.dart';
import 'package:dnsc_events/database/transactionGet.dart';
import 'package:dnsc_events/widget/paginationUi.dart'; // 👈 reuse pagination

class Transaction extends StatefulWidget {
  const Transaction({super.key});

  @override
  State<Transaction> createState() => _TransactionState();
}

class _TransactionState extends State<Transaction> {
  String _searchQuery = '';
  late Future<List<TransactionRecord>> _futureTransactions;

  // Pagination (0-based)
  int _currentPage = 0;
  int _itemsPerPage = 5; // 5 per page

  @override
  void initState() {
    super.initState();
    _futureTransactions = transactionFetchService.fetchAllTransactions();
  }

  void _refresh() {
    setState(() {
      _currentPage = 0; // reset page on refresh
      _futureTransactions = transactionFetchService.fetchAllTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColor.background,
      appBar: Appbaradmin(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 5),
                  child: Text(
                    'Transactions',
                    style: TextStyle(
                      fontSize: 24,
                      fontFamily: 'InterExtra',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Search Box
            Container(
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 1),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Icon(Icons.search_outlined, color: Colors.grey.shade400),
                  const SizedBox(width: 5),
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                          _currentPage = 0; // reset to first page on search
                        });
                      },
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        isCollapsed: true,
                        hintText: "Search Transaction",
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Add filter logic here if needed
                    },
                    child: Icon(Icons.filter_list, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Transactions via FutureBuilder
            FutureBuilder<List<TransactionRecord>>(
              future: _futureTransactions,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 200),
                      Center(
                        child: CircularProgressIndicator(
                          color: CustomColor.primary,
                        ),
                      ),
                    ],
                  );
                }

                if (snapshot.hasError) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Error loading transactions',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ],
                  );
                }

                final all = snapshot.data ?? [];

                // apply search
                final filtered = all.where((tx) {
                  if (_searchQuery.isEmpty) return true;
                  final q = _searchQuery;
                  return tx.userName.toLowerCase().contains(q) ||
                      tx.userEmail.toLowerCase().contains(q) ||
                      tx.eventName.toLowerCase().contains(q) ||
                      tx.transactionId.toLowerCase().contains(q);
                }).toList();

                final int totalItems = filtered.length;
                final int totalPages = totalItems == 0
                    ? 0
                    : (totalItems / _itemsPerPage).ceil();

                // Safe current page index (0-based)
                final int safePage = totalPages == 0
                    ? 0
                    : _currentPage.clamp(0, totalPages - 1);

                // Slice current page items
                final int startIndex = safePage * _itemsPerPage;
                final int endIndex = math.min(
                  startIndex + _itemsPerPage,
                  totalItems,
                );

                final List<TransactionRecord> pageItems = totalItems == 0
                    ? <TransactionRecord>[]
                    : filtered.sublist(startIndex, endIndex);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$totalItems transaction${totalItems == 1 ? '' : 's'} found',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (filtered.isEmpty) ...[
                      // Empty State Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.confirmation_number_outlined,
                              size: 60,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'No Transaction Found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'InterExtra',
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: CustomColor.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'No transaction found',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 10),

                      // 🔽 Paginated List (5 per page)
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: pageItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final tx = pageItems[index];
                          return _buildTransactionCard(context, tx);
                        },
                      ),

                      // 🔁 Reusable Pagination Controls
                      PaginationControls(
                        currentPage: safePage, // 0-based
                        totalItems: totalItems,
                        itemsPerPage: _itemsPerPage,
                        itemLabel: 'transactions',
                        primaryColor: CustomColor.primary,
                        onPrevious: () {
                          setState(() {
                            if (_currentPage > 0) {
                              _currentPage--;
                            }
                          });
                        },
                        onNext: () {
                          setState(() {
                            if (totalPages > 0 &&
                                _currentPage < totalPages - 1) {
                              _currentPage++;
                            }
                          });
                        },
                        onPageSelected: (page) {
                          setState(() {
                            _currentPage = page;
                          });
                        },
                        itemsPerPageOptions: const [5, 10, 20],
                        onItemsPerPageChanged: (newSize) {
                          setState(() {
                            _itemsPerPage = newSize;
                            _currentPage = 0;
                          });
                        },
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _refresh,
        backgroundColor: CustomColor.primary,
        child: const Icon(Icons.refresh, color: Colors.white),
        mini: true,
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, TransactionRecord tx) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            return TransactionDetails(transaction: tx);
          },
        );
      },
      child: Container(
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
                      // Left info
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${tx.transactionId}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            tx.userName.isNotEmpty ? tx.userName : tx.userEmail,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tx.eventName,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Right info
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            tx.formattedAmount.isNotEmpty
                                ? tx.formattedAmount
                                : '₱${tx.amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            tx.transactionDate,
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
          ],
        ),
      ),
    );
  }
}
