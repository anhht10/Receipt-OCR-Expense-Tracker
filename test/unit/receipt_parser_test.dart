import 'package:flutter_test/flutter_test.dart';
import 'package:vku_receipt_scanner/features/receipt_scanner/domain/receipt_parser.dart';

void main() {
  late ReceiptParser parser;

  setUp(() {
    parser = ReceiptParser();
  });

  group('ReceiptParser Tests', () {
    // 1. Total extraction
    test('1. Total extraction with standard TOTAL keyword', () {
      const ocr = '''
      THE COFFEE HOUSE
      123 Nguyen Tat Thanh, Da Nang
      TOTAL: 45000
      Date: 08/10/2026
      ''';
      final result = parser.parse(ocr);
      expect(result.totalAmount, equals(45000));
    });

    // 2. Vietnamese total labels
    test('2. Vietnamese total labels (TỔNG CỘNG, TỔNG TIỀN, THANH TOÁN)', () {
      const ocr1 = '''
      CĂN TIN VKU
      Bàn số 5
      TỔNG CỘNG: 35.000
      ''';
      expect(parser.parse(ocr1).totalAmount, equals(35000));

      const ocr2 = '''
      QUÁN CƠM VIỆT HÀN
      TỔNG TIỀN: 70.000
      ''';
      expect(parser.parse(ocr2).totalAmount, equals(70000));

      const ocr3 = '''
      PHOTOCOPY SINH VIÊN
      CẦN THANH TOÁN: 120.000
      ''';
      expect(parser.parse(ocr3).totalAmount, equals(120000));
    });

    // 3. Comma amount format (e.g. 125,000)
    test('3. Comma amount format is normalized correctly', () {
      const ocr = '''
      HIGHLANDS COFFEE
      Phiếu tính tiền
      Tổng cộng: 125,000
      ''';
      final result = parser.parse(ocr);
      expect(result.totalAmount, equals(125000));
    });

    // 4. Dot amount format (e.g. 125.000)
    test('4. Dot amount format is normalized correctly', () {
      const ocr = '''
      TRÀ SỮA TOCOTOCO
      Thành tiền: 65.000
      ''';
      final result = parser.parse(ocr);
      expect(result.totalAmount, equals(65000));
    });

    // 5. VND suffix (e.g. 125,000 VND, 125000đ, 125.000 VNĐ)
    test('5. VND and đ suffix variations are parsed properly', () {
      const ocrVnd = '''
      TIỆM TẠP HÓA VKU
      THANH TOÁN: 85,000 VND
      ''';
      expect(parser.parse(ocrVnd).totalAmount, equals(85000));

      const ocrD = '''
      TIỆM TẠP HÓA VKU
      THANH TOÁN: 95.000đ
      ''';
      expect(parser.parse(ocrD).totalAmount, equals(95000));

      const ocrVndCap = '''
      TIỆM TẠP HÓA VKU
      THANH TOÁN: 150000 VNĐ
      ''';
      expect(parser.parse(ocrVndCap).totalAmount, equals(150000));
    });

    // 6. Date extraction
    test('6. Date extraction supports dd/MM/yyyy, dd-MM-yyyy, and yyyy-MM-dd', () {
      const ocrDmySlash = '''
      MINISTOP VIỆT NAM
      Ngày: 08/10/2026
      TOTAL: 30000
      ''';
      final res1 = parser.parse(ocrDmySlash);
      expect(res1.date, equals(DateTime(2026, 10, 8)));

      const ocrDmyDash = '''
      CIRCLE K
      Date: 15-05-2026 14:30
      TOTAL: 40000
      ''';
      final res2 = parser.parse(ocrDmyDash);
      expect(res2.date, equals(DateTime(2026, 5, 15)));

      const ocrYmd = '''
      GS25 CONVENIENCE
      2026-11-20
      TOTAL: 55000
      ''';
      final res3 = parser.parse(ocrYmd);
      expect(res3.date, equals(DateTime(2026, 11, 20)));
    });

    // 7. Merchant extraction
    test('7. Merchant extraction ignores receipt headers and extracts company name', () {
      const ocr = '''
      HÓA ĐƠN BÁN HÀNG
      COFFEE HOUSE VKU
      123 Tran Dai Nghia, Da Nang
      Ngày: 08/10/2026
      TOTAL: 60000
      ''';
      final res = parser.parse(ocr);
      expect(res.merchant, equals('COFFEE HOUSE VKU'));
    });

    // 8. Missing total
    test('8. Missing total returns null gracefully', () {
      const ocr = '''
      COFFEE HOUSE VKU
      123 Tran Dai Nghia
      Ngày: 08/10/2026
      Cam on quy khach
      ''';
      final res = parser.parse(ocr);
      expect(res.totalAmount, isNull);
    });

    // 9. Missing date
    test('9. Missing date returns null gracefully', () {
      const ocr = '''
      COFFEE HOUSE VKU
      TOTAL: 45000 VND
      ''';
      final res = parser.parse(ocr);
      expect(res.date, isNull);
      expect(res.totalAmount, equals(45000));
    });

    // 10. Multiple amount candidates - prioritizes line with TOTAL keyword over subtotal/item prices
    test('10. Multiple amount candidates prioritizes TOTAL line score', () {
      const ocr = '''
      CANTEEN VKU
      1. Com suon: 25,000 VND
      2. Canh chua: 10,000 VND
      3. Tra da: 5,000 VND
      TAM TINH: 40,000 VND
      GIAM GIA: 0 VND
      TONG CONG: 40,000 VND
      TIEN KHACH DUA: 50,000 VND
      TIEN THOI: 10,000 VND
      ''';
      final res = parser.parse(ocr);
      expect(res.totalAmount, equals(40000));
    });

    // Category suggestion test
    test('Suggests food category for coffee/canteen keywords', () {
      const ocr = '''
      CANTEEN VKU
      TOTAL: 30000
      ''';
      final res = parser.parse(ocr);
      expect(res.suggestedCategory, equals('food'));
    });
  });
}

