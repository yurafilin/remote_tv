import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv/core/remote/discovered_device.dart';
import 'package:remote_tv/core/remote/remote_store.dart';
import 'package:remote_tv/features/discovery/domain/discovery_state.dart';
import 'package:remote_tv/features/discovery/presentation/discovery_controller.dart';
import 'package:remote_tv/features/discovery/presentation/discovery_screen.dart';
import 'package:remote_tv/features/remote/presentation/remote_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeDiscovery extends DiscoveryController {
  @override
  DiscoveryState build() => const DiscoveryState();

  @override
  Future<void> scan() async {}
}

class _OneRokuDevice extends DiscoveryController {
  @override
  DiscoveryState build() => const DiscoveryState(
    devices: [
      DiscoveredDevice(
        host: '10.0.0.5',
        platform: DevicePlatform.roku,
        name: 'Living Room',
      ),
    ],
  );

  @override
  Future<void> scan() async {}
}

/// A remote whose connection never resolves, so the row stays in its
/// "connecting" state for the duration of the test.
class _PendingRemote extends RemoteController {
  @override
  Future<void> connect(DiscoveredDevice device) => Completer<void>().future;
}

Future<void> _pumpDiscovery(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        firstRunProvider.overrideWithValue(false),
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

  testWidgets('tapping a device swaps its chevron for a spinner', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          firstRunProvider.overrideWithValue(false),
          discoveryControllerProvider.overrideWith(_OneRokuDevice.new),
          remoteControllerProvider.overrideWith(_PendingRemote.new),
        ],
        child: const MaterialApp(home: DiscoveryScreen()),
      ),
    );

    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(find.byType(CupertinoActivityIndicator), findsNothing);

    await tester.tap(find.text('Living Room'));
    await tester.pump();

    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });
}
