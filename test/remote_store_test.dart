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
}
