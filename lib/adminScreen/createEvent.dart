import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart'; // (kept in case you still need it later)
import 'package:image_picker/image_picker.dart';
import 'package:dnsc_events/colors/color.dart';

import 'package:dnsc_events/database/event_service.dart';

class Createevent extends StatefulWidget {
  const Createevent({super.key});

  @override
  State<Createevent> createState() => _CreateeventState();
}

class _CreateeventState extends State<Createevent> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  late final EventService _eventService;

  String? _selectedEventType;
  String? _selectedEventLocation;
  bool _isPressed = false;
  bool _hasImage = false;
  bool _formSubmitted = false;
  bool _isSubmitting = false;

  File? _imageFile;

  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _ticketPriceController = TextEditingController();
  final TextEditingController _ticketQuantityController =
      TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    _eventService = EventService(databaseRef: _databaseRef);
  }

  // ======================
  // Validation methods
  // ======================

  String? _validateRequired(String? value, String fieldName) {
    if (!_formSubmitted) return null;
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validateDropdown(String? value, String fieldName) {
    if (!_formSubmitted) return null;
    if (value == null) {
      return 'Please select $fieldName';
    }
    return null;
  }

  String? _validateDate(DateTime? value) {
    if (!_formSubmitted) return null;
    if (value == null) {
      return 'Please select date';
    }
    return null;
  }

  String? _validateTime(TimeOfDay? value, String fieldName) {
    if (!_formSubmitted) return null;
    if (value == null) {
      return 'Please select $fieldName';
    }
    return null;
  }

  String? _validateNumber(String? value, String fieldName) {
    if (!_formSubmitted) return null;
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    return null;
  }

  String? _validateTicketQuantity(String? value) {
    if (!_formSubmitted) return null;
    if (value == null || value.trim().isEmpty) {
      return 'Ticket quantity is required';
    }
    if (int.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    if (int.parse(value) <= 0) {
      return 'Quantity must be greater than 0';
    }
    return null;
  }

  // ======================
  // Pickers
  // ======================

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select Date';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Select Time';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // ======================
  // Image handling (UI)
  // ======================

  Future<void> _selectImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
          _hasImage = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo selected successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to select image: $e')));
    }
  }

  void _uploadPhoto() {
    _selectImage();
  }

  // ======================
  // Submit
  // ======================

  Future<void> _submitForm() async {
    setState(() {
      _formSubmitted = true;
    });

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (!_hasImage || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an event photo')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      print('🟡 Starting form submission process...');

      // 1. Compress + convert image to base64 via service
      print('🟡 Preparing Base64 image (with compression)...');
      final String? base64Image = await _eventService
          .prepareBase64ForEventImage(
            imageFile: _imageFile,
            existingBase64: null,
          );

      if (base64Image == null) {
        throw Exception('Failed to process image');
      }

      print('🟢 Base64 image ready. Length: ${base64Image.length}');

      // 2. Prepare form data (without image / id / timestamps)
      final Map<String, dynamic> formData = {
        'event_name': _eventNameController.text.trim(),
        'event_date': _selectedDate!.toIso8601String(),
        'event_start_time':
            '${_startTime!.hour}:${_startTime!.minute.toString().padLeft(2, '0')}',
        'event_end_time':
            '${_endTime!.hour}:${_endTime!.minute.toString().padLeft(2, '0')}',
        'event_type': _selectedEventType,
        'event_location': _selectedEventLocation,
        'event_description': _descriptionController.text.trim(),
        'ticket_price': double.parse(_ticketPriceController.text),
        'ticket_quantity': int.parse(_ticketQuantityController.text),
      };

      // 3. Call service to create event (handles event_id, tickets_sold, timestamps)
      final String eventKey = await _eventService.createEvent(
        formData: formData,
        base64Image: base64Image,
      );

      print('🟢 Event created with key: $eventKey');

      // 4. Success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '✅ Event created successfully!',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // 5. Reset form after success
      _resetForm();
    } catch (e, stackTrace) {
      print('❌ Error creating event: $e');
      print('❌ Stack trace: $stackTrace');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create event: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _resetForm() {
    setState(() {
      _eventNameController.clear();
      _descriptionController.clear();
      _ticketPriceController.clear();
      _ticketQuantityController.clear();
      _selectedEventType = null;
      _selectedEventLocation = null;
      _selectedDate = null;
      _startTime = null;
      _endTime = null;
      _imageFile = null;
      _hasImage = false;
      _formSubmitted = false;
      _isSubmitting = false;
    });
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _descriptionController.dispose();
    _ticketPriceController.dispose();
    _ticketQuantityController.dispose();
    super.dispose();
  }

  // ======================
  // UI BUILD (unchanged)
  // ======================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(
              top: 55,
              left: 15,
              right: 15,
              bottom: 15,
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Create ',
                          style: TextStyle(
                            fontFamily: 'InterExtra',
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Event',
                          style: TextStyle(
                            fontFamily: 'InterExtra',
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: CustomColor.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Photo Upload Section
                Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: _formSubmitted && !_hasImage
                        ? Border.all(color: Colors.red, width: 2)
                        : _hasImage
                        ? Border.all(color: Colors.green, width: 2)
                        : Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.error,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Failed to load',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image,
                                size: 50,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Upload Photo',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),

                const SizedBox(height: 10),

                GestureDetector(
                  onTapDown: (_) => setState(() => _isPressed = true),
                  onTapUp: (_) => setState(() => _isPressed = false),
                  onTapCancel: () => setState(() => _isPressed = false),
                  onTap: _uploadPhoto,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    height: 26,
                    width: 200,
                    decoration: BoxDecoration(
                      color: _isPressed
                          ? Colors.grey.shade500
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.image, size: 16),
                        SizedBox(width: 5),
                        Text('Upload Photo', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ),
                if (_formSubmitted && !_hasImage) ...[
                  const SizedBox(height: 5),
                  const Text(
                    'Photo is required',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],

                const SizedBox(height: 17),

                // Event Name
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Event Name',
                      style: TextStyle(
                        fontFamily: 'InterExtra',
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          width: 1,
                          color:
                              _validateRequired(
                                    _eventNameController.text,
                                    'Event name',
                                  ) !=
                                  null
                              ? Colors.red
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: TextFormField(
                          controller: _eventNameController,
                          textAlignVertical: TextAlignVertical.center,
                          validator: (value) =>
                              _validateRequired(value, 'Event name'),
                          decoration: InputDecoration(
                            hintText: "Enter Event Name",
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade400,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.only(bottom: 13),
                            errorStyle: const TextStyle(fontSize: 0, height: 0),
                          ),
                        ),
                      ),
                    ),
                    if (_validateRequired(
                          _eventNameController.text,
                          'Event name',
                        ) !=
                        null) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Event name is required',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 10),

                // Date and Time Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: const [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Date',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'InterExtra',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Start time',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'InterExtra',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'End time',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'InterExtra',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Date Picker
                        Expanded(
                          flex: 3,
                          child: GestureDetector(
                            onTap: () => _selectDate(context),
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  width: 1,
                                  color: _validateDate(_selectedDate) != null
                                      ? Colors.red
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_month,
                                      size: 14,
                                      color: _selectedDate != null
                                          ? Colors.black
                                          : Colors.grey.shade400,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      _selectedDate != null
                                          ? _formatDate(_selectedDate)
                                          : 'Select Date',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _selectedDate != null
                                            ? Colors.black
                                            : Colors.grey.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Start Time Picker
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () => _selectTime(context, true),
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  width: 1,
                                  color:
                                      _validateTime(_startTime, 'start time') !=
                                          null
                                      ? Colors.red
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_filled,
                                      size: 14,
                                      color: _startTime != null
                                          ? Colors.black
                                          : Colors.grey.shade400,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      _startTime != null
                                          ? _formatTime(_startTime)
                                          : 'Time',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _startTime != null
                                            ? Colors.black
                                            : Colors.grey.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // End Time Picker
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () => _selectTime(context, false),
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  width: 1,
                                  color:
                                      _validateTime(_endTime, 'end time') !=
                                          null
                                      ? Colors.red
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_filled,
                                      size: 14,
                                      color: _endTime != null
                                          ? Colors.black
                                          : Colors.grey.shade400,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      _endTime != null
                                          ? _formatTime(_endTime)
                                          : 'Time',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _endTime != null
                                            ? Colors.black
                                            : Colors.grey.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_validateDate(_selectedDate) != null ||
                        _validateTime(_startTime, 'start time') != null ||
                        _validateTime(_endTime, 'end time') != null) ...[
                      const SizedBox(height: 5),
                      const Text(
                        'Date and time are required',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 10),

                // Event Type
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Event Type',
                      style: TextStyle(
                        fontFamily: 'InterExtra',
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          width: 1,
                          color:
                              _validateDropdown(
                                    _selectedEventType,
                                    'event type',
                                  ) !=
                                  null
                              ? Colors.red
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: DropdownButtonFormField<String>(
                          value: _selectedEventType,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedEventType = newValue;
                            });
                          },
                          items:
                              <String>[
                                'Sports',
                                'Cultural',
                                'Musical',
                                'Theatre',
                              ].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                );
                              }).toList(),
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            errorStyle: TextStyle(fontSize: 0, height: 0),
                            contentPadding: EdgeInsets.only(bottom: 11),
                          ),
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey.shade400,
                          ),
                          hint: Text(
                            "Select Event",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          dropdownColor: Colors.white,
                          validator: (value) =>
                              _validateDropdown(value, 'event type'),
                        ),
                      ),
                    ),
                    if (_validateDropdown(_selectedEventType, 'event type') !=
                        null) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Please select event type',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 10),

                // Event Location
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Event Location',
                      style: TextStyle(
                        fontFamily: 'InterExtra',
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          width: 1,
                          color:
                              _validateDropdown(
                                    _selectedEventLocation,
                                    'event location',
                                  ) !=
                                  null
                              ? Colors.red
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: DropdownButtonFormField<String>(
                          value: _selectedEventLocation,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedEventLocation = newValue;
                            });
                          },
                          items:
                              <String>[
                                'DNSC Sports Complex',
                                'DNSC Gymnasium',
                                'DNSC Audio Room',
                                'DNSC NTED',
                              ].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                );
                              }).toList(),
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            errorStyle: TextStyle(fontSize: 0, height: 0),
                            contentPadding: EdgeInsets.only(bottom: 11),
                          ),
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey.shade400,
                          ),
                          hint: Text(
                            "Select Event Location",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          dropdownColor: Colors.white,
                          validator: (value) =>
                              _validateDropdown(value, 'event location'),
                        ),
                      ),
                    ),
                    if (_validateDropdown(
                          _selectedEventLocation,
                          'event location',
                        ) !=
                        null) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Please select event location',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 10),

                // Event Description
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Event Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'InterExtra',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 140,
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 1,
                          color:
                              _validateRequired(
                                    _descriptionController.text,
                                    'Event description',
                                  ) !=
                                  null
                              ? Colors.red
                              : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: TextFormField(
                          controller: _descriptionController,
                          textAlignVertical: TextAlignVertical.top,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          maxLength: 150,
                          validator: (value) =>
                              _validateRequired(value, 'Event description'),
                          decoration: InputDecoration(
                            hintText: "Description",
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade400,
                            ),
                            border: InputBorder.none,
                            counterText: "",
                            errorStyle: const TextStyle(fontSize: 0, height: 0),
                          ),
                        ),
                      ),
                    ),
                    if (_validateRequired(
                          _descriptionController.text,
                          'Event description',
                        ) !=
                        null) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Event description is required',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 10),

                // Ticket Price and Quantity
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Ticket Price',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'InterExtra',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Ticket Quantity',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'InterExtra',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Ticket Price
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    width: 1,
                                    color:
                                        _validateNumber(
                                              _ticketPriceController.text,
                                              'Ticket price',
                                            ) !=
                                            null
                                        ? Colors.red
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      const Text(
                                        '₱',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _ticketPriceController,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          textAlignVertical:
                                              TextAlignVertical.center,
                                          validator: (value) => _validateNumber(
                                            value,
                                            'Ticket price',
                                          ),
                                          decoration: InputDecoration(
                                            hintText: "0.00",
                                            hintStyle: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade400,
                                            ),
                                            border: InputBorder.none,
                                            contentPadding:
                                                const EdgeInsets.only(
                                                  bottom: 13,
                                                ),
                                            errorStyle: const TextStyle(
                                              fontSize: 0,
                                              height: 0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_validateNumber(
                                    _ticketPriceController.text,
                                    'Ticket price',
                                  ) !=
                                  null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _validateNumber(
                                    _ticketPriceController.text,
                                    'Ticket price',
                                  )!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Ticket Quantity
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    width: 1,
                                    color:
                                        _validateTicketQuantity(
                                              _ticketQuantityController.text,
                                            ) !=
                                            null
                                        ? Colors.red
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: TextFormField(
                                    controller: _ticketQuantityController,
                                    keyboardType: TextInputType.number,
                                    textAlignVertical: TextAlignVertical.center,
                                    validator: _validateTicketQuantity,
                                    decoration: InputDecoration(
                                      hintText: 'Quantity',
                                      hintStyle: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade400,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.only(
                                        bottom: 13,
                                      ),
                                      errorStyle: const TextStyle(
                                        fontSize: 0,
                                        height: 0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (_validateTicketQuantity(
                                    _ticketQuantityController.text,
                                  ) !=
                                  null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _validateTicketQuantity(
                                    _ticketQuantityController.text,
                                  )!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Create Event Button
                _isSubmitting
                    ? Container(
                        height: 48,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: CustomColor.primary.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: _submitForm,
                        child: Container(
                          height: 48,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: CustomColor.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'Create Event',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
