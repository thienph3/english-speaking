import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/placement/repositories/placement_repository.dart';

/// Root widget cho ứng dụng SpeakEng.
class SpeakEngApp extends ConsumerWidget {
  const SpeakEngApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Khi auth state thay đổi → check placement status
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated) {
        _checkPlacement(ref);
      }
    });

    return MaterialApp.router(
      title: 'SpeakEng',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          surface: AppColors.surface,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
    );
  }

  /// Kiểm tra trạng thái placement khi user đăng nhập.
  Future<void> _checkPlacement(WidgetRef ref) async {
    try {
      final repo = ref.read(placementRepositoryProvider);
      final completed = await repo.hasCompletedPlacement();
      ref.read(placementCompletedProvider.notifier).state = completed;
    } on Exception {
      // Nếu lỗi, mặc định cho phép vào app
      ref.read(placementCompletedProvider.notifier).state = true;
    }
  }
}
