import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import '../Component/find_ctrls.dart';

class BookSyncService extends GetxService {
  static const String FTP_HOST = 'v2001.coreserver.jp';
  static const int FTP_PORT = 21;
  static const String FTP_USER = 'zmongol@hiimor.com';
  static const String FTP_PASSWORD = 'Zm20251212';
  static const String FTP_PATH = '/Znom/js/';
  static const String FTP_IMAGE_PATH = '/Znom/images/';

  late Timer _syncTimer;
  bool _isSyncing = false;

  @override
  void onInit() {
    super.onInit();
    // Sync immediately on startup
    _syncBooks();
    // Then sync every hour
    _syncTimer = Timer.periodic(Duration(hours: 1), (_) {
      _syncBooks();
    });
  }

  @override
  void onClose() {
    _syncTimer.cancel();
    super.onClose();
  }

  Future<void> _syncBooks() async {
    if (_isSyncing) return;

    _isSyncing = true;
    try {
      print('Starting book sync...');

      // Get list of JSON files with their modification dates from FTP server
      Map<String, DateTime> ftpFiles = await _getFTPFileList();
      print('Found ${ftpFiles.length} files on FTP server');

      // Get local JSON files
      List<String> localFiles = await _getLocalFileList();
      print('Found ${localFiles.length} local files');

      bool hasChanges = false;

      // Download new files or update existing ones
      for (String fileName in ftpFiles.keys) {
        DateTime serverModified = ftpFiles[fileName]!;
        bool needsUpdate = false;

        if (!localFiles.contains(fileName)) {
          // New file - download it
          print('Downloading new file: $fileName');
          needsUpdate = true;
        } else {
          // Check if file was updated on server
          DateTime? localModified = await _getLocalFileModifiedDate(fileName);
          if (localModified == null || serverModified.isAfter(localModified)) {
            print(
                'Updating modified file: $fileName (server: $serverModified, local: $localModified)');
            needsUpdate = true;
          }
        }

        if (needsUpdate) {
          await _downloadBookFile(fileName);
          // Save server modified date to local file
          await _saveFileModifiedDate(fileName, serverModified);

          // Try to download corresponding image
          String imageName = fileName.replaceAll('.json', '.png');
          await _downloadImageFile(imageName);

          hasChanges = true;
        }
      }

      // Delete files that are no longer on server
      for (String localFileName in localFiles) {
        if (!ftpFiles.containsKey(localFileName)) {
          print('Deleting removed file: $localFileName');
          await _deleteLocalBookFile(localFileName);

          // Delete corresponding image
          String imageName = localFileName.replaceAll('.json', '.png');
          await _deleteLocalImageFile(imageName);

          hasChanges = true;
        }
      }

      // Reload books if there were any changes
      if (hasChanges) {
        print('Reloading books list...');
        final bookCtrl = FindCtrl.book;
        await bookCtrl.reloadBooks();
      }

      print('Book sync completed');
    } catch (e) {
      print('Error syncing books: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<Map<String, DateTime>> _getFTPFileList() async {
    Map<String, DateTime> files = {};
    FTPConnect ftpConnect = FTPConnect(
      FTP_HOST,
      port: FTP_PORT,
      user: FTP_USER,
      pass: FTP_PASSWORD,
    );

    try {
      await ftpConnect.connect();

      // Change to the directory first
      await ftpConnect.changeDirectory(FTP_PATH);

      // List files in the current directory
      var list = await ftpConnect.listDirectoryContent();

      for (var item in list) {
        if (item.name.endsWith('.json')) {
          // Store filename with modification date
          files[item.name] = item.modifyTime ?? DateTime.now();
        }
      }

      await ftpConnect.disconnect();
    } catch (e) {
      print('Error listing FTP files: $e');
    }

    return files;
  }

  Future<List<String>> _getLocalFileList() async {
    List<String> files = [];

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final booksDir = Directory('${appDir.path}/books');

      if (await booksDir.exists()) {
        final fileList = booksDir.listSync();
        for (var file in fileList) {
          if (file.path.endsWith('.json')) {
            files.add(file.path.split('/').last);
          }
        }
      } else {
        await booksDir.create(recursive: true);
      }
    } catch (e) {
      print('Error listing local files: $e');
    }

    return files;
  }

  Future<void> _downloadBookFile(String fileName) async {
    FTPConnect ftpConnect = FTPConnect(
      FTP_HOST,
      port: FTP_PORT,
      user: FTP_USER,
      pass: FTP_PASSWORD,
    );

    try {
      await ftpConnect.connect();

      final appDir = await getApplicationDocumentsDirectory();
      final booksDir = Directory('${appDir.path}/books');
      if (!await booksDir.exists()) {
        await booksDir.create(recursive: true);
      }

      final localPath = '${booksDir.path}/$fileName';

      // Download file
      await ftpConnect.downloadFile(
        FTP_PATH + fileName,
        File(localPath),
      );

      print('Downloaded: $fileName to $localPath');
      await ftpConnect.disconnect();
    } catch (e) {
      print('Error downloading file $fileName: $e');
    }
  }

  Future<void> _deleteLocalBookFile(String fileName) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final file = File('${appDir.path}/books/$fileName');

      if (await file.exists()) {
        await file.delete();
        print('Deleted local file: $fileName');
      }

      // Delete metadata file
      final metaFile = File('${appDir.path}/book_meta/$fileName.meta');
      if (await metaFile.exists()) {
        await metaFile.delete();
        print('Deleted metadata for: $fileName');
      }
    } catch (e) {
      print('Error deleting file $fileName: $e');
    }
  }

  Future<void> _downloadImageFile(String imageName) async {
    FTPConnect ftpConnect = FTPConnect(
      FTP_HOST,
      port: FTP_PORT,
      user: FTP_USER,
      pass: FTP_PASSWORD,
    );

    try {
      await ftpConnect.connect();

      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/book_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final localPath = '${imagesDir.path}/$imageName';

      // Download image file
      await ftpConnect.downloadFile(
        FTP_IMAGE_PATH + imageName,
        File(localPath),
      );

      print('Downloaded image: $imageName to $localPath');
      await ftpConnect.disconnect();
    } catch (e) {
      print('Image not found or error downloading $imageName: $e');
      // Image is optional, so we don't throw error
    }
  }

  Future<void> _deleteLocalImageFile(String imageName) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final file = File('${appDir.path}/book_images/$imageName');

      if (await file.exists()) {
        await file.delete();
        print('Deleted local image: $imageName');
      }
    } catch (e) {
      print('Error deleting image $imageName: $e');
    }
  }

  Future<DateTime?> _getLocalFileModifiedDate(String fileName) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final metaFile = File('${appDir.path}/book_meta/$fileName.meta');

      if (await metaFile.exists()) {
        String dateStr = await metaFile.readAsString();
        return DateTime.parse(dateStr);
      }
    } catch (e) {
      print('Error reading file meta: $e');
    }
    return null;
  }

  Future<void> _saveFileModifiedDate(
      String fileName, DateTime modifiedDate) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final metaDir = Directory('${appDir.path}/book_meta');
      if (!await metaDir.exists()) {
        await metaDir.create(recursive: true);
      }

      final metaFile = File('${metaDir.path}/$fileName.meta');
      await metaFile.writeAsString(modifiedDate.toIso8601String());
    } catch (e) {
      print('Error saving file meta: $e');
    }
  }

  Future<Map<String, dynamic>?> getLocalBookData(String fileName) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final file = File('${appDir.path}/books/$fileName');

      if (await file.exists()) {
        final contents = await file.readAsString();
        return jsonDecode(contents);
      }
    } catch (e) {
      print('Error reading local book file: $e');
    }
    return null;
  }

  Future<List<String>> getAvailableBookFiles() async {
    return await _getLocalFileList();
  }
}
