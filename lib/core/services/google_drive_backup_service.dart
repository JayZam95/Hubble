import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'local_media_service.dart';

/// Helper HTTP client to add Google Auth headers to Google API requests
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

/// GoogleDriveBackupService manages uploading & restoring local app backups to/from 
/// the user's hidden Google Drive App Data folder (drive.appdata scope), keeping 
/// developer costs at $0.
class GoogleDriveBackupService {
  static GoogleDriveBackupService? _instance;
  GoogleDriveBackupService._();
  static GoogleDriveBackupService get instance => _instance ??= GoogleDriveBackupService._();

  static const String backupFolderName = 'appDataFolder';

  /// Creates a Drive API instance using the authenticated user's Auth Headers
  drive.DriveApi _getDriveApi(Map<String, String> authHeaders) {
    final client = _GoogleAuthClient(authHeaders);
    return drive.DriveApi(client);
  }

  /// Uploads a local file to the user's hidden Google Drive App Data folder
  Future<String?> uploadFileToAppDataFolder({
    required Map<String, String> authHeaders,
    required File localFile,
    required String remoteFileName,
  }) async {
    try {
      final driveApi = _getDriveApi(authHeaders);

      // Check if a backup file with the same name already exists in appDataFolder
      final fileList = await driveApi.files.list(
        spaces: backupFolderName,
        q: "name = '$remoteFileName' and '$backupFolderName' in parents and trashed = false",
      );

      final media = drive.Media(
        localFile.openRead(),
        await localFile.length(),
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        // Update existing backup file
        final existingFileId = fileList.files!.first.id!;
        final updatedFile = await driveApi.files.update(
          drive.File(),
          existingFileId,
          uploadMedia: media,
        );
        debugPrint('Updated Google Drive backup file: ${updatedFile.id}');
        return updatedFile.id;
      } else {
        // Create new backup file in appDataFolder
        final driveFile = drive.File()
          ..name = remoteFileName
          ..parents = [backupFolderName];

        final createdFile = await driveApi.files.create(
          driveFile,
          uploadMedia: media,
        );
        debugPrint('Created Google Drive backup file: ${createdFile.id}');
        return createdFile.id;
      }
    } catch (e) {
      debugPrint('Google Drive Backup Error: $e');
      rethrow;
    }
  }

  /// Lists all files in the user's Google Drive App Data folder
  Future<List<drive.File>> listAppDataFolderFiles(Map<String, String> authHeaders) async {
    try {
      final driveApi = _getDriveApi(authHeaders);
      final fileList = await driveApi.files.list(
        spaces: backupFolderName,
        $fields: 'files(id, name, size, createdTime, modifiedTime)',
      );
      return fileList.files ?? [];
    } catch (e) {
      debugPrint('Google Drive List Error: $e');
      return [];
    }
  }

  /// Downloads a file from the user's Google Drive App Data folder to local device
  Future<File?> downloadFileFromAppDataFolder({
    required Map<String, String> authHeaders,
    required String remoteFileName,
    required String targetLocalFileName,
  }) async {
    try {
      final driveApi = _getDriveApi(authHeaders);
      final fileList = await driveApi.files.list(
        spaces: backupFolderName,
        q: "name = '$remoteFileName' and '$backupFolderName' in parents and trashed = false",
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        debugPrint('No backup file found with name: $remoteFileName');
        return null;
      }

      final fileId = fileList.files!.first.id!;
      final media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final List<int> dataBytes = [];
      await for (final data in media.stream) {
        dataBytes.addAll(data);
      }

      return await LocalMediaService.instance.saveMediaBytes(dataBytes, targetLocalFileName);
    } catch (e) {
      debugPrint('Google Drive Download Error: $e');
      rethrow;
    }
  }

  /// Deletes a file from the user's Google Drive App Data folder
  Future<bool> deleteAppDataFolderFile({
    required Map<String, String> authHeaders,
    required String remoteFileName,
  }) async {
    try {
      final driveApi = _getDriveApi(authHeaders);
      final fileList = await driveApi.files.list(
        spaces: backupFolderName,
        q: "name = '$remoteFileName' and '$backupFolderName' in parents and trashed = false",
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        final fileId = fileList.files!.first.id!;
        await driveApi.files.delete(fileId);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Google Drive Delete Error: $e');
      return false;
    }
  }
}
