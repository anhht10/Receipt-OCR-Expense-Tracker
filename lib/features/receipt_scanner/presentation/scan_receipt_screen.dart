import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/scanner_provider.dart';
import '../providers/scanner_state.dart';
import 'review_receipt_screen.dart';

class ScanReceiptScreen extends ConsumerWidget {
  const ScanReceiptScreen({super.key});

  Future<void> _handlePick(BuildContext context, WidgetRef ref, ImageSource source) async {
    final notifier = ref.read(scannerStateProvider.notifier);
    final success = await notifier.pickAndProcessImage(source);

    if (success && context.mounted) {
      final state = ref.read(scannerStateProvider);
      if (state.selectedImage != null) {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (ctx) => ReviewReceiptScreen(
              imageFile: state.selectedImage!,
              parsedReceipt: state.parsedReceipt,
              rawOcrText: state.rawOcrText,
            ),
          ),
        );

        if (result == true && context.mounted) {
          // If saved, reset scanner state
          notifier.reset();
        }
      }
    } else if (context.mounted) {
      final state = ref.read(scannerStateProvider);
      if (state.status == ScannerStatus.error && state.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scannerState = ref.watch(scannerStateProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét Hóa Đơn Chi Tiêu'),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero illustration / scanner icon card
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.12),
                          theme.colorScheme.primary.withValues(alpha: 0.04),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.document_scanner_rounded,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Nhận diện Hóa đơn bằng AI On-Device',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sử dụng Google ML Kit xử lý trực tiếp trên thiết bị (Offline 100%), không gửi dữ liệu ra máy chủ bên ngoài.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  ElevatedButton.icon(
                    onPressed: scannerState.isLoading
                        ? null
                        : () => _handlePick(context, ref, ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded, size: 22),
                    label: const Text('Chụp ảnh hóa đơn mới'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  OutlinedButton.icon(
                    onPressed: scannerState.isLoading
                        ? null
                        : () => _handlePick(context, ref, ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, size: 22),
                    label: const Text('Chọn ảnh từ thư viện'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Tips card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Mẹo để nhận diện chính xác nhất:',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildTipItem(
                            context,
                            'Giữ hóa đơn phẳng, đủ ánh sáng và không bị bóng che mờ.',
                          ),
                          _buildTipItem(
                            context,
                            'Đảm bảo thấy rõ dòng TỔNG CỘNG / THANH TOÁN và Tên quán.',
                          ),
                          _buildTipItem(
                            context,
                            'Bạn có thể dễ dàng kiểm tra và chỉnh sửa lại sau khi quét.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading overlay
          if (scannerState.isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.65),
              child: Center(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 28.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          scannerState.status == ScannerStatus.capturing
                              ? 'Đang chuẩn bị ảnh...'
                              : 'Google ML Kit đang nhận diện chữ...',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Xử lý trực tiếp trên thiết bị (Offline)',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

