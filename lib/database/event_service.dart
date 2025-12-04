import 'dart:convert';
import 'dart:io';

import 'package:firebase_database/firebase_database.dart';

import 'package:dnsc_events/database/imageCompression.dart';

class EventService {
  final DatabaseReference _databaseRef;
  final ImageCompressionService _imageCompressionService;

  EventService({
    DatabaseReference? databaseRef,
    ImageCompressionService? imageCompressionService,
  }) : _databaseRef = databaseRef ?? FirebaseDatabase.instance.ref(),
       _imageCompressionService =
           imageCompressionService ?? ImageCompressionService();

  /// Compress + convert to Base64.
  /// If [imageFile] is null, just return [existingBase64].
  Future<String?> prepareBase64ForEventImage({
    File? imageFile,
    String? existingBase64,
  }) async {
    if (imageFile == null) return existingBase64;

    final File compressed = await _imageCompressionService.compressImageSmart(
      imageFile,
    );

    final List<int> bytes = await compressed.readAsBytes();
    final String base64Image = base64Encode(bytes);
    return base64Image;
  }

  /// Get next event_id by scanning existing events and finding max.
  Future<int> _getNextEventId() async {
    try {
      final DataSnapshot snapshot = await _databaseRef.child('events').get();

      if (!snapshot.exists) {
        return 1;
      }

      final value = snapshot.value;
      if (value is! Map) {
        return 1;
      }

      Map<dynamic, dynamic> events = value;
      int maxId = 0;

      events.forEach((key, raw) {
        if (raw is Map && raw['event_id'] != null) {
          final dynamic idVal = raw['event_id'];
          int eventId;
          if (idVal is int) {
            eventId = idVal;
          } else if (idVal is String) {
            eventId = int.tryParse(idVal) ?? 0;
          } else {
            eventId = 0;
          }
          if (eventId > maxId) {
            maxId = eventId;
          }
        }
      });

      return maxId + 1;
    } catch (e) {
      print('Error getting next event ID: $e');
      return 1;
    }
  }

  /// Create event (used by Createevent screen)
  ///
  /// [formData] should NOT include:
  /// - event_id
  /// - event_image / event_image_type
  /// - tickets_sold
  /// - created_at / updated_at
  Future<String> createEvent({
    required Map<String, dynamic> formData,
    required String base64Image,
  }) async {
    print('🟡 Getting next event ID...');
    final int nextEventId = await _getNextEventId();
    print('🟢 Next event ID: $nextEventId');

    final String eventKey = _databaseRef.child('events').push().key!;
    print('🟢 New event key: $eventKey');

    final Map<String, dynamic> eventData = {
      'event_id': nextEventId,
      ...formData,
      'event_image': base64Image,
      'event_image_type': 'base64',
      'tickets_sold': 0,
      'created_at': ServerValue.timestamp,
      'updated_at': ServerValue.timestamp,
    };

    print('🟡 Saving event to database at events/$eventKey');
    await _databaseRef.child('events').child(eventKey).set(eventData);
    print('🟢 Event created successfully!');

    // 🔹 Increment admin -> summary -> events_created
    await _incrementAdminEventCountOnCreate();

    return eventKey;
  }

  /// Update event (used by Editevent screen)
  ///
  /// [formData] should NOT include:
  /// - event_image / event_image_type
  /// - tickets_sold
  /// - updated_at
  Future<void> updateEvent({
    required String eventKey,
    required Map<String, dynamic> formData,
    required String base64Image,
    required int ticketsSold,
  }) async {
    final Map<String, dynamic> payload = {
      ...formData,
      'event_image': base64Image,
      'event_image_type': 'base64',
      'tickets_sold': ticketsSold,
      'updated_at': ServerValue.timestamp,
    };

    print('🟡 Updating database at: events/$eventKey');
    await _databaseRef.child('events').child(eventKey).update(payload);
    print('🟢 Event updated successfully!');
  }

  /// READ: Get upcoming events, with images, max [maxCount].
  ///
  /// Your DB fields:
  /// - event_date: "2025-12-31T00:00:00.000"
  /// - event_start_time: "18:09"
  /// - event_end_time: "18:09" (not strictly needed here)
  ///
  /// We combine event_date + event_start_time into a DateTime.
  /// Only events with that DateTime >= now will be returned.
  Future<List<Map<String, dynamic>>> getUpcomingEvents({
    int maxCount = 4,
  }) async {
    try {
      final DataSnapshot snapshot = await _databaseRef.child('events').get();

      if (!snapshot.exists || snapshot.value is! Map) {
        return [];
      }

      final Map<dynamic, dynamic> eventsMap =
          snapshot.value as Map<dynamic, dynamic>;

      final DateTime now = DateTime.now();
      final List<Map<String, dynamic>> upcoming = [];

      DateTime? _parseEventDateTime(Map<String, dynamic> data) {
        final String? dateStr = data['event_date']?.toString();
        if (dateStr == null || dateStr.isEmpty) return null;

        try {
          DateTime date = DateTime.parse(dateStr);

          final String? startTimeStr = data['event_start_time']?.toString();
          if (startTimeStr != null && startTimeStr.isNotEmpty) {
            final parts = startTimeStr.split(':');
            if (parts.length >= 2) {
              final int hour = int.tryParse(parts[0]) ?? 0;
              final int minute = int.tryParse(parts[1]) ?? 0;
              date = DateTime(date.year, date.month, date.day, hour, minute);
            }
          }

          return date;
        } catch (e) {
          print('Error parsing event_date/start_time: $e');
          return null;
        }
      }

      eventsMap.forEach((key, raw) {
        if (raw is Map) {
          // Normalize map
          final Map<String, dynamic> data = raw.map(
            (k, v) => MapEntry(k.toString(), v),
          );

          final DateTime? eventDateTime = _parseEventDateTime(data);

          // No date/time or already in the past -> not upcoming
          if (eventDateTime == null || eventDateTime.isBefore(now)) {
            return;
          }

          data['key'] = key.toString();
          data['_event_ts'] = eventDateTime.millisecondsSinceEpoch;
          upcoming.add(data);
        }
      });

      // Sort by computed DateTime ascending (nearest first)
      upcoming.sort((a, b) {
        final int at = (a['_event_ts'] ?? 0) as int;
        final int bt = (b['_event_ts'] ?? 0) as int;
        return at.compareTo(bt);
      });

      // Limit to maxCount
      if (upcoming.length > maxCount) {
        return upcoming.sublist(0, maxCount);
      }

      return upcoming;
    } catch (e) {
      print('Error loading upcoming events: $e');
      return [];
    }
  }

  /// 🔹 Private: increment admin -> summary -> events_created
  Future<void> _incrementAdminEventCountOnCreate() async {
    final DatabaseReference counterRef = _databaseRef
        .child('admins')
        .child('summary')
        .child('events_created');

    try {
      await counterRef.runTransaction((Object? currentData) {
        final dynamic current = currentData;

        int newValue;

        if (current is int) {
          newValue = current + 1;
        } else if (current is String) {
          final parsed = int.tryParse(current);
          newValue = (parsed ?? 0) + 1;
        } else {
          // null or unexpected type → start from 1
          newValue = 1;
        }

        return Transaction.success(newValue);
      });

      print('🟢 Incremented admin/summary/events_created');
    } catch (e) {
      print('❌ Error incrementing admin/summary/events_created: $e');
    }
  }
}
