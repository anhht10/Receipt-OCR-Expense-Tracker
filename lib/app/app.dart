import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../features/settings/providers/theme_provider.dart';
import 'home_navigation_screen.dart';
import 'theme/app_theme.dart';

class VkuReceiptScannerApp extends ConsumerWidget {
  const VkuReceiptScannerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const HomeNavigationScreen(),
    );
  }
}

