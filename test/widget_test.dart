import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv/core/remote/remote_store.dart';
import 'package:remote_tv/features/discovery/domain/discovery_state.dart';
import 'package:remote_tv/features/discovery/presentation/discovery_controller.dart';
import 'package:remote_tv/features/discovery/presentation/discovery_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeDiscovery extends DiscoveryController {
  @override
  DiscoveryState build() => const DiscoveryState();

  @override
  Future<void> scan() async {}
}

Future<void> _pumpDiscovery(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        discoveryControllerProvider.overrideWith(_FakeDiscovery.new),
      ],
      child: const MaterialApp(home: DiscoveryScreen()),
    ),
  );
}

void main() {
  testWidgets('connection screen shows the title and refresh', (
    tester,
  ) async {
    await _pumpDiscovery(tester);

    expect(find.text('Connect your TV'), findsOneWidget);
    expect(find.text('Refresh'), findsOneWidget);
  });

  testWidgets('add-by-IP sheet opens from the bottom link', (tester) async {
    await _pumpDiscovery(tester);

    await tester.tap(find.text('Add TV by IP'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
  });
}
