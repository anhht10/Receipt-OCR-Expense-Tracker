import 'dart:io';
import 'package:flutter/foundation.dart';
import '../domain/parsed_receipt.dart';

enum ScannerStatus { idle, capturing, runningOcr, success, error }

@immutable
class ScannerState {
  final ScannerStatus status;
  final File? selectedImage;
  final String? rawOcrText;
  final ParsedReceipt? parsedReceipt;
  final String? errorMessage;

  const ScannerState({
    this.status = ScannerStatus.idle,
    this.selectedImage,
    this.rawOcrText,
    this.parsedReceipt,
    this.errorMessage,
  });

  ScannerState copyWith({
    ScannerStatus? status,
    File? selectedImage,
    String? rawOcrText,
    ParsedReceipt? parsedReceipt,
    String? errorMessage,
  }) {
    return ScannerState(
      status: status ?? this.status,
      selectedImage: selectedImage ?? this.selectedImage,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      parsedReceipt: parsedReceipt ?? this.parsedReceipt,
      errorMessage: errorMessage,
    );
  }

  bool get isLoading =>
      status == ScannerStatus.capturing || status == ScannerStatus.runningOcr;
}

