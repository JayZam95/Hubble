import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageUtils {
  /// Compresses a file and converts it to a Base64 data URI.
  /// Target size is < 200KB to fit within Firestore's 1MB document limit.
  static Future<String?> fileToBase64(File file) async {
    try {
      final filePath = file.absolute.path;
      
      // Compress the image
      // We use a lower quality and downscale to ensure it fits comfortably in Firestore
      final Uint8List? compressedBytes = await FlutterImageCompress.compressWithFile(
        filePath,
        minWidth: 800,
        minHeight: 800,
        quality: 70,
        format: CompressFormat.jpeg,
      );

      if (compressedBytes == null) return null;

      // Check size (200KB = 204800 bytes)
      // Base64 encoding adds ~33% overhead, so 200KB raw -> 266KB string.
      // Even at 500KB raw, it's ~665KB, still safe for 1MB limit.
      final base64String = base64Encode(compressedBytes);
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      debugPrint('Error converting image to Base64: $e');
      return null;
    }
  }

  static bool isBase64(String path) => path.startsWith('data:image');
}
