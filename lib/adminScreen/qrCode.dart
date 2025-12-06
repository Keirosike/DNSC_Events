import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:dnsc_events/colors/color.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRTicketScanner extends StatefulWidget {
  final String eventId; // event we are checking in for (as String)

  const QRTicketScanner({super.key, required this.eventId});

  @override
  State<QRTicketScanner> createState() => _QRTicketScannerState();
}

class _QRTicketScannerState extends State<QRTicketScanner> {
  bool _isScanning = true; // true = ready, false = processing
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final MobileScannerController _cameraController = MobileScannerController();

  // 🔹 Called when a QR is scanned from the camera
  Future<void> _onQrScanned(String rawValue) async {
    print('🔍 QR scanned rawValue = "$rawValue"');

    setState(() {
      _isScanning = false; // pause scanning while validating
    });

    try {
      final bool isValid = await _validateTicket(rawValue);
      _showResultSnackbar(isValid);
    } catch (e, st) {
      print('❌ Error validating ticket: $e');
      print(st);
      _showResultSnackbar(false);
    } finally {
      // Auto reset after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _resetScanner();
      });
    }
  }

  /// 🔍 Validate QR data against Firebase
  ///
  /// Supports TWO formats:
  /// 1) JSON: {"ticket_id":"...","event_id":4,...}
  /// 2) Plain: "<eventId>|<ticketId>"
  Future<bool> _validateTicket(String rawValue) async {
    String scannedEventId = '';
    String ticketId = '';

    // 1️⃣ Try JSON decode first (your current QR format)
    try {
      final decoded = jsonDecode(rawValue);

      if (decoded is Map<String, dynamic>) {
        scannedEventId = decoded['event_id']?.toString().trim() ?? '';
        ticketId = decoded['ticket_id']?.toString().trim() ?? '';

        print(
          '🧩 Parsed JSON QR -> event_id="$scannedEventId", ticket_id="$ticketId"',
        );
      } else {
        print('⚠️ Decoded JSON is not a Map, got: $decoded');
      }
    } catch (e) {
      print('⚠️ rawValue is not JSON: $e');
    }

    // 2️⃣ If JSON parsing failed or fields missing, fallback to "<eventId>|<ticketId>"
    if (scannedEventId.isEmpty || ticketId.isEmpty) {
      final parts = rawValue.split('|');
      print('🧩 Fallback split parts = $parts');

      if (parts.length != 2) {
        print('⚠️ Invalid QR format (expected JSON or "<eventId>|<ticketId>")');
        return false;
      }

      scannedEventId = parts[0].trim();
      ticketId = parts[1].trim();
    }

    print(
      '🔎 scannedEventId="$scannedEventId" | currentEventId="${widget.eventId}" | ticketId="$ticketId"',
    );

    // 3️⃣ Check event matches current event
    if (scannedEventId != widget.eventId.trim()) {
      print(
        '⚠️ Ticket is for another event. scanned: "$scannedEventId", current: "${widget.eventId}"',
      );
      return false;
    }

    // 4️⃣ Look up ticket directly by KEY in /ticket_purchase/{ticketId}
    final txSnapshot = await _db.child('ticket_purchase').child(ticketId).get();

    print('📡 txSnapshot.exists = ${txSnapshot.exists}');
    if (txSnapshot.exists) {
      print('📦 txSnapshot.value = ${txSnapshot.value}');
    }

    if (!txSnapshot.exists) {
      print('⚠️ No ticket_purchase found for ticketId (key): $ticketId');
      return false;
    }

    final txDataRaw = txSnapshot.value;
    if (txDataRaw is! Map) {
      print('⚠️ ticket_purchase data is not a Map. Got: $txDataRaw');
      return false;
    }

    final Map<dynamic, dynamic> txData = txDataRaw;

    final String txEventId = txData['event_id']?.toString().trim() ?? '';
    final String paymentStatusRaw = txData['payment_status']?.toString() ?? '';
    final String paymentStatus = paymentStatusRaw.toLowerCase().trim();
    final String orderStatusRaw = txData['order_status']?.toString() ?? '';
    final String orderStatus = orderStatusRaw.toLowerCase().trim();

    print(
      '🧾 From DB -> event_id="$txEventId", payment_status="$paymentStatusRaw", order_status="$orderStatusRaw"',
    );

    // 5️⃣ Double-check event again from record
    if (txEventId != widget.eventId.trim()) {
      print(
        '⚠️ DB event_id does not match current event. txEventId="$txEventId" current="${widget.eventId}"',
      );
      return false;
    }

    // 6️⃣ Check payment/order status
    // 👉 Adjust this rule as you like:
    // For now: require payment_status == "paid"
    if (paymentStatus != 'paid') {
      print(
        '⚠️ Ticket not in paid status (found payment_status="$paymentStatusRaw")',
      );
      return false;
    }

    // (Optional) Also enforce order_status == "confirmed"
    // if (orderStatus != 'confirmed') {
    //   print('⚠️ Order is not confirmed (order_status="$orderStatusRaw")');
    //   return false;
    // }

    // OPTIONAL: mark as checked_in once used
    // await txSnapshot.ref.child('checked_in').set(true);

    print('✅ Ticket is VALID');
    return true;
  }

  void _showResultSnackbar(bool isValid) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isValid ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isValid ? 'VALID TICKET' : 'INVALID TICKET',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isValid
                      ? 'Ticket verified successfully'
                      : 'Ticket verification failed',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: isValid ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'X',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            _resetScanner();
          },
        ),
      ),
    );
  }

  void _resetScanner() {
    setState(() {
      _isScanning = true; // allow scanning again
    });
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ticket Scanner',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.black),
            onPressed: () async {
              await _cameraController.toggleTorch();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Scanner View
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Camera scanner
                MobileScanner(
                  controller: _cameraController,
                  onDetect: (capture) {
                    // Only handle if we are in scanning state
                    if (!_isScanning) return;

                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isEmpty) return;

                    final String? raw = barcodes.first.rawValue;
                    if (raw == null || raw.isEmpty) return;

                    _onQrScanned(raw);
                  },
                ),

                // Custom overlay (frame + text)
                _buildScannerContent(),
              ],
            ),
          ),

          // Bottom info area
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isScanning
                      ? 'Point the camera at the ticket QR code'
                      : 'Validating ticket...',
                  style: TextStyle(
                    color: _isScanning ? Colors.grey[700] : Colors.grey[500],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                if (!_isScanning)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Scanner Frame Overlay
        Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            border: Border.all(color: CustomColor.primary, width: 3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              // Top-left corner
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: CustomColor.primary, width: 5),
                      left: BorderSide(color: CustomColor.primary, width: 5),
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                    ),
                  ),
                ),
              ),
              // Top-right corner
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: CustomColor.primary, width: 5),
                      right: BorderSide(color: CustomColor.primary, width: 5),
                    ),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                    ),
                  ),
                ),
              ),
              // Bottom-left corner
              Positioned(
                bottom: 0,
                left: 0,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: CustomColor.primary, width: 5),
                      left: BorderSide(color: CustomColor.primary, width: 5),
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
              ),
              // Bottom-right corner
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: CustomColor.primary, width: 5),
                      right: BorderSide(color: CustomColor.primary, width: 5),
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                ),
              ),

              // Scanning line
              if (_isScanning)
                Positioned(
                  top: 3,
                  left: 3,
                  right: 3,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          CustomColor.primary.withOpacity(0),
                          CustomColor.primary,
                          CustomColor.primary.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 40),

        Icon(
          Icons.qr_code_scanner,
          size: 80,
          color: CustomColor.primary.withOpacity(_isScanning ? 0.7 : 0.3),
        ),

        const SizedBox(height: 20),

        Column(
          children: [
            Text(
              _isScanning ? 'Position QR code within frame' : 'Processing...',
              style: TextStyle(
                color: _isScanning ? Colors.grey[700] : Colors.grey[500],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            if (_isScanning)
              Text(
                'Ready to scan',
                style: TextStyle(
                  color: CustomColor.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
