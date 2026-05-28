import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

import 'package:speakeng/features/ai_services/screens/settings_screen.dart';
import 'package:speakeng/features/auth/providers/auth_provider.dart';
import 'package:speakeng/features/auth/screens/auth_screen.dart';
import 'package:speakeng/features/conversation/screens/conversation_screen.dart';
import 'package:speakeng/features/conversation/screens/feedback_screen.dart';
import 'package:speakeng/features/daily_flow/screens/daily_flow_screen.dart';
import 'package:speakeng/features/onboarding/screens/onboarding_screen.dart';
import 'package:speakeng/features/placement/screens/placement_screen.dart';
import 'package:speakeng/features/progress/screens/progress_screen.dart';
import 'package:speakeng/features/shadowing/screens/shadowing_screen.dart';

/// Provider kiểm tra trạng thái placement của user.
///
/// Trả về `true` nếu user đã hoàn thành placement, `false` nếu chưa.
/// Mặc định `null` khi đang loading.
final placementCompletedProvider = StateProvider<bool?>((ref) => null);

/// Provider kiểm tra trạng thái onboarding.
///
/// Trả về `true` nếu user đã xem onboarding, `false` nếu chưa.
final onboardingDoneProvider = StateProvider<bool>((ref) => false);

/// Provider cho GoRouter instance.
///
/// Redirect logic:
/// - Chưa login → /login
/// - Đã login, chưa placement → /placement
/// - Đã login, đã placement → / (daily flow)
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final placementCompleted = ref.watch(placementCompletedProvider);
  final onboardingDone = ref.watch(onboardingDoneProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authState is AuthAuthenticated;
      final isOnLogin = state.matchedLocation == '/login';
      final isOnPlacement = state.matchedLocation == '/placement';
      final isOnOnboarding = state.matchedLocation == '/onboarding';

      // Chưa đăng nhập → redirect về /login
      if (!isAuthenticated && !isOnLogin) {
        return '/login';
      }

      // Đã đăng nhập mà đang ở /login → kiểm tra placement
      if (isAuthenticated && isOnLogin) {
        if (placementCompleted == false) return '/placement';
        if (placementCompleted == true && !onboardingDone) {
          return '/onboarding';
        }
        return '/';
      }

      // Đã đăng nhập, chưa placement → redirect về /placement
      if (isAuthenticated && placementCompleted == false && !isOnPlacement) {
        return '/placement';
      }

      // Đã placement mà đang ở /placement → redirect về /
      if (isAuthenticated && placementCompleted == true && isOnPlacement) {
        return '/';
      }

      // Đã placement, chưa onboarding → redirect về /onboarding
      if (isAuthenticated &&
          placementCompleted == true &&
          !onboardingDone &&
          !isOnOnboarding) {
        return '/onboarding';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/placement',
        builder: (context, state) => const PlacementScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const DailyFlowScreen(),
      ),
      GoRoute(
        path: '/shadowing/:id',
        builder: (context, state) => ShadowingScreen(
          sentenceId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/conversation/:id',
        builder: (context, state) {
          final scenario = state.extra as dynamic;
          return ConversationScreen(scenario: scenario);
        },
      ),
      GoRoute(
        path: '/progress',
        builder: (context, state) => const ProgressScreen(),
      ),
      GoRoute(
        path: '/feedback',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return FeedbackScreen(
            feedback: extra?['feedback'],
            targetPhrases: extra?['targetPhrases'] ?? [],
            userTranscripts: extra?['userTranscripts'] ?? [],
            responseTimes: extra?['responseTimes'] ?? [],
            onDone: () => context.go('/'),
          );
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
