import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_constants.dart';

class ReceiptImageService {
  /// Save an image file to app's local document directory under `receipts/receipt_<id>.jpg`
  /// Returns the persistent local absolute path of the saved image.
  Future<String> saveReceiptImage(File sourceFile, String receiptId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory(p.join(appDir.path, AppConstants.receiptsDirectoryName));

      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }

      final extension = p.extension(sourceFile.path).isNotEmpty
          ? p.extension(sourceFile.path)
          : '.jpg';
      final targetPath = p.join(receiptsDir.path, 'receipt_$receiptId$extension');

      // Copy source file to permanent storage
      final savedFile = await sourceFile.copy(targetPath);
      return savedFile.path;
    } catch (e, stack) {
      debugPrint('Error saving receipt image: $e\n$stack');
      // If saving fails, fallback to original path if it exists
      return sourceFile.path;
    }
  }

  /// Safely deletes the image file from storage
  Future<bool> deleteReceiptImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Safe warning: Could not delete receipt image file at $imagePath: $e');
      return false;
    }
  }
}

