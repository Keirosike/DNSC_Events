// lib/widget/pagination_controls.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

class PaginationControls extends StatelessWidget {
  /// 0-based current page index
  final int currentPage;

  /// Total items (events, students, tickets, etc.)
  final int totalItems;

  /// Items per page (current selected)
  final int itemsPerPage;

  /// Label for items: "events", "students", "tickets", etc.
  final String itemLabel;

  /// Main color (you'll pass CustomColor.primary)
  final Color primaryColor;

  /// Go to previous page
  final VoidCallback? onPrevious;

  /// Go to next page
  final VoidCallback? onNext;

  /// Go to specific page (0-based index)
  final ValueChanged<int>? onPageSelected;

  /// Available options for items per page (e.g. [4, 5, 10])
  final List<int> itemsPerPageOptions;

  /// Callback when user changes items per page
  final ValueChanged<int>? onItemsPerPageChanged;

  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.totalItems,
    required this.itemsPerPage,
    required this.itemLabel,
    required this.primaryColor,
    this.onPrevious,
    this.onNext,
    this.onPageSelected,
    this.itemsPerPageOptions = const [],
    this.onItemsPerPageChanged,
  });

  int get _totalPages => (totalItems / itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    final totalPages = _totalPages;

    if (totalItems == 0 || totalPages < 2) {
      return const SizedBox();
    }

    final startItem = currentPage * itemsPerPage + 1;
    final endItem = math.min((currentPage + 1) * itemsPerPage, totalItems);

    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row: "Showing X-Y of Z" + (optional) page size selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    'Showing $startItem-$endItem of $totalItems $itemLabel',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous Button
              Container(
                width: 80,
                height: 40,
                decoration: BoxDecoration(
                  color: currentPage > 0
                      ? primaryColor.withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: currentPage > 0
                        ? primaryColor.withOpacity(0.5)
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: TextButton(
                  onPressed: currentPage > 0 ? onPrevious : null,
                  style: TextButton.styleFrom(
                    foregroundColor: currentPage > 0
                        ? primaryColor
                        : Colors.grey.shade500,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: currentPage > 0
                            ? primaryColor
                            : Colors.grey.shade500,
                      ),
                    ],
                  ),
                ),
              ),

              // Page Indicator with Dots
              Column(
                children: [
                  // Page Info
                  Text(
                    'Page ${currentPage + 1} of $totalPages',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Page Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      math.min(totalPages, 7), // Show max 7 dots
                      (index) {
                        bool isCurrentPage = index == currentPage;
                        bool showDot = true;

                        // For many pages, show ellipsis and only nearby pages
                        if (totalPages > 7) {
                          if (index == 0 || index == 6) {
                            // First and last dot
                            showDot = true;
                          } else if (index == 3 &&
                              currentPage > 2 &&
                              currentPage < totalPages - 3) {
                            // Middle dot for ellipsis
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: Text(
                                '...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          } else if (index == 1 || index == 2) {
                            // Dots near beginning
                            showDot = true;
                          } else if (index == 4 || index == 5) {
                            // Dots near end
                            showDot = true;
                          } else {
                            showDot = false;
                          }
                        }

                        if (showDot) {
                          return GestureDetector(
                            onTap: onPageSelected != null
                                ? () => onPageSelected!(index)
                                : null,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              width: isCurrentPage ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isCurrentPage
                                    ? primaryColor
                                    : Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          );
                        } else {
                          return const SizedBox(width: 8);
                        }
                      },
                    ),
                  ),
                ],
              ),

              // Next Button
              Container(
                width: 80,
                height: 40,
                decoration: BoxDecoration(
                  color: currentPage < totalPages - 1
                      ? primaryColor.withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: currentPage < totalPages - 1
                        ? primaryColor.withOpacity(0.5)
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: TextButton(
                  onPressed: currentPage < totalPages - 1 ? onNext : null,
                  style: TextButton.styleFrom(
                    foregroundColor: currentPage < totalPages - 1
                        ? primaryColor
                        : Colors.grey.shade500,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_forward,
                        size: 20,
                        color: currentPage < totalPages - 1
                            ? primaryColor
                            : Colors.grey.shade500,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
