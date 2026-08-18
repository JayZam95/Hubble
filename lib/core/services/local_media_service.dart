import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// LocalMediaService manages local on-device file storage for chat media (images, audio, docs)
/// saving cloud storage costs while keeping media accessible offline.
class LocalMediaService {
  static LocalMediaService? _instance;
  LocalMediaService._();
  static LocalMediaService get instance => _instance ??= LocalMediaService._();

  Directory? _mediaDir;

  /// Ensures the local media directory exists
  Future<Directory> get mediaDirectory async {
    if (_mediaDir != null) return _mediaDir!;
    final appDocDir = await getApplicationDocumentsDirectory();
    final mediaFolder = Directory(p.join(appDocDir.path, 'hubble_media'));
    if (!await mediaFolder.exists()) {
      await mediaFolder.create(recursive: true);
    }
    _mediaDir = mediaFolder;
    return mediaFolder;
  }

  /// Save a file locally to the app's media directory
  Future<File> saveMediaFile(File sourceFile, {String? customFileName}) async {
    final mediaDir = await mediaDirectory;
    final fileName = customFileName ?? '${DateTime.now().millisecondsSinceEpoch}_${p.basename(sourceFile.path)}';
    final targetPath = p.join(mediaDir.path, fileName);
    return await sourceFile.copy(targetPath);
  }

  /// Save raw bytes locally to the app's media directory
  Future<File> saveMediaBytes(List<int> bytes, String fileName) async {
    final mediaDir = await mediaDirectory;
    final targetPath = p.join(mediaDir.path, fileName);
    final file = File(targetPath);
    return await file.writeAsBytes(bytes);
  }

  /// Get a local media file if it exists
  Future<File?> getLocalMediaFile(String fileName) async {
    final mediaDir = await mediaDirectory;
    final filePath = p.join(mediaDir.path, fileName);
    final file = File(filePath);
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  /// Get total size of local media files in bytes
  Future<int> getLocalMediaTotalSize() async {
    final mediaDir = await mediaDirectory;
    int totalBytes = 0;
    if (await mediaDir.exists()) {
      await for (final entity in mediaDir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          totalBytes += await entity.length();
        }
      }
    }
    return totalBytes;
  }

  /// List all local media files
  Future<List<File>> listLocalMediaFiles() async {
    final mediaDir = await mediaDirectory;
    final List<File> files = [];
    if (await mediaDir.exists()) {
      await for (final entity in mediaDir.list(recursive: false, followLinks: false)) {
        if (entity is File) {
          files.add(entity);
        }
      }
    }
    return files;
  }

  /// Delete a local file
  Future<bool> deleteLocalMediaFile(String fileName) async {
    final mediaDir = await mediaDirectory;
    final file = File(p.join(mediaDir.path, fileName));
    if (await file.exists()) {
      await file.delete();
      return true;
    }
    return false;
  }
}
