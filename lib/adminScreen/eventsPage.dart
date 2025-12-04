import 'dart:convert'; // Add this import for base64Decode
import 'package:auto_size_text/auto_size_text.dart';
import 'package:dnsc_events/adminScreen/createEvent.dart';
import 'package:dnsc_events/widget/appbar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:dnsc_events/colors/color.dart';
import 'package:dnsc_events/adminScreen/readEvent.dart';
import 'package:dnsc_events/widget/paginationUi.dart'; // 👈 reusable pagination

class Eventadmin extends StatefulWidget {
  const Eventadmin({super.key});

  @override
  State<Eventadmin> createState() => _EventadminState();
}

class _EventadminState extends State<Eventadmin> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref(
    'events',
  );

  List<Map<String, dynamic>> _allEvents = [];
  List<Map<String, dynamic>> _displayedEvents = [];
  List<Map<String, dynamic>> _filteredEvents = [];

  bool _isLoading = true;
  bool _loadingMore = false;
  bool _hasMore = true;

  int _currentPage = 0; // 0-based index
  int _itemsPerPage = 4; // 4 items per page
  String _searchQuery = '';

  final ScrollController _scrollController = ScrollController();
  final int _initialLoadCount = 12; // first batch

  @override
  void initState() {
    super.initState();
    _loadInitialEvents();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------- SCROLL & FETCH ----------------

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreEvents();
      }
    });
  }

  Future<void> _loadInitialEvents() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final snapshot = await _databaseRef.get();

      if (snapshot.exists) {
        final eventsMap = snapshot.value as Map<dynamic, dynamic>;

        final List<Map<String, dynamic>> eventsList = [];

        eventsMap.forEach((key, value) {
          eventsList.add({
            'key': key.toString(),
            ...Map<String, dynamic>.from(value),
          });
        });

        // Sort by event_id descending
        eventsList.sort(
          (a, b) => (b['event_id'] ?? 0).compareTo(a['event_id'] ?? 0),
        );

        setState(() {
          _allEvents = eventsList;
          _filteredEvents = eventsList;
          _displayedEvents = _filteredEvents.take(_initialLoadCount).toList();
          _isLoading = false;
          _hasMore = _filteredEvents.length > _displayedEvents.length;
          _currentPage = 0; // reset
        });
      } else {
        setState(() {
          _allEvents = [];
          _filteredEvents = [];
          _displayedEvents = [];
          _isLoading = false;
          _hasMore = false;
          _currentPage = 0;
        });
      }
    } catch (e) {
      print('Error loading events: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreEvents() async {
    if (_loadingMore || !_hasMore) return;

    setState(() {
      _loadingMore = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    final currentLength = _displayedEvents.length;
    final nextItems = currentLength + _itemsPerPage;

    setState(() {
      if (nextItems < _filteredEvents.length) {
        _displayedEvents = _filteredEvents.take(nextItems).toList();
        _hasMore = true;
      } else {
        _displayedEvents = _filteredEvents;
        _hasMore = false;
      }
      _loadingMore = false;
    });
  }

  // ---------------- SEARCH ----------------

  void _searchEvents(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 0;

      if (query.isEmpty) {
        _filteredEvents = _allEvents;
      } else {
        final queryLower = query.toLowerCase();
        _filteredEvents = _allEvents.where((event) {
          final name = event['event_name']?.toString().toLowerCase() ?? '';
          final type = event['event_type']?.toString().toLowerCase() ?? '';
          final location =
              event['event_location']?.toString().toLowerCase() ?? '';

          return name.contains(queryLower) ||
              type.contains(queryLower) ||
              location.contains(queryLower);
        }).toList();
      }

      _displayedEvents = _filteredEvents.take(_initialLoadCount).toList();
      _hasMore = _filteredEvents.length > _displayedEvents.length;
    });
  }

  // ---------------- PAGINATION HELPERS ----------------

  List<Map<String, dynamic>> _getCurrentPageEvents() {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    if (startIndex >= _displayedEvents.length) return [];

    return _displayedEvents.sublist(
      startIndex,
      endIndex.clamp(0, _displayedEvents.length),
    );
  }

  void _nextPage() {
    final totalPages = (_displayedEvents.length / _itemsPerPage).ceil();
    if (_currentPage < totalPages - 1) {
      setState(() {
        _currentPage++;
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _goToPage(int page) {
    final totalPages = (_displayedEvents.length / _itemsPerPage).ceil();
    if (page >= 0 && page < totalPages) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  // ---------------- FORMATTERS ----------------

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final monthNames = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${monthNames[date.month - 1]}. ${date.day}, ${date.year}';
    } catch (_) {
      return 'Invalid Date';
    }
  }

  String _formatTime(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final period = hour >= 12 ? 'PM' : 'AM';
        hour = hour % 12;
        hour = hour == 0 ? 12 : hour;
        return '$hour:${minute.toString().padLeft(2, '0')} $period';
      }
      return timeString;
    } catch (_) {
      return 'Invalid Time';
    }
  }

  String _getEventStatus(Map<String, dynamic> event) {
    try {
      final dateString = event['event_date'];
      if (dateString != null) {
        final eventDate = DateTime.parse(dateString);
        final now = DateTime.now();

        if (eventDate.isBefore(now.subtract(const Duration(days: 1)))) {
          return 'Completed';
        } else if (eventDate.isAfter(now)) {
          return 'Upcoming';
        } else {
          return 'Today';
        }
      }
      return 'Unknown';
    } catch (_) {
      return 'Unknown';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Upcoming':
      case 'Today':
        return Colors.green.shade800;
      case 'Completed':
        return Colors.grey.shade600;
      default:
        return Colors.grey.shade800;
    }
  }

  // ---------------- EVENT CARD ----------------

  Widget _buildEventContainer(Map<String, dynamic> event) {
    final status = _getEventStatus(event);
    final ticketsSold = event['tickets_sold'] ?? 0;
    final ticketQuantity = event['ticket_quantity'] ?? 1;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                Readevent(eventData: event, eventKey: event['key']),
          ),
        );
      },
      child: Container(
        height: 244,
        width: 157,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(width: 1, color: CustomColor.borderGray),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 130,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    color: Colors.grey.shade200,
                  ),
                  child: event['event_image'] != null
                      ? FutureBuilder<Widget>(
                          future: _buildEventImage(event['event_image']),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              );
                            }
                            return snapshot.data ?? _buildPlaceholderImage();
                          },
                        )
                      : _buildPlaceholderImage(),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.only(
                left: 10,
                right: 10,
                top: 8,
                bottom: 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Name
                  SizedBox(
                    width: 150,
                    child: AutoSizeText(
                      event['event_name']?.toString() ?? 'Unnamed Event',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      minFontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Location
                  _buildEventInfo(
                    Icons.location_on,
                    event['event_location']?.toString() ?? 'No Location',
                  ),
                  const SizedBox(height: 4),

                  // Date & Time
                  _buildEventInfo(
                    Icons.calendar_month_rounded,
                    '${_formatDate(event['event_date']?.toString() ?? '')} • ${_formatTime(event['event_start_time']?.toString() ?? '')}',
                  ),
                  const SizedBox(height: 4),

                  // Price
                  _buildEventInfo(
                    Icons.price_change_rounded,
                    'P${(event['ticket_price'] ?? 0.0).toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 6),

                  // Tickets Sold
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.confirmation_number,
                            size: 12,
                            color: Colors.green.shade900,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Tickets:',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$ticketsSold/$ticketQuantity Sold',
                        style: TextStyle(
                          fontSize: 10,
                          color: ticketsSold >= ticketQuantity
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventInfo(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Icon(icon, color: CustomColor.green, size: 12),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 4),
          Text(
            'No Image',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Future<Widget> _buildEventImage(dynamic imageData) async {
    try {
      if (imageData is String) {
        // base64?
        if (imageData.contains(';base64,') || imageData.length > 1000) {
          final base64String = imageData.contains(';base64,')
              ? imageData.split(',').last
              : imageData;

          if (base64String.isEmpty) {
            return _buildPlaceholderImage();
          }

          try {
            return ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Image.memory(
                base64Decode(base64String),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  print('Error decoding base64: $error');
                  return _buildPlaceholderImage();
                },
              ),
            );
          } catch (e) {
            print('Base64 decode error: $e');
            return _buildPlaceholderImage();
          }
        } else {
          // URL
          return ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Image.network(
              imageData,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholderImage();
              },
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading event image: $e');
    }
    return _buildPlaceholderImage();
  }

  // ---------------- GRID + PAGINATION ----------------

  Widget _buildGridView(List<Map<String, dynamic>> events) {
    return Column(
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: events.map(_buildEventContainer).toList(),
        ),
        if (events.isEmpty && !_isLoading)
          SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 50, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No events found',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  if (_searchQuery.isNotEmpty)
                    Text(
                      'Try a different search',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPaginationControls() {
    final currentPageEvents = _getCurrentPageEvents();
    if (currentPageEvents.isEmpty || _displayedEvents.isEmpty) {
      return const SizedBox();
    }

    final totalItems = _displayedEvents.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    if (totalPages < 2) return const SizedBox();

    return PaginationControls(
      currentPage: _currentPage, // 0-based
      totalItems: totalItems,
      itemsPerPage: _itemsPerPage,
      itemLabel: 'events',
      primaryColor: CustomColor.primary,
      onPrevious: _currentPage > 0 ? _previousPage : null,
      onNext: _currentPage < totalPages - 1 ? _nextPage : null,
      onPageSelected: (pageIndex) => _goToPage(pageIndex),
      itemsPerPageOptions: const [4],
      onItemsPerPageChanged: (value) {
        setState(() {
          _itemsPerPage = value;
          _currentPage = 0;
        });
      },
    );
  }

  Widget _buildLoadingIndicator() {
    if (!_loadingMore) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(
              strokeWidth: 2,
              color: CustomColor.primary,
            ),
            const SizedBox(height: 10),
            Text(
              'Loading more events...',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- BUILD ----------------

  @override
  Widget build(BuildContext context) {
    final currentEvents = _getCurrentPageEvents();

    return Scaffold(
      backgroundColor: CustomColor.background,
      appBar: Appbaradmin(),
      body: RefreshIndicator(
        onRefresh: _loadInitialEvents,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'Events',
                    style: TextStyle(
                      fontFamily: 'InterExtra',
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Createevent(),
                        ),
                      ).then((_) => _loadInitialEvents());
                    },
                    child: Container(
                      height: 35,
                      width: 35,
                      decoration: BoxDecoration(
                        color: CustomColor.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
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
                        onChanged: _searchEvents,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          isCollapsed: true,
                          hintText: "Search Events",
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    Icon(Icons.filter_list, color: Colors.grey.shade400),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Events Count
              if (!_isLoading)
                Row(
                  children: [
                    Text(
                      '${_filteredEvents.length} event${_filteredEvents.length == 1 ? '' : 's'} found',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (_displayedEvents.length < _filteredEvents.length)
                      Text(
                        ' (${_displayedEvents.length} loaded)',
                        style: TextStyle(
                          fontSize: 12,
                          color: CustomColor.primary,
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 10),

              // Loading
              if (_isLoading)
                SizedBox(
                  height: 400,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: CustomColor.primary,
                    ),
                  ),
                ),

              // Events Grid + Pagination
              if (!_isLoading) ...[
                _buildGridView(currentEvents),
                _buildPaginationControls(),
                _buildLoadingIndicator(),

                if (_hasMore && !_loadingMore)
                  Container(
                    margin: const EdgeInsets.only(top: 20, bottom: 30),
                    child: ElevatedButton(
                      onPressed: _loadMoreEvents,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CustomColor.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Load More Events',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                if (!_hasMore && _displayedEvents.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Text(
                      'No more events to load',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadInitialEvents,
        backgroundColor: CustomColor.primary,
        child: const Icon(Icons.refresh, color: Colors.white),
        mini: true,
      ),
    );
  }
}
