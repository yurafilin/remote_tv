import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv/core/remote/app_launcher.dart';
import 'package:remote_tv/core/remote/discovered_device.dart';
import 'package:remote_tv/core/remote/keys.dart';
import 'package:remote_tv/features/remote/domain/remote_state.dart';
import 'package:remote_tv/features/remote/presentation/remote_controller.dart';
import 'package:remote_tv/features/remote/presentation/remote_screen.dart';

class _FullController extends RemoteController {
  @override
  RemoteState build() => RemoteState(
        device: const DiscoveredDevice(
          host: '10.0.0.5',
          platform: DevicePlatform.samsung,
          name: '75" The Frame',
        ),
        capabilities: RemoteKey.values.toSet(),
        canType: true,
        apps: AppShortcut.values.toSet(),
      );
}

void main() {
  testWidgets('remote layout golden', (tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [remoteControllerProvider.overrideWith(_FullController.new)],
        child: const MaterialApp(home: RemoteScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(RemoteScreen),
      matchesGoldenFile('remote_layout.png'),
    );
  });
}
