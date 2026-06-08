import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv/core/remote/remote_store.dart';
import 'package:remote_tv/features/discovery/presentation/discovery_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpDiscovery(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: DiscoveryScreen()),
    ),
  );
}

void main() {
  testWidgets('discovery screen shows the scan action when idle', (
    tester,
  ) async {
    await _pumpDiscovery(tester);

    expect(find.text('Find your TV'), findsOneWidget);
    expect(find.text('Scan network'), findsOneWidget);
  });

  testWidgets('add-by-IP dialog opens from the app bar', (tester) async {
    await _pumpDiscovery(tester);

    await tester.tap(find.byTooltip('Add by IP'));
    await tester.pumpAndSettle();

    expect(find.text('Add TV by IP'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
