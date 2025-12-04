import 'package:dnsc_events/colors/color.dart';
import 'package:dnsc_events/studentScreen/viewTicket.dart';
import 'package:flutter/material.dart';
import 'package:dnsc_events/widget/appbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'package:dnsc_events/database/deleteLongPressTicket.dart';
import 'package:dnsc_events/student.dart';
import 'package:dnsc_events/widget/paginationUi.dart';
import 'dart:math' as math;

class Myticket extends StatefulWidget {
  const Myticket({super.key});

  @override
  State<Myticket> createState() => _MyticketState();
}

class _MyticketState extends State<Myticket> {
  bool isLoading = true;
  bool _loadingImages = false;
  String _searchQuery = '';
  String? _userId;

  // Ticket data without images
  List<Map<String, dynamic>> _allTickets = [];
  List<Map<String, dynamic>> _filteredTickets = [];
  List<Map<String, dynamic>> _paginatedTickets = [];

  // Images cache for loaded tickets
  Map<String, ImageProvider?> _imageCache = {};

  // Pagination variables
  int _currentPage = 0;
  final int _itemsPerPage = 5;
  int _totalPages = 1;

  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  void _initializeUser() {
    if (_user != null) {
      _userId = _user!.uid;
      _loadUserTickets();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showDeleteDialog(Map<String, dynamic> ticket) {
    final eventName = ticket['event_name'] ?? 'Unknown Event';
    final canDelete = deleteTicketService.canDeleteTicket(ticket);
    final message = deleteTicketService.getDeletionMessage(ticket);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 400, minWidth: 300),
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: canDelete
                            ? Colors.red.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        canDelete ? Icons.delete_outline : Icons.block,
                        color: canDelete ? Colors.red : Colors.orange,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            canDelete ? 'Delete Ticket' : 'Action Restricted',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            canDelete
                                ? 'Remove this ticket permanently'
                                : 'This ticket cannot be deleted',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // Content
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.event,
                            size: 16,
                            color: CustomColor.primary,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              eventName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Divider(height: 1, color: Colors.grey.shade200),
                      SizedBox(height: 12),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Warning (only for deletable tickets)
                if (canDelete)
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This action cannot be undone.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: 20),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text('Cancel'),
                      ),
                    ),

                    if (canDelete) SizedBox(width: 12),

                    if (canDelete)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _deleteTicket(ticket);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text('Delete'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteTicket(Map<String, dynamic> ticket) async {
    final ticketId = ticket['ticket_id'];
    final eventName = ticket['event_name'] ?? 'Unknown Event';

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            CircularProgressIndicator(color: CustomColor.primary),
            SizedBox(height: 20),
          ],
        ),
      ),
    );

    try {
      final success = await deleteTicketService.deleteTicket(
        ticketId: ticketId,
        ticketData: ticket,
      );

      Navigator.pop(context); // Close loading dialog

      if (success) {
        // Remove from local lists
        setState(() {
          // Remove from all lists
          _allTickets.removeWhere((t) => t['ticket_id'] == ticketId);
          _filteredTickets.removeWhere((t) => t['ticket_id'] == ticketId);
          _paginatedTickets.removeWhere((t) => t['ticket_id'] == ticketId);

          // Remove from image cache
          _imageCache.remove(ticketId);

          // Update pagination
          _updatePagination();
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Ticket deleted successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Failed to delete ticket'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Error: ${e.toString()}'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _loadUserTickets() async {
    try {
      if (_userId == null) return;

      setState(() {
        isLoading = true;
        _imageCache.clear();
      });

      final ticketRef = _databaseRef
          .child('ticket_purchase')
          .orderByChild('user_id')
          .equalTo(_userId);

      final event = await ticketRef.once();
      final ticketsData = event.snapshot.value;
      _allTickets.clear();

      if (ticketsData != null && ticketsData is Map) {
        for (var entry in ticketsData.entries) {
          final ticketId = entry.key;
          final ticketData = entry.value as Map<dynamic, dynamic>;

          _allTickets.add({
            'ticket_id': ticketId,
            ...ticketData,
            // Don't load image yet, just store event key
            'event_key': ticketData['event_key'],
          });
        }
      }

      _allTickets.sort((a, b) {
        final dateA = a['created_at'] ?? 0;
        final dateB = b['created_at'] ?? 0;
        return dateB.compareTo(dateA);
      });

      _filteredTickets = List.from(_allTickets);
      _updatePagination();

      // Load images for current page only
      await _loadImagesForCurrentPage();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error loading tickets: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadImagesForCurrentPage() async {
    setState(() {
      _loadingImages = true;
    });

    try {
      // Only load images for tickets on current page
      for (var ticket in _paginatedTickets) {
        final ticketId = ticket['ticket_id'];
        final eventKey = ticket['event_key'];

        // Skip if already in cache
        if (!_imageCache.containsKey(ticketId) && eventKey != null) {
          final image = await _getEventImage(eventKey.toString());
          _imageCache[ticketId] = image;
        }
      }
    } catch (e) {
      print('Error loading images: $e');
    } finally {
      setState(() {
        _loadingImages = false;
      });
    }
  }

  Future<ImageProvider?> _getEventImage(String eventKey) async {
    try {
      final eventSnapshot = await _databaseRef
          .child('events')
          .child(eventKey)
          .get();

      if (eventSnapshot.exists) {
        final eventData = eventSnapshot.value as Map<dynamic, dynamic>;

        if (eventData['event_image_type'] == 'base64' &&
            eventData['event_image'] != null) {
          try {
            final base64String = eventData['event_image'].toString();
            final imageData = base64String.split(',').last;
            return MemoryImage(base64Decode(imageData));
          } catch (e) {
            print('Error decoding base64 image: $e');
            return null;
          }
        } else if (eventData['event_image'] != null) {
          return NetworkImage(eventData['event_image'].toString());
        }
      }
    } catch (e) {
      print('Error loading event image: $e');
    }
    return null;
  }

  void _searchEvents(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (query.isEmpty) {
        _filteredTickets = List.from(_allTickets);
      } else {
        _filteredTickets = _allTickets.where((ticket) {
          final eventName = (ticket['event_name'] ?? '')
              .toString()
              .toLowerCase();
          final ticketCode = (ticket['ticket_code'] ?? '')
              .toString()
              .toLowerCase();
          final eventType = (ticket['event_type'] ?? '')
              .toString()
              .toLowerCase();
          return eventName.contains(query) ||
              ticketCode.contains(query) ||
              eventType.contains(query);
        }).toList();
      }
      _currentPage = 0;
      _updatePagination();
    });

    // Load images for new filtered page
    _loadImagesForCurrentPage();
  }

  void _updatePagination() {
    final total = _filteredTickets.length;

    // compute total pages
    _totalPages = (total / _itemsPerPage).ceil();
    if (_totalPages == 0) _totalPages = 1;

    // clamp current page between 0 and totalPages - 1
    if (_currentPage < 0) _currentPage = 0;
    if (_currentPage > _totalPages - 1) _currentPage = _totalPages - 1;

    // compute start/end indices
    if (total == 0) {
      _paginatedTickets = [];
      return;
    }

    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = math.min(startIndex + _itemsPerPage, total);

    _paginatedTickets = _filteredTickets.sublist(startIndex, endIndex);
  }

  void _goToPage(int pageIndex) async {
    setState(() {
      _currentPage = pageIndex;
      _updatePagination();
    });
    await _loadImagesForCurrentPage();
  }

  void _goToNextPage() async {
    if (_currentPage < _totalPages - 1) {
      setState(() {
        _currentPage++;
        _updatePagination();
      });
      await _loadImagesForCurrentPage();
    }
  }

  void _goToPreviousPage() async {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
        _updatePagination();
      });
      await _loadImagesForCurrentPage();
    }
  }

  void _onMenuPressed() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Filter Tickets',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'InterExtra',
                ),
              ),
              SizedBox(height: 20),
              _buildFilterOption('All Tickets', Icons.all_inclusive),
              _buildFilterOption('Active', Icons.check_circle),
              _buildFilterOption('Used', Icons.done_all),
              _buildFilterOption('Cancelled', Icons.cancel),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: CustomColor.primary),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        _filterByStatus(title.toLowerCase());
      },
    );
  }

  void _filterByStatus(String status) async {
    setState(() {
      if (status == 'all tickets') {
        _filteredTickets = List.from(_allTickets);
      } else {
        _filteredTickets = _allTickets.where((ticket) {
          final ticketStatus = (ticket['order_status'] ?? '')
              .toString()
              .toLowerCase();
          return ticketStatus == status;
        }).toList();
      }
      _currentPage = 0;
      _updatePagination();
    });

    // Load images for filtered page
    await _loadImagesForCurrentPage();
  }

  String _formatDate(int timestamp) {
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'used':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Active';
      case 'pending':
        return 'Pending';
      case 'used':
        return 'Used';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColor.background,
      appBar: Appbar(),
      body: RefreshIndicator(
        onRefresh: _loadUserTickets,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: Text(
                      'My',
                      style: TextStyle(
                        fontSize: 24,
                        fontFamily: 'InterExtra',
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    ' Ticket',
                    style: TextStyle(
                      fontSize: 24,
                      fontFamily: 'InterExtra',
                      color: CustomColor.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),

              // Search Box
              Container(
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Icon(Icons.search_outlined, color: Colors.grey.shade400),
                    SizedBox(width: 5),
                    Expanded(
                      child: TextField(
                        onChanged: _searchEvents,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          isCollapsed: true,
                          hintText: "Search Tickets",
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _onMenuPressed,
                      child: Icon(
                        Icons.filter_list,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),

              // Tickets Count and Pagination Info
              if (!isLoading && _user != null)
                Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          '${_filteredTickets.length} ticket${_filteredTickets.length == 1 ? '' : 's'} found',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          'Page ${_currentPage + 1} of $_totalPages',

                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          '(${_paginatedTickets.length} tickets on this page)',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              SizedBox(height: 10),

              // Loading Indicator for initial load
              if (isLoading)
                Container(
                  height: 400,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: CustomColor.primary,
                    ),
                  ),
                ),

              // Show message if no user
              if (!isLoading && _user == null)
                _buildLoginRequiredCard()
              else if (!isLoading && _filteredTickets.isEmpty)
                _buildNoTicketsCard()
              else if (!isLoading)
                // Ticket List with Pagination
                _buildTicketListWithPagination(),
            ],
          ),
        ),
      ),
      // Only Floating Action Button for refresh at bottom
      floatingActionButton: FloatingActionButton(
        onPressed: _loadUserTickets,
        backgroundColor: CustomColor.primary,
        child: Icon(Icons.refresh, color: Colors.white),
        mini: true,
      ),
    );
  }

  Widget _buildLoginRequiredCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(
            Icons.person_off_outlined,
            size: 60,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 10),
          Text(
            'Login Required',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'InterExtra',
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Please login to view your tickets',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildNoTicketsCard() {
    return Container(
      padding: EdgeInsets.all(20),
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
          SizedBox(height: 10),
          Text(
            'No Tickets Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'InterExtra',
            ),
          ),
          SizedBox(height: 10),
          Text(
            _searchQuery.isNotEmpty
                ? 'No tickets match your search'
                : 'You haven\'t purchased any tickets yet',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          SizedBox(height: 20),
          // Only Browse Events button (no refresh button)
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: CustomColor.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Student(initialIndex: 1),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Browse Events',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketListWithPagination() {
    return Column(
      children: [
        // Show loading indicator when images are loading
        if (_loadingImages)
          Container(
            margin: EdgeInsets.only(bottom: 10),
            child: Center(
              child: CircularProgressIndicator(
                color: CustomColor.primary,
                strokeWidth: 2,
              ),
            ),
          ),

        // Ticket List
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _paginatedTickets.length,
          itemBuilder: (context, index) {
            final ticket = _paginatedTickets[index];
            return _buildTicketCard(ticket, context);
          },
        ),

        // Reusable Pagination UI
        PaginationControls(
          currentPage: _currentPage,
          totalItems: _filteredTickets.length,
          itemsPerPage: _itemsPerPage,
          itemLabel: 'tickets',
          primaryColor: CustomColor.primary,
          onPrevious: _currentPage > 0 ? _goToPreviousPage : null,
          onNext: _currentPage < _totalPages - 1 ? _goToNextPage : null,
          onPageSelected: (pageIndex) => _goToPage(pageIndex),
          itemsPerPageOptions: const [5], // fixed 5 per page
        ),

        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket, BuildContext context) {
    final ticketId = ticket['ticket_id'];
    final eventName = ticket['event_name'] ?? 'Unnamed Event';
    final status = ticket['order_status'] ?? 'pending';
    final eventType = ticket['event_type'] ?? 'Event';
    final quantity = ticket['quantity'] ?? 1;
    final purchaseDate = ticket['created_at'] ?? 0;

    // Get image from cache
    final eventImageProvider = _imageCache[ticketId];

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => Viewticket(ticketData: ticket),
        );
      },
      onLongPress: () {
        _showDeleteDialog(ticket);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        height: 88,
        decoration: BoxDecoration(
          color: Colors.green.shade900,
          borderRadius: BorderRadius.horizontal(
            left: Radius.circular(12),
            right: Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              spreadRadius: 1,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.only(left: 5),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  // Event Image Container
                  Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: CustomColor.primary.withOpacity(0.1),
                    ),
                    child: eventImageProvider != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image(
                              image: eventImageProvider,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholderIcon();
                              },
                            ),
                          )
                        : _buildPlaceholderIcon(),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 10, bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  eventName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Add delete icon for tickets that can be deleted
                              if (deleteTicketService.canDeleteTicket(ticket))
                                Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                  color: Colors.grey.shade400,
                                )
                              else
                                Icon(
                                  Icons.arrow_forward_ios_outlined,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    status,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getStatusText(status),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _getStatusColor(status),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Qty: $quantity',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                eventType,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                _formatDate(purchaseDate),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Center(
      child: Icon(Icons.event, size: 30, color: CustomColor.primary),
    );
  }
}
