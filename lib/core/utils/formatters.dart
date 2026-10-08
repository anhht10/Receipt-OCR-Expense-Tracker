import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  static final NumberFormat _vndFormatter = NumberFormat('#,###', 'vi_VN');

  /// Formats an integer VND amount (e.g., 125000 -> "125.000 ₫")
  static String format(int amount) {
    return _formatter.format(amount);
  }

  /// Formats without symbol (e.g., 125000 -> "125.000")
  static String formatWithoutSymbol(int amount) {
    return _vndFormatter.format(amount);
  }

  /// Parse a string representing currency into integer VND
  /// Handles formats like: "125,000", "125.000", "125000 VND", "125 000đ"
  static int? parse(String text) {
    final cleaned = text
        .replaceAll(RegExp(r'[^\d]'), '')
        .trim();
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned);
  }
}

class DateFormatter {
  static final DateFormat _displayFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _isoFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  /// Format DateTime to standard display format dd/MM/yyyy
  static String format(DateTime date) {
    return _displayFormat.format(date);
  }

  /// Format DateTime to ISO format yyyy-MM-dd
  static String formatIso(DateTime date) {
    return _isoFormat.format(date);
  }

  /// Format DateTime with time
  static String formatWithTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }

  /// Parse ISO yyyy-MM-dd or yyyy-MM-ddTHH:mm:ss
  static DateTime? parseIso(String isoString) {
    return DateTime.tryParse(isoString);
  }
}

