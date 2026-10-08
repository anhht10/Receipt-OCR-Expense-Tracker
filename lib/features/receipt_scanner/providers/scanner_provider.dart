import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/providers/database_providers.dart';
import 'scanner_state.dart';

final scannerStateProvider = StateNotifierProvider.autoDispose<ScannerNotifier, ScannerState>((ref) {
  final ocrService = ref.watch(ocrServiceProvider);
  final parser = ref.watch(receiptParserProvider);
  return ScannerNotifier(ocrService, parser);
});

class ScannerNotifier extends StateNotifier<ScannerState> {
  final dynamic _ocrService;
  final dynamic _parser;
  final ImagePicker _picker = ImagePicker();

  ScannerNotifier(this._ocrService, this._parser) : super(const ScannerState());

  Future<bool> pickAndProcessImage(ImageSource source) async {
    try {
      state = state.copyWith(status: ScannerStatus.capturing);

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        // User cancelled picking
        state = state.copyWith(status: ScannerStatus.idle);
        return false;
      }

      final file = File(pickedFile.path);
      if (!await file.exists()) {
        state = state.copyWith(
          status: ScannerStatus.error,
          errorMessage: 'Tệp hình ảnh không tồn tại. Vui lòng thử lại.',
        );
        return false;
      }

      state = state.copyWith(
        status: ScannerStatus.runningOcr,
        selectedImage: file,
      );

      // Perform OCR
      final ocrResult = await _ocrService.processImage(file);

      // Parse OCR result
      final parsed = _parser.parse(ocrResult.rawText);

      state = state.copyWith(
        status: ScannerStatus.success,
        selectedImage: file,
        rawOcrText: ocrResult.rawText,
        parsedReceipt: parsed,
      );
      return true;
    } catch (e, stack) {
      debugPrint('Scanner error: $e\n$stack');
      state = state.copyWith(
        status: ScannerStatus.error,
        errorMessage: 'Lỗi khi nhận diện hóa đơn: ${e.toString().replaceAll('Exception: ', '')}',
      );
      return false;
    }
  }

  void reset() {
    state = const ScannerState();
  }
}

