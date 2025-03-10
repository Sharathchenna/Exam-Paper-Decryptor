import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ZipService {
  /// Extracts a password-protected zip file and returns the path to the extracted directory
  Future<String> extractZipFile(String zipPath, String password) async {
    try {
      // Read the zip file
      final bytes = File(zipPath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes, password: password);

      // Create a unique directory name with date
      final tempDir = await getTemporaryDirectory();
      final dateStr = DateTime.now().toString().split(' ')[0];
      final extractDir = Directory(
        path.join(tempDir.path, 'decryption_$dateStr'),
      );

      // Create the directory if it doesn't exist
      if (!extractDir.existsSync()) {
        extractDir.createSync(recursive: true);
      }

      // Extract each file
      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          File(path.join(extractDir.path, filename))
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        }
      }

      return extractDir.path;
    } catch (e) {
      throw Exception('Failed to extract zip file: $e');
    }
  }

  /// Copies key files to the specified directory
  Future<void> copyKeysToDirectory(
    String sourceDir,
    String destinationPath,
  ) async {
    try {
      final keysDir = Directory(sourceDir);
      if (!keysDir.existsSync()) return;

      // Create destination directory if it doesn't exist
      final destDir = Directory(destinationPath);
      if (!destDir.existsSync()) {
        destDir.createSync(recursive: true);
      }

      // Copy all files from the keys directory
      await for (final entity in keysDir.list()) {
        if (entity is File) {
          final newPath = path.join(
            destinationPath,
            path.basename(entity.path),
          );
          await entity.copy(newPath);
        }
      }
    } catch (e) {
      throw Exception('Failed to copy key files: $e');
    }
  }
}
