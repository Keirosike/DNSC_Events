import 'package:flutter/material.dart';
import 'package:dnsc_events/colors/color.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class Viewticket extends StatefulWidget {
  final Map<String, dynamic>? ticketData;
  final String? ticketId;

  const Viewticket({super.key, this.ticketData, this.ticketId});

  @override
  State<Viewticket> createState() => _ViewticketState();
}

class _ViewticketState extends State<Viewticket> {
  late Map<String, dynamic>? _ticketData;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isGeneratingPDF = false;

  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    if (widget.ticketData != null) {
      // Use provided ticket data
      _ticketData = widget.ticketData;
      _isLoading = false;
    } else if (widget.ticketId != null) {
      // Load ticket data from Firebase using ticket ID
      _loadTicketData();
    } else {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'No ticket data provided';
      });
    }
  }

  // Method to generate QR code image for PDF
  Future<Uint8List> _generateQRCodeImage(String data) async {
    try {
      // Generate QR code using the same library and parameters as the widget
      final qrPainter = QrPainter(
        data: data,
        version: QrVersions.auto,
        color: const Color(0xFF000000), // Black color
        emptyColor: const Color(0xFFFFFFFF), // White color
        gapless: true,
        embeddedImageStyle: null,
        embeddedImage: null,
      );

      // Generate image with the same dimensions (200x200)
      final uiImage = await qrPainter.toImage(200);

      // Convert to PNG bytes
      final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    } catch (e) {
      print('Error generating QR code for PDF: $e');
      // Fallback: generate a simple QR code
      return await _generateFallbackQRCode(data);
    }
  }

  // Fallback QR code generation
  Future<Uint8List> _generateFallbackQRCode(String data) async {
    try {
      final qrPainter = QrPainter(
        data: data,
        version: QrVersions.auto,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
        gapless: true,
      );

      final uiImage = await qrPainter.toImage(200);
      final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    } catch (e) {
      print('Error in fallback QR generation: $e');
      // Return empty bytes as last resort
      return Uint8List(0);
    }
  }

  // PDF generation method
  Future<Uint8List> _generatePDF() async {
    if (_ticketData == null) throw Exception('No ticket data');

    final pdf = pw.Document();

    final ticket = _ticketData!;
    final eventName = ticket['event_name'] ?? 'Unnamed Event';
    final userName = ticket['user_name'] ?? 'Guest User';
    final eventLocation = ticket['event_location'] ?? 'Location not specified';
    final eventDate = ticket['event_date'] ?? '';
    final eventTime = ticket['event_time'] ?? ticket['event_start_time'] ?? '';
    final ticketCode = ticket['ticket_code'] ?? 'N/A';
    final ticketId = ticket['ticket_id'] ?? 'N/A';

    // Generate QR code using the same data as in the widget
    final qrData = _generateQRData();
    final qrCodeBytes = await _generateQRCodeImage(qrData);

    // Load logo from assets
    final ByteData logoData = await rootBundle.load(
      'assets/image/dnscEvents.png',
    );
    final Uint8List logoBytes = logoData.buffer.asUint8List();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'DNSC EVENTS',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green800,
                        ),
                      ),
                      pw.Text(
                        'Official Event Ticket',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey,
                        ),
                      ),
                    ],
                  ),
                  pw.Image(pw.MemoryImage(logoBytes), width: 60, height: 60),
                ],
              ),

              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 20),

              // Ticket Title
              pw.Center(
                child: pw.Text(
                  'EVENT TICKET',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green800,
                  ),
                ),
              ),
              pw.SizedBox(height: 30),

              // Event Info
              _buildPDFRow('Event:', eventName),
              pw.SizedBox(height: 10),
              _buildPDFRow('Attendee:', userName),
              pw.SizedBox(height: 10),
              _buildPDFRow('Location:', eventLocation),
              pw.SizedBox(height: 10),
              _buildPDFRow('Date:', _formatDate(eventDate)),
              pw.SizedBox(height: 10),
              _buildPDFRow('Time:', _formatTime(eventTime)),
              pw.SizedBox(height: 10),
              _buildPDFRow('Ticket Code:', ticketCode),
              pw.SizedBox(height: 10),
              _buildPDFRow('Ticket ID:', ticketId),

              pw.SizedBox(height: 30),

              // QR Code Section (Matches the widget exactly)
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Scan This QR',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Your Ticket',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 10),

                    // QR Code Container (same style as widget)
                    pw.Container(
                      width: 200,
                      height: 200,
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        borderRadius: pw.BorderRadius.circular(12),
                        border: pw.Border.all(
                          color: PdfColors.grey300,
                          width: 2,
                        ),
                      ),
                      child: qrCodeBytes.isNotEmpty
                          ? pw.Center(
                              child: pw.Image(
                                pw.MemoryImage(qrCodeBytes),
                                width: 180,
                                height: 180,
                              ),
                            )
                          : pw.Center(
                              child: pw.Text(
                                'QR Code',
                                style: pw.TextStyle(
                                  fontSize: 16,
                                  color: PdfColors.grey,
                                ),
                              ),
                            ),
                    ),

                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Ticket Code: $ticketCode',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Decorative dots (matches widget)
              pw.Row(
                children: List.generate(8, (index) {
                  return pw.Expanded(
                    child: pw.Container(
                      height: 2,
                      margin: const pw.EdgeInsets.symmetric(horizontal: 10),
                      color: PdfColors.grey300,
                    ),
                  );
                }).toList(),
              ),

              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),

              // Footer
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'IMPORTANT:',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      '• Present this ticket at the event entrance',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      '• Keep this receipt for verification',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      '• Non-transferable and non-refundable',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),
              pw.Text(
                'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<void> _loadTicketData() async {
    if (widget.ticketId == null || widget.ticketId!.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'No ticket ID provided';
      });
      return;
    }

    try {
      final snapshot = await _databaseRef
          .child('ticket_purchase')
          .child(widget.ticketId!)
          .get();

      if (snapshot.exists) {
        final ticketData = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _ticketData = Map<String, dynamic>.from(ticketData);
          _ticketData!['ticket_id'] = widget.ticketId;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Ticket not found';
        });
      }
    } catch (e) {
      print('Error loading ticket data: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Error loading ticket data';
      });
    }
  }

  String _formatDate(dynamic date) {
    try {
      if (date is int) {
        // Handle timestamp
        final dateTime = DateTime.fromMillisecondsSinceEpoch(date);
        return DateFormat('MMM dd, yyyy').format(dateTime);
      } else if (date is String) {
        // Handle date string
        final dateTime = DateTime.parse(date);
        return DateFormat('MMM dd, yyyy').format(dateTime);
      }
      return 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatTime(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        String period = hour >= 12 ? 'PM' : 'AM';
        hour = hour % 12;
        hour = hour == 0 ? 12 : hour;
        return '$hour:${minute.toString().padLeft(2, '0')} $period';
      }
      return timeString;
    } catch (e) {
      return 'Invalid Time';
    }
  }

  String _generateQRData() {
    if (_ticketData == null) return 'NO_DATA';

    final qrData = {
      'ticket_id': _ticketData!['ticket_id'] ?? 'N/A',
      'ticket_code': _ticketData!['ticket_code'] ?? 'N/A',
      'event_id': _ticketData!['event_id'] ?? 'N/A',
      'user_id': _ticketData!['user_id'] ?? 'N/A',
      'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    return jsonEncode(qrData);
  }

  pw.Widget _buildPDFRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 80,
          child: pw.Text(
            label,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(child: pw.Text(value, style: pw.TextStyle(fontSize: 12))),
      ],
    );
  }

  // Download PDF function
  Future<void> _downloadPDF() async {
    if (_ticketData == null) return;

    setState(() {
      _isGeneratingPDF = true;
    });

    try {
      final pdfBytes = await _generatePDF();

      // Use layoutPdf for preview
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'DNSC_Ticket_${_ticketData!['ticket_code'] ?? 'ticket'}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ticket receipt generated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error generating PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isGeneratingPDF = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              child: _isLoading
                  ? _buildLoadingState()
                  : _hasError
                  ? _buildErrorState()
                  : _buildTicketContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: CustomColor.primary),
        SizedBox(height: 20),
        Text(
          'Loading ticket...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 60, color: Colors.red),
        SizedBox(height: 20),
        Text(
          'Error',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: CustomColor.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text('Close', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildTicketContent() {
    final ticket = _ticketData!;

    // Extract data with defaults
    final eventName = ticket['event_name'] ?? 'Unnamed Event';
    final userName = ticket['user_name'] ?? 'Guest User';
    final eventLocation = ticket['event_location'] ?? 'Location not specified';
    final eventDate = ticket['event_date'] ?? '';
    final eventTime = ticket['event_time'] ?? ticket['event_start_time'] ?? '';
    final ticketCode = ticket['ticket_code'] ?? 'N/A';

    return Column(
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

        // Download button with loading indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (_isGeneratingPDF)
              Container(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: CustomColor.primary,
                ),
              )
            else
              IconButton(
                onPressed: _downloadPDF,
                icon: Icon(
                  Icons.download,
                  color: CustomColor.primary,
                  size: 30,
                ),
                tooltip: 'Download PDF Receipt',
              ),
          ],
        ),

        // Ticket content
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Scan This QR',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              'Your Ticket',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            SizedBox(height: 10),

            // QR Code
            Container(
              height: 200,
              width: 200,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: QrImageView(
                data: _generateQRData(),
                version: QrVersions.auto,
                size: 180,
                backgroundColor: Colors.white,
              ),
            ),

            SizedBox(height: 5),
            Text(
              'Ticket Code: $ticketCode',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),

            SizedBox(height: 20),

            // Decorative dots
            Row(
              children: List.generate(8, (index) {
                return Expanded(
                  child: Container(
                    width: 25,
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(color: Colors.grey.shade300),
                  ),
                );
              }),
            ),

            SizedBox(height: 10),

            // Event Name
            Container(
              height: 60,
              alignment: Alignment.center,
              child: Text(
                eventName,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
            ),

            // Ticket Details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Name',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        child: AutoSizeText(
                          userName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          maxFontSize: 16,
                          minFontSize: 10,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      Text(
                        'Location',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        child: AutoSizeText(
                          eventLocation,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          maxFontSize: 16,
                          minFontSize: 10,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 20),

                // Right Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      Text(
                        _formatDate(eventDate),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        'Time',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      Text(
                        _formatTime(eventTime),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
