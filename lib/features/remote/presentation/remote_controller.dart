import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/remote/app_launcher.dart';
import '../../../core/remote/discovered_device.dart';
import '../../../core/remote/driver.dart';
import '../../../core/remote/driver_factory.dart';
import '../../../core/remote/drivers/lg/lg_webos_driver.dart';
import '../../../core/remote/drivers/samsung/samsung_driver.dart';
import '../../../core/remote/device_info_reporter.dart';
import '../../../core/remote/keys.dart';
import '../../../core/remote/remote_store.dart';
import '../../../core/remote/text_input.dart';
import '../domain/remote_state.dart';

final remoteControllerProvider =
    NotifierProvider<RemoteController, RemoteState>(RemoteController.new);

class RemoteController extends Notifier<RemoteState> {
  RemoteDriver? _driver;

  @override
  RemoteState build() {
    ref.onDispose(() => _driver?.disconnect());
    return const RemoteState();
  }

  Future<void> connect(DiscoveredDevice device) async {
    await _driver?.disconnect();
    final store = ref.read(remoteStoreProvider);
    final driver = createDriver(
      device,
      samsungToken: store.token(device.host),
      lgKey: store.lgKey(device.host),
    );
    await driver.connect();
    if (driver is SamsungDriver) {
      final token = driver.token;
      if (token != null) await store.saveToken(device.host, token);
    } else if (driver is LgWebosDriver) {
      final key = driver.clientKey;
      if (key != null) await store.saveLgKey(device.host, key);
    }
    var resolved = device;
    if (driver is DeviceInfoReporter) {
      final info = await (driver as DeviceInfoReporter).info().timeout(
        const Duration(seconds: 3),
        onTimeout: () => null,
      );
      if (info != null) {
        final mac = info.mac;
        if (mac != null) await store.saveMac(device.host, mac);
        final name = info.name;
        if (name != null && name.isNotEmpty) {
          resolved = DiscoveredDevice(
            host: device.host,
            platform: device.platform,
            name: name,
          );
        }
      }
    }
    await store.saveLastDevice(resolved);

    _driver = driver;
    state = RemoteState(
      device: resolved,
      capabilities: driver.capabilities,
      canType: driver is TextInput,
      apps: driver is AppLauncher ? (driver as AppLauncher).apps : const {},
    );
  }

  Future<void> launchApp(AppShortcut app) async {
    final driver = _driver;
    if (driver is AppLauncher) await (driver as AppLauncher).launchApp(app);
  }

  Future<void> sendText(String text) async {
    final driver = _driver;
    if (driver is TextInput) await (driver as TextInput).sendText(text);
  }

  Future<void> submit() async {
    final driver = _driver;
    if (driver is TextInput) await (driver as TextInput).submit();
  }

  Future<void> press(RemoteKey key) async {
    final driver = _driver;
    if (driver == null) return;
    await driver.sendKey(key);
    state = state.copyWith(lastKey: key);
  }

  Future<void> disconnect() async {
    await _driver?.disconnect();
    _driver = null;
    state = const RemoteState();
  }
}
