import 'package:flutter_test/flutter_test.dart';

/// Replicates the redirect logic from lib/core/router.dart as a pure function
/// for testability without GoRouter/Riverpod dependencies.
String? computeRedirect({
  required bool isAuthenticated,
  required bool? placementCompleted,
  required bool onboardingDone,
  required String matchedLocation,
}) {
  final isOnLogin = matchedLocation == '/login';
  final isOnPlacement = matchedLocation == '/placement';
  final isOnOnboarding = matchedLocation == '/onboarding';

  if (!isAuthenticated && !isOnLogin) return '/login';

  if (isAuthenticated && isOnLogin) {
    if (placementCompleted == false) return '/placement';
    if (placementCompleted == true && !onboardingDone) return '/onboarding';
    return '/';
  }

  if (isAuthenticated && placementCompleted == false && !isOnPlacement) {
    return '/placement';
  }

  if (isAuthenticated && placementCompleted == true && isOnPlacement) {
    return '/';
  }

  if (isAuthenticated &&
      placementCompleted == true &&
      !onboardingDone &&
      !isOnOnboarding) {
    return '/onboarding';
  }

  return null;
}

void main() {
  group('Router redirect logic', () {
    test('unauthenticated on / redirects to /login', () {
      expect(
        computeRedirect(
          isAuthenticated: false,
          placementCompleted: null,
          onboardingDone: false,
          matchedLocation: '/',
        ),
        '/login',
      );
    });

    test('unauthenticated on /login stays (null)', () {
      expect(
        computeRedirect(
          isAuthenticated: false,
          placementCompleted: null,
          onboardingDone: false,
          matchedLocation: '/login',
        ),
        null,
      );
    });

    test('authenticated on /login, placement not done → /placement', () {
      expect(
        computeRedirect(
          isAuthenticated: true,
          placementCompleted: false,
          onboardingDone: false,
          matchedLocation: '/login',
        ),
        '/placement',
      );
    });

    test('authenticated on /login, placement done, onboarding not done → /onboarding', () {
      expect(
        computeRedirect(
          isAuthenticated: true,
          placementCompleted: true,
          onboardingDone: false,
          matchedLocation: '/login',
        ),
        '/onboarding',
      );
    });

    test('authenticated on /login, all done → /', () {
      expect(
        computeRedirect(
          isAuthenticated: true,
          placementCompleted: true,
          onboardingDone: true,
          matchedLocation: '/login',
        ),
        '/',
      );
    });

    test('authenticated, placement not done, not on /placement → /placement', () {
      expect(
        computeRedirect(
          isAuthenticated: true,
          placementCompleted: false,
          onboardingDone: false,
          matchedLocation: '/',
        ),
        '/placement',
      );
    });

    test('authenticated, placement done, on /placement → /', () {
      expect(
        computeRedirect(
          isAuthenticated: true,
          placementCompleted: true,
          onboardingDone: true,
          matchedLocation: '/placement',
        ),
        '/',
      );
    });

    test('authenticated, placement done, onboarding not done, on / → /onboarding', () {
      expect(
        computeRedirect(
          isAuthenticated: true,
          placementCompleted: true,
          onboardingDone: false,
          matchedLocation: '/',
        ),
        '/onboarding',
      );
    });

    test('authenticated, all done, on / → null (no redirect)', () {
      expect(
        computeRedirect(
          isAuthenticated: true,
          placementCompleted: true,
          onboardingDone: true,
          matchedLocation: '/',
        ),
        null,
      );
    });
  });
}
