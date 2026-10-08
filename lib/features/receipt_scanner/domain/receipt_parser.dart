import 'parsed_receipt.dart';

class ReceiptParser {
  /// Parses raw OCR text and/or lines to extract receipt details.
  ParsedReceipt parse(String rawText, [List<String>? providedLines]) {
    final lines = providedLines ??
        rawText
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();

    final merchant = extractMerchant(lines);
    final date = extractDate(rawText, lines);
    final totalAmount = extractTotalAmount(rawText, lines);
    final category = suggestCategory(merchant, rawText);

    double score = 0.0;
    if (merchant != null) score += 0.3;
    if (date != null) score += 0.3;
    if (totalAmount != null) score += 0.4;

    return ParsedReceipt(
      merchant: merchant,
      date: date,
      totalAmount: totalAmount,
      suggestedCategory: category,
      confidenceScore: score,
    );
  }

  /// Extracts the merchant name using heuristics
  String? extractMerchant(List<String> lines) {
    if (lines.isEmpty) return null;

    final ignoredHeaderWords = [
      'hoa don', 'hóa đơn', 'phieu thanh toan', 'phiếu thanh toán',
      'phieu tinh tien', 'phiếu tính tiền', 'receipt', 'bill', 'invoice',
      'order', 'ban so', 'bàn số', 'thu ngan', 'thu ngân', 'stt',
      'gio vao', 'giờ vào', 'gio ra', 'giờ ra', 'khach hang', 'khách hàng',
      'ngay', 'ngày', 'date', 'mst', 'ma so thue', 'mã số thuế',
      'tel', 'phone', 'hotline', 'dt:', 'đt:', 'sdt:', 'sđt:',
      'dia chi', 'địa chỉ', 'dc:', 'đc:', 'address', 'add:',
      'wifi', 'mat khau', 'mật khẩu', 'pass:', 'password',
    ];

    // Check first 5 lines
    final candidateCount = lines.length < 5 ? lines.length : 5;
    for (int i = 0; i < candidateCount; i++) {
      final line = lines[i].trim();
      final lower = line.toLowerCase();

      // Skip lines that are too short
      if (line.length < 3) continue;

      // Skip lines matching phone numbers or numbers only
      if (RegExp(r'^\+?[0-9\s\.\-\(\)]{6,}$').hasMatch(line)) continue;

      // Skip if contains common receipt metadata headers
      bool isIgnored = false;
      for (final ignored in ignoredHeaderWords) {
        if (lower.startsWith(ignored) || lower == ignored) {
          isIgnored = true;
          break;
        }
      }
      if (isIgnored) continue;

      // Skip if contains date
      if (RegExp(r'\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4}').hasMatch(line)) {
        continue;
      }

      // Found a valid candidate!
      // Strip leading symbols (e.g. *, -, #)
      final cleaned = line.replaceAll(RegExp(r'^[\*\-\#\:\s]+'), '').trim();
      if (cleaned.isNotEmpty && cleaned.length >= 3) {
        return cleaned;
      }
    }

    return null;
  }

