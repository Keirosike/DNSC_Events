import 'dart:io';
import 'dart:math';
import 'dart:convert';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Service that:
/// - Enforces a 5MB upper check
/// - Compresses images down to ~500KB
/// - Can convert files to Base64 if needed
class ImageCompressionService {
  /// ~5MB
  static const int maxUploadBytes = 5 * 1024 * 1024;

  /// target compressed size: ~500KB
  static const int targetBytes = 500 * 1024;

  /// minimum JPEG quality
  static const int minQuality = 30;

  /// Compress image until it hits [targetBytes] or [minQuality].
  Future<File> compressImageSmart(File file) async {
    int originalSize = await file.length();
    print(
      '📷 Original image size: ${formatBytes(originalSize)} (${file.path})',
    );

    if (originalSize > maxUploadBytes) {
      print(
        '⚠️ Image is larger than 5MB (${formatBytes(originalSize)}). Will compress aggressively.',
      );
    }

    if (originalSize <= targetBytes) {
      print('✅ Image already under target size. No compression needed.');
      return file;
    }

    int quality = 95;
    int pass = 0;

    int minWidth = 1920;
    int minHeight = 1080;

    File currentFile = file;
    int currentSize = originalSize;

    while (currentSize > targetBytes && quality >= minQuality) {
      pass++;
      print(
        '🔄 Compress pass #$pass | quality=$quality | minWidth=$minWidth | minHeight=$minHeight',
      );

      final List<int>? compressedBytes =
          await FlutterImageCompress.compressWithFile(
            currentFile.path,
            format: CompressFormat.jpeg,
            quality: quality,
            minWidth: minWidth,
            minHeight: minHeight,
          );

      if (compressedBytes == null) {
        print('❌ Compression returned null bytes. Stopping.');
        break;
      }

      final Directory tempDir = await getTemporaryDirectory();
      final String outPath = p.join(
        tempDir.path,
        'cmp_${DateTime.now().millisecondsSinceEpoch}_$quality.jpg',
      );

      final File outFile = File(outPath);
      await outFile.writeAsBytes(compressedBytes, flush: true);

      currentFile = outFile;
      currentSize = await currentFile.length();

      print(
        '📉 After pass #$pass: ${formatBytes(currentSize)} (quality=$quality)',
      );

      if (currentSize <= targetBytes) {
        print('✅ Reached target size: ${formatBytes(currentSize)}');
        break;
      }

      quality -= 10;
      minWidth = (minWidth * 0.9).floor();
      minHeight = (minHeight * 0.9).floor();
    }

    if (currentSize > maxUploadBytes) {
      print(
        '⚠️ Warning: compressed image still above 5MB (${formatBytes(currentSize)}).',
      );
    }

    print('🏁 Final compressed size: ${formatBytes(currentSize)}');
    return currentFile;
  }

  /// Optional helper to convert a file to Base64.
  Future<String> fileToBase64(File file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  /// Pretty formatting for logging.
  String formatBytes(int bytes, [int decimals = 2]) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (log(bytes) / log(1024)).floor();
    final size = (bytes / pow(1024, i));
    return '${size.toStringAsFixed(decimals)} ${suffixes[i]}';
  }
}
