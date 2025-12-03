import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:sjlshs_chronos/features/logging/chronos_logger.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;

class GoogleDriveService {
  final Isar _isar;
  final FirebaseFirestore _firestore;
  final logger = getLogger();

  GoogleDriveService(this._isar, this._firestore);

  Stream<double> importPhotos() async* {
    try {
      // 1. Load service account credentials from the JSON file
      final serviceAccountJson = await rootBundle.loadString(
        'sjlshs-chronos-480102-1a16b0c21ee4.json',
      );
      final accountCredentials = ServiceAccountCredentials.fromJson(
        json.decode(serviceAccountJson),
      );

      // 2. Get folder ID from Firestore
      final folderDoc =
          await _firestore
              .collection('gdrive_pubfolder')
              .doc('gdrive_public_folder')
              .get();
      if (!folderDoc.exists) {
        throw Exception('Folder configuration not found in Firestore');
      }

      final folderId = folderDoc.data()?['images_public_link'];
      if (folderId == null || folderId.isEmpty) {
        throw Exception('Folder ID not found in Firestore');
      }

      // 3. Create authenticated client
      final scopes = [drive.DriveApi.driveReadonlyScope];
      final authClient = await clientViaServiceAccount(
        accountCredentials,
        scopes,
      );

      try {
        // 4. Initialize Drive API
        final driveApi = drive.DriveApi(authClient);

        // 5. List files in the folder
        final fileList = await driveApi.files.list(
          q: "'$folderId' in parents",
          $fields: 'files(id, name)',
          pageSize: 1000,
        );

        final files = fileList.files ?? [];
        final totalFiles = files.length;

        if (totalFiles == 0) {
          yield 1.0;
          return;
        }

        final prefs = await SharedPreferences.getInstance();

        final photosDir = prefs.getString('student_images_path');
        if (photosDir == null) {
          throw Exception('Student images path not found in SharedPreferences');
        }

        int processedFiles = 0;

        for (final file in files) {
          final fileId = file.id;
          final fileName = file.name;

          if (fileId == null || fileName == null) continue;

          // 6. Download file
          final media =
              await driveApi.files.get(
                    fileId,
                    downloadOptions: drive.DownloadOptions.fullMedia,
                  )
                  as drive.Media;

          final localPath = '$photosDir/$fileName';
          final localFile = File(localPath);
          final sink = localFile.openWrite();

          await for (final data in media.stream) {
            sink.add(data);
          }
          await sink.close();

          processedFiles++;
          yield processedFiles / totalFiles;
        }

      } finally {
        authClient.close();
      }
    } catch (e) {
      logger.e('Error importing photos: $e');
      throw Exception('Error importing photos: $e');
    }
  }
}
