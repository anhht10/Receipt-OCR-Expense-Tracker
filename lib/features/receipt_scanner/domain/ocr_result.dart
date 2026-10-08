class OcrLine {
  final String text;
  final int lineIndex;

  const OcrLine({
    required this.text,
    required this.lineIndex,
  });
}

class OcrResult {
  final String rawText;
  final List<OcrLine> lines;

  const OcrResult({
    required this.rawText,
    required this.lines,
  });

  bool get isEmpty => rawText.trim().isEmpty;
}

