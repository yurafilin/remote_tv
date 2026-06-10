import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv/core/remote/discovered_device.dart';
import 'package:remote_tv/core/remote/remote_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('RemoteStore round-trips the last device and Samsung token', () async {
    SharedPreferences.setMockInitialValues({});
    final store = RemoteStore(await SharedPreferences.getInstance());

    expect(store.loadLastDevice(), isNull);

    const device = DiscoveredDevice(
      host: '10.0.0.5',
      platform: DevicePlatform.samsung,
      name: 'Living Room TV',
    );
    await store.saveLastDevice(device);
    await store.saveToken('10.0.0.5', 'abc123');

    final loaded = store.loadLastDevice();
    expect(loaded?.host, '10.0.0.5');
    expect(loaded?.platform, DevicePlatform.samsung);
    expect(loaded?.name, 'Living Room TV');
    expect(store.token('10.0.0.5'), 'abc123');

    await store.clearLastDevice();
    expect(store.loadLastDevice(), isNull);
  });

  test('forget clears the last device, token and MAC for a host', () async {
    SharedPreferences.setMockInitialValues({});
    final store = RemoteStore(await SharedPreferences.getInstance());

    const device = DiscoveredDevice(
      host: '10.0.0.7',
      platform: DevicePlatform.samsung,
      name: 'Frame 75',
    );
    await store.saveLastDevice(device);
    await store.saveToken('10.0.0.7', 'tok');
    await store.saveMac('10.0.0.7', 'AA:BB:CC:DD:EE:FF');

    await store.forget('10.0.0.7');

    expect(store.loadLastDevice(), isNull);
    expect(store.token('10.0.0.7'), isNull);
    expect(store.mac('10.0.0.7'), isNull);
  });
}
