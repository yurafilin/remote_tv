import 'discovered_device.dart';
import 'driver.dart';
import 'drivers/androidtv/android_tv_driver.dart';
import 'drivers/lg/lg_webos_driver.dart';
import 'drivers/roku/roku_driver.dart';
import 'drivers/samsung/samsung_driver.dart';

/// Builds the right [RemoteDriver] for a discovered device.
/// New brands slot in here as their drivers land.
RemoteDriver createDriver(
  DiscoveredDevice device, {
  String? samsungToken,
  String? lgKey,
}) =>
    switch (device.platform) {
      DevicePlatform.roku => RokuDriver(device.host),
      DevicePlatform.samsung => SamsungDriver(device.host, token: samsungToken),
      DevicePlatform.androidTv => AndroidTvDriver(device.host),
      DevicePlatform.lg => LgWebosDriver(device.host, clientKey: lgKey),
      _ => throw UnimplementedError(
            '${device.platform.name} driver not implemented yet',
          ),
    };
