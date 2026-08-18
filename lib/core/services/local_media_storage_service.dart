import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

/// WhatsApp-style local media storage service for saving, caching, and sharing
/// media locally without requiring paid cloud storage buckets.
class LocalMediaStorageService {
  static LocalMediaStorageService? _instance;
  static LocalMediaStorageService get instance => _instance ??= LocalMediaStorageService._();

  LocalMediaStorageService._();

  Directory? _mediaDir;

  /// Initializes the local media directory (e.g., AppDocuments/Hubble/Media/Images)
  Future<Directory> get mediaDirectory async {
    if (_mediaDir != null && await _mediaDir!.exists()) {
      return _mediaDir!;
    }
    final appDocDir = await getApplicationDocumentsDirectory();
    final hubbleMediaDir = Directory('${appDocDir.path}/Hubble/Media/Images');
    if (!await hubbleMediaDir.exists()) {
      await hubbleMediaDir.create(recursive: true);
    }
    _mediaDir = hubbleMediaDir;
    return _mediaDir!;
  }

  /// Saves a Base64 encoded image string locally to disk (WhatsApp style caching)
  /// Returns the absolute local File path (`file:///...`)
  Future<File?> saveBase64ToLocalMedia(String base64Data, {String? filename}) async {
    try {
      final cleanBase64 = base64Data.contains(',') ? base64Data.split(',').last : base64Data;
      final bytes = base64Decode(cleanBase64);

      final dir = await mediaDirectory;
      final name = filename ?? '${md5.convert(utf8.encode(cleanBase64)).toString()}.jpg';
      final file = File('${dir.path}/$name');

      if (!await file.exists()) {
        await file.writeAsBytes(bytes);
      }
      return file;
    } catch (e) {
      debugPrint('Error saving base64 to local media storage: $e');
      return null;
    }
  }

  /// Checks if a file exists locally by filename or hash
  Future<File?> getLocalMediaFile(String filenameOrHash) async {
    try {
      final dir = await mediaDirectory;
      final file = File('${dir.path}/$filenameOrHash');
      if (await file.exists()) {
        return file;
      }
    } catch (e) {
      debugPrint('Error checking local media file: $e');
    }
    return null;
  }

  /// Cleans up old cache items if storage threshold is reached
  Future<void> clearMediaCache() async {
    try {
      final dir = await mediaDirectory;
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create(recursive: true);
      }
    } catch (e) {
      debugPrint('Error clearing local media cache: $e');
    }
  }
}
