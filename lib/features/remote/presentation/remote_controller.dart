import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/remote/discovered_device.dart';
import '../../../core/remote/driver.dart';
import '../../../core/remote/driver_factory.dart';
import '../../../core/remote/drivers/samsung/samsung_driver.dart';
import '../../../core/remote/keys.dart';
import '../domain/remote_state.dart';

final remoteControllerProvider =
    NotifierProvider<RemoteController, RemoteState>(RemoteController.new);

class RemoteController extends Notifier<RemoteState> {
  RemoteDriver? _driver;
  final Map<String, String> _samsungTokens = {};

  @override
  RemoteState build() {
    ref.onDispose(() => _driver?.disconnect());
    return const RemoteState();
  }

  Future<void> connect(DiscoveredDevice device) async {
    await _driver?.disconnect();
    final driver = createDriver(
      device,
      samsungToken: _samsungTokens[device.host],
    );
    await driver.connect();
    if (driver is SamsungDriver) {
      final token = driver.token;
      if (token != null) _samsungTokens[device.host] = token;
    }
    _driver = driver;
    state = RemoteState(device: device, capabilities: driver.capabilities);
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
