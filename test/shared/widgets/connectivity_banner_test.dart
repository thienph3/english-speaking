import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakeng/shared/widgets/connectivity_banner.dart';

void main() {
  group('ConnectivityBanner', () {
    testWidgets('shows banner when offline', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ConnectivityBanner(isOffline: true),
        ),
      ));

      expect(find.text('Mất kết nối internet'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });

    testWidgets('hides when online', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ConnectivityBanner(isOffline: false),
        ),
      ));

      expect(find.text('Mất kết nối internet'), findsNothing);
    });

    testWidgets('shows custom message', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ConnectivityBanner(
            isOffline: true,
            message: 'Custom offline msg',
          ),
        ),
      ));

      expect(find.text('Custom offline msg'), findsOneWidget);
    });
  });
}
