import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../domain/ocr_result.dart';

abstract class IReceiptOcrService {
  Future<OcrResult> processImage(File imageFile);
  Future<void> dispose();
}

class ReceiptOcrService implements IReceiptOcrService {
  TextRecognizer? _recognizer;

  TextRecognizer _getRecognizer() {
    return _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
  }

  @override
  Future<OcrResult> processImage(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        throw Exception('Ảnh hóa đơn không tồn tại tại đường dẫn: ${imageFile.path}');
      }

      final inputImage = InputImage.fromFile(imageFile);
      final recognizer = _getRecognizer();
      final RecognizedText recognizedText = await recognizer.processImage(inputImage);

      final List<OcrLine> lines = [];
      int index = 0;
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          final trimmed = line.text.trim();
          if (trimmed.isNotEmpty) {
            lines.add(OcrLine(text: trimmed, lineIndex: index++));
          }
        }
      }

      return OcrResult(
        rawText: recognizedText.text,
        lines: lines,
      );
    } catch (e, stack) {
      debugPrint('ML Kit OCR error: $e\n$stack');
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    await _recognizer?.close();
    _recognizer = null;
  }
}