  /// Extracts transaction date
  DateTime? extractDate(String rawText, List<String> lines) {
    // Regex for:
    // 1. dd/MM/yyyy or dd-MM-yyyy or dd.MM.yyyy
    // 2. yyyy-MM-dd or yyyy/MM/dd
    final dmyRegex = RegExp(r'\b(0?[1-9]|[12][0-9]|3[01])[\/\-\.](0?[1-9]|1[012])[\/\-\.](20\d\d|\d{2})\b');
    final ymdRegex = RegExp(r'\b(20\d\d)[\/\-\.](0?[1-9]|1[012])[\/\-\.](0?[1-9]|[12][0-9]|3[01])\b');

    // Priority 1: Check lines with keyword 'ngày', 'date', 'ngay'
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('ngay') || lower.contains('ngày') || lower.contains('date')) {
        final dmyMatch = dmyRegex.firstMatch(line);
        if (dmyMatch != null) {
          final parsed = _buildDateFromDmy(dmyMatch);
          if (parsed != null) return parsed;
        }
        final ymdMatch = ymdRegex.firstMatch(line);
        if (ymdMatch != null) {
          final parsed = _buildDateFromYmd(ymdMatch);
          if (parsed != null) return parsed;
        }
      }
    }

    // Priority 2: Check any line in the text
    final dmyMatches = dmyRegex.allMatches(rawText);
    for (final m in dmyMatches) {
      final parsed = _buildDateFromDmy(m);
      if (parsed != null) return parsed;
    }

    final ymdMatches = ymdRegex.allMatches(rawText);
    for (final m in ymdMatches) {
      final parsed = _buildDateFromYmd(m);
      if (parsed != null) return parsed;
    }

    return null;
  }

  DateTime? _buildDateFromDmy(Match m) {
    try {
      final day = int.parse(m.group(1)!);
      final month = int.parse(m.group(2)!);
      var year = int.parse(m.group(3)!);
      if (year < 100) {
        year += 2000;
      }
      if (day >= 1 && day <= 31 && month >= 1 && month <= 12 && year >= 2000 && year <= 2099) {
        return DateTime(year, month, day);
      }
    } catch (_) {}
    return null;
  }

  DateTime? _buildDateFromYmd(Match m) {
    try {
      final year = int.parse(m.group(1)!);
      final month = int.parse(m.group(2)!);
      final day = int.parse(m.group(3)!);
      if (day >= 1 && day <= 31 && month >= 1 && month <= 12 && year >= 2000 && year <= 2099) {
        return DateTime(year, month, day);
      }
    } catch (_) {}
    return null;
  }

  /// Extracts total amount in VND using priority-based scoring heuristics
  int? extractTotalAmount(String rawText, List<String> lines) {
    // Scoring definitions for keywords
    final priority1Keywords = [
      'tong cong', 'tổng cộng', 'total', 'total amount', 'can thanh toan', 'cần thanh toán',
      'tong tien', 'tổng tiền', 'tong thanh toan', 'tổng thanh toán', 'phai thanh toan', 'phải thanh toán'
    ];
    final priority2Keywords = [
      'thanh toan', 'thanh toán', 'thanh tien', 'thành tiền', 'tien mat', 'tiền mặt',
      'khach phai tra', 'khách phải trả', 'so tien', 'số tiền', 'amount', 'grand total'
    ];
    final priority3Keywords = [
      'tong', 'tổng', 'cong', 'cộng'
    ];

    int? bestAmount;
    int highestScore = -1;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = _normalizeVietnamese(line.toLowerCase());

      int lineBaseScore = 0;
      if (priority1Keywords.any((kw) => lower.contains(_normalizeVietnamese(kw)))) {
        lineBaseScore = 100;
      } else if (priority2Keywords.any((kw) => lower.contains(_normalizeVietnamese(kw)))) {
        lineBaseScore = 70;
      } else if (priority3Keywords.any((kw) => lower.contains(_normalizeVietnamese(kw)))) {
        lineBaseScore = 40;
      }

      if (lineBaseScore > 0) {
        // Try extracting amount from the same line
        final amountInLine = _findAmountInLine(line);
        if (amountInLine != null) {
          final score = lineBaseScore + (line.toLowerCase().contains('vnd') || line.contains('đ') ? 10 : 0);
          if (score > highestScore) {
            highestScore = score;
            bestAmount = amountInLine;
          }
        } else if (i + 1 < lines.length) {
          // If keyword is alone on line i, check line i + 1
          final nextLine = lines[i + 1];
          final amountInNextLine = _findAmountInLine(nextLine);
          if (amountInNextLine != null) {
            final score = lineBaseScore - 5;
            if (score > highestScore) {
              highestScore = score;
              bestAmount = amountInNextLine;
            }
          }
        }
      }
    }

    if (bestAmount != null) {
      return bestAmount;
    }

    // Fallback: look for lines ending in VND / đ or formatted numbers
    final fallbackCandidates = <int>[];
    for (final line in lines) {
      // If line contains currency marker
      if (RegExp(r'(vnd|vnđ|đ)', caseSensitive: false).hasMatch(line)) {
        final val = _findAmountInLine(line);
        if (val != null && val >= 1000) {
          fallbackCandidates.add(val);
        }
      }
    }

    if (fallbackCandidates.isNotEmpty) {
      // Return the largest candidate from those with explicit currency marker
      fallbackCandidates.sort();
      return fallbackCandidates.last;
    }

    return null;
  }

  /// Finds and parses the most likely amount from a single line
  int? _findAmountInLine(String line) {
    // Matches patterns like:
    // 125,000 | 125.000 | 125 000 | 125000
    // Optional trailing VND / đ / VNĐ
    final amountPattern = RegExp(
      r'(?:(?:\b|\:|\=)\s*)(\d{1,3}(?:[,\.\s]\d{3})+(?:\.\d{2})?|\d{4,9})(?:\s*(?:vnd|vnđ|đ|d))?',
      caseSensitive: false,
    );

    final matches = amountPattern.allMatches(line);
    int? candidate;

    for (final match in matches) {
      String rawNumber = match.group(1) ?? match.group(0)!;
      // Exclude strings that look like years: 2024, 2025, 2026, etc. if no separator
      if (rawNumber.length == 4 && (rawNumber.startsWith('20') || rawNumber.startsWith('19'))) {
        continue;
      }

      // If it contains decimal cents like .00, remove .00
      if (rawNumber.endsWith('.00') || rawNumber.endsWith(',00')) {
        rawNumber = rawNumber.substring(0, rawNumber.length - 3);
      }

      // Remove thousand separators (comma, dot, space)
      final clean = rawNumber.replaceAll(RegExp(r'[,\.\s]'), '');
      final parsed = int.tryParse(clean);
      if (parsed != null && parsed > 0) {
        // Prefer sensible receipt amounts (e.g. at least 1,000 VND)
        if (candidate == null || parsed >= candidate) {
          candidate = parsed;
        }
      }
    }

    return candidate;
  }

  /// Suggests category based on merchant name or raw receipt text
  String suggestCategory(String? merchant, String rawText) {
    final text = '${merchant ?? ''} $rawText'.toLowerCase();

    if (_hasAny(text, ['cafe', 'coffee', 'trà sữa', 'tra sua', 'quán', 'quan', 'cơm', 'com', 'phở', 'pho', 'bún', 'bun', 'bánh', 'banh', 'mì', 'mi', 'nước', 'nuoc', 'lẩu', 'lau', 'nướng', 'nuong', 'canteen', 'food', 'kfc', 'lotteria', 'highlands', 'phuc long', 'gà rán'])) {
      return 'food';
    }

    if (_hasAny(text, ['photo', 'in ấn', 'in an', 'photocopy', 'sách', 'sach', 'vở', 'vo', 'bút', 'but', 'giáo trình', 'giao trinh', 'văn phòng phẩm', 'van phong pham', 'thư viện', 'thu vien', 'study', 'tai lieu', 'tài liệu'])) {
      return 'study';
    }

    if (_hasAny(text, ['thiết bị', 'thiet bi', 'linh kiện', 'linh kien', 'dây điện', 'day dien', 'loa', 'micro', 'bảng', 'bang', 'kìm', 'kim', 'ốc vít', 'hardware', 'equipment', 'dụng cụ', 'dung cu', 'đèn', 'den'])) {
      return 'equipment';
    }

    if (_hasAny(text, ['xe bus', 'xe buýt', 'grab', 'xăng', 'xang', 'bãi giữ xe', 'giu xe', 'vé xe', 've xe', 'bike', 'taxi', 'be', 'gojek', 'petrol'])) {
      return 'transport';
    }

    if (_hasAny(text, ['sự kiện', 'su kien', 'liên hoan', 'lien hoan', 'karaoke', 'cinema', 'rạp', 'rap', 'phim', 'gala', 'teambuilding', 'event', 'party', 'vé xem', 've xem'])) {
      return 'entertainment';
    }

    return 'other';
  }

  bool _hasAny(String text, List<String> keywords) {
    final normalized = _normalizeVietnamese(text);
    return keywords.any((kw) => normalized.contains(_normalizeVietnamese(kw)));
  }

  /// Normalizes Vietnamese diacritics to basic Latin characters for robust keyword matching
  String _normalizeVietnamese(String input) {
    var str = input.toLowerCase();
    const withDiacritics = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const withoutDiacritics = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';

    for (int i = 0; i < withDiacritics.length; i++) {
      str = str.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }
    return str;
  }
}

