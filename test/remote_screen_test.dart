import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv/core/remote/discovered_device.dart';
import 'package:remote_tv/core/remote/keys.dart';
import 'package:remote_tv/features/remote/domain/remote_state.dart';
import 'package:remote_tv/features/remote/presentation/remote_controller.dart';
import 'package:remote_tv/features/remote/presentation/remote_screen.dart';

class _FakeController extends RemoteController {
  @override
  RemoteState build() => const RemoteState(
        device: DiscoveredDevice(
          host: '10.0.0.5',
          platform: DevicePlatform.samsung,
          name: 'Living Room TV',
        ),
        capabilities: {
          RemoteKey.power,
          RemoteKey.home,
          RemoteKey.back,
          RemoteKey.up,
          RemoteKey.down,
          RemoteKey.left,
          RemoteKey.right,
          RemoteKey.ok,
          RemoteKey.volumeUp,
          RemoteKey.volumeDown,
          RemoteKey.mute,
          RemoteKey.playPause,
        },
      );
}

void main() {
  testWidgets('remote screen renders the connected device without errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [remoteControllerProvider.overrideWith(_FakeController.new)],
        child: const MaterialApp(home: RemoteScreen()),
      ),
    );

    expect(find.text('Living Room TV'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('123 opens the controls sheet with the number pad', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [remoteControllerProvider.overrideWith(_FakeController.new)],
        child: const MaterialApp(home: RemoteScreen()),
      ),
    );

    await tester.tap(find.text('123'));
    await tester.pumpAndSettle();

    expect(find.text('Channel'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
