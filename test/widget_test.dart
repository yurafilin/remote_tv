import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv/features/discovery/presentation/discovery_screen.dart';

void main() {
  testWidgets('discovery screen shows the scan action when idle', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: DiscoveryScreen()),
      ),
    );

    expect(find.text('Find your TV'), findsOneWidget);
    expect(find.text('Scan network'), findsOneWidget);
  });
}
