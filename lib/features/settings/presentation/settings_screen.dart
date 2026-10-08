import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../receipts/providers/receipts_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeModeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt & Thông tin'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        children: [
          // Section: Giao diện
          _buildSectionHeader('GIAO DIỆN & CHỦ ĐỀ'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Chế độ hiển thị',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('Hệ thống'),
                        icon: Icon(Icons.settings_suggest_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Sáng'),
                        icon: Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Tối'),
                        icon: Icon(Icons.dark_mode_outlined),
                      ),
                    ],
                    selected: {currentTheme},
                    onSelectionChanged: (newSelection) {
                      ref.read(themeModeProvider.notifier).setThemeMode(newSelection.first);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Section: Tiện ích dữ liệu thử nghiệm
          _buildSectionHeader('TIỆN ÍCH DỮ LIỆU'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.post_add_outlined, color: Colors.blue),
                  title: const Text('Thêm dữ liệu mẫu thử nghiệm'),
                  subtitle: const Text('Tạo 3 hóa đơn chi tiêu mẫu để kiểm tra biểu đồ'),
                  onTap: () => _addSampleData(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: Ứng dụng & Quyền riêng tư
          _buildSectionHeader('THÔNG TIN & QUYỀN RIÊNG TƯ'),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.offline_pin_outlined, color: Colors.green),
                  title: Text('Xử lý 100% On-Device'),
                  subtitle: Text(
                    'Toàn bộ quá trình OCR (Google ML Kit) và dữ liệu hóa đơn (SQLite) chỉ lưu trên máy bạn, tuyệt đối không gửi lên server mạng.',
                  ),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.school_outlined, color: Colors.deepPurple),
                  title: Text('Ứng dụng SV & CLB VKU'),
                  subtitle: Text(
                    'Trường Đại học Công nghệ Thông tin và Truyền thông Việt - Hàn (VKU)',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Phiên bản'),
                  trailing: Text(
                    '1.0.0 (Production Ready)',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: Colors.grey,
        ),
      ),
    );
  }

  Future<void> _addSampleData(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(receiptListProvider.notifier);

    // Create a dummy image file in temp for sample receipts
    final tempDir = Directory.systemTemp;
    final dummyFile = File('${tempDir.path}/sample_receipt.jpg');
    if (!dummyFile.existsSync()) {
      dummyFile.writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46]);
    }

    final samples = [
      {
        'merchant': 'Căn tin VKU',
        'amount': 35000,
        'cat': 'food',
        'date': DateTime.now(),
        'ocr': 'CĂN TIN VKU\nCom trua sinh vien\nTONG CONG: 35.000 VND',
      },
      {
        'merchant': 'Tiệm In & Photo Thư Viện VKU',
        'amount': 50000,
        'cat': 'study',
        'date': DateTime.now().subtract(const Duration(days: 1)),
        'ocr': 'PHOTO & IN AN VKU\nIn tai lieu sinh hoat CLB\nTHANH TOAN: 50.000 d',
      },
      {
        'merchant': 'Highlands Coffee Ngũ Hành Sơn',
        'amount': 118000,
        'cat': 'entertainment',
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'ocr': 'HIGHLANDS COFFEE\n2 Phin sua da, 1 Freeze\nTOTAL: 118,000 VND',
      },
      {
        'merchant': 'Cửa hàng Thiết bị Điện Tử',
        'amount': 250000,
        'cat': 'equipment',
        'date': DateTime.now().subtract(const Duration(days: 3)),
        'ocr': 'CUA HANG LINH KIEN\nDay cap HDMI & Micro\nTONG TIEN: 250,000 VNĐ',
      },
    ];

    for (final s in samples) {
      await notifier.addReceipt(
        id: const Uuid().v4(),
        merchant: s['merchant'] as String,
        totalAmount: s['amount'] as int,
        date: s['date'] as DateTime,
        category: s['cat'] as String,
        imageFile: dummyFile,
        rawOcrText: s['ocr'] as String,
      );
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã thêm 4 hóa đơn mẫu thành công! Hãy xem biểu đồ ở Dashboard.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

